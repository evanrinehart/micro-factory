require 'machine'
require 'mover'
require 'box'
require 'end_finder'
require 'time'
require 'hotlist'

class World

  attr_reader :things
  attr_reader :counter
  attr_reader :current_time
  attr_reader :hotlist

  attr_reader :ix_movers_in
  attr_reader :ix_movers_out

  def initialize
    @things = {}
    @counter = 0
    @current_time = Time::ZERO
    @hotlist = Hotlist.new

    @ix_movers_in = {}
    @ix_movers_out = {}

    add(next_key, @hotlist)
  end

  def add(k,thing)
    @things[k] = thing
  end

  # remaining references to k will be invalid
  def delete(k)
    @things.delete(k)
  end

  def seek_to(t)
    e = find_end(t).time
    if e && e < t
      raise "seeked too far"
    end
    @current_time = t
    @things.each do |k, thing|
      thing.seek_to(t)
    end
  end

  def find_end(limit)
    finder = EndFinder.new(limit)
    @things.each do |k,thing|
      finder.insert(thing)
    end
    finder
  end

  def next_key
    @counter += 1
    @counter
  end

  def build_index
    @ix_movers_in = {}
    @ix_movers_out = {}
    @things.each do |k1,_|
      array1 = []
      array2 = []
      @things.each do |k2,thing2|
        array1.push(k2) if thing2.mover? && thing2.destination_id == k1
        array2.push(k2) if thing2.mover? && thing2.source_id == k1
      end
      @ix_movers_in[k1]  = array1 unless array1.empty?
      @ix_movers_out[k1] = array2 unless array2.empty?
    end

  end

  def movers_into(thing_k)
    (@ix_movers_in[thing_k]||[]).map{|k| @things[k] }
  end

  def movers_outof(thing_k)
    (@ix_movers_out[thing_k]||[]).map{|k| @things[k] }
  end

  def mover_wants(mover)
    @things[mover.destination_id].item_needed
  end

end



=begin
class World

  attr_reader :machines
  attr_reader :movers
  attr_reader :boxes
  attr_reader :things

  attr_reader :ix_movers_in
  attr_reader :ix_movers_out

  def initialize
    @machines = {}
    @movers = {}
    @boxes = {}
    @things = {}
    @entities = {}
  end

  def copy_from(w)
    @things = {}
    @machines = {}
    w.machines.each do |m|
      e = m.copy
      @machines[m.serial_no] = e
      @things[m.serial_no] = e
    end

    @movers = {}
    w.movers.each do |m|
      e = m.copy
      @movers[m.serial_no] = e
      @things[m.serial_no] = e
    end

    @boxes = {}
    w.boxes.each do |b|
      e = b.copy
      @boxes[b.serial_no] = e
      @things[b.serial_no] = e
    end

  end

  def copy
    w = World.new
    w.copy_from(self)
    return w
  end

  def add_box
    sn = SerialNo.mint
    box = Box.new(sn)
    @boxes[sn] = box
    @entities[sn] = box
    return box
  end

  def add_machine
    sn = SerialNo.mint
    machine = Machine.new(sn)
    @machines[sn] = machine
    @entities[sn] = machine
    return machine
  end

  def add_mover(now, c1, c2)
    sn = SerialNo.mint
    mover = Mover.new(now, sn, c1, c2)
    @movers[sn] = mover
    @entities[sn] = mover
    return mover
  end

  def demo
    machine = add_machine
    b1 = add_box
    b2 = add_box
    mv1 = add_mover(0, b1.serial_no, machine.serial_no)
    mv2 = add_mover(0, machine.serial_no, b2.serial_no)
    b1.set_contents(:gear, 4)
    nil
  end

  def seek_to(t)
    @machines.each do |i,m|
      m.seek_to(t)
    end

    @movers.each do |i,m|
      m.seek_to(t)
    end

    @boxes.each do |i,b|
      b.seek_to(t)
    end

    nil
  end

  class EndFinder

    attr_reader :time
    attr_reader :enders

    def initialize(limit)
      @enders = []
      @time = nil
      @limit = limit
    end

    def insert(obj)
      t = obj.find_end(@limit)
      return if t.nil?
      return if @time && @time < t
      @time = t if @time.nil?
      if t < @time
        @enders.clear
        @enders.push(obj)
        @time = t
      else # equal
        @enders.push(obj)
      end
    end
      
  end

  def find_end(limit)
    finder = EndFinder.new(limit)

    @machines.each{|i, m| finder.insert(m) }
    @movers.each{|i, m| finder.insert(m) }
    @boxes.each{|i, b| finder.insert(b) }

    finder
  end

  def resolutions(end_time, enders)

    # vital set = Set.new

    boxes = Set.new
    machines = Set.new
    transactions = []

    enders.each do |mover|
      o1 = get_ent(mover.source_id)
      o2 = get_ent(mover.destination_id)

      b = mover.touching_entity(Box, o1, o2)
      boxes.add(b) if b

      m = mover.touching_entity(Machine, o1, o2)
      machines.add(m) if m
    end

    {:machines => machines, :boxes => boxes}

    # for each box, collect all the relevant machines and movers
    # generate the transactions which resolve all those things

    # for each machine, collect all relevant movers
    # generate the transactions which resolve the machine and the movers

    # everything in the vital set might also need to be resolved
    
  end

  def get_thing(i)
    @things[i] || raise("get_end: bad ID")
  end

  #interactions
  #  output buffer, movers trying to take and machine possibly trying to output item
  #  input buffer, movers trying to put items and machine possibly trying to start new run
  #  box, movers trying to take and put items


  class AdjustBuffer
    def initialize(buffer, item_class, delta)
      @buffer = buffer
      @item_class = item_class
      @delta = delta
    end

    def execute
      @buffer.change_amount(@item_class, @delta)
    end
  end

  class GotoSleep
    def initialize(obj)
      @obj = obj
    end

    def execute
      @obj.sleep
    end
  end

  class DispatchMover
    def initialize(mover)
      @mover = mover
    end

    def execute
      @mover.dispatch
    end
  end


  def compute_spooky_set(prime_movers, prime_machines)
    # prime things are just now ending
    # some of them are about to free up space in a full buffer
    # if anything is waiting on those buffers they are remembered
    # and traversed to find more spooky set members

    spookies = Set.new
    amounts_taken = {}
    stack = []

    prime_movers.each do |thing|
      obj1 = @entities[thing.source_id]
      obj2 = @entities[thing.destination_id]

      next if obj1.unspooky?

      if thing.spooky_0?(obj1, obj2)
        spookies.add(thing)
        if obj1.machine?
          amounts_taken[obj1.id] ||= 0
          amounts_taken[obj1.id] += thing.buffer.limit
          if obj1.could_run_if_took?(amounts_taken[obj1.id])
            stack.push(obj1)
          end
        else
          stack.push(obj1)
        end
      end
    end

    prime_machines.each do |thing|
      spookies.add(thing) if thing.spooky_0?
      @ix_movers_in[thing.id].each do |m|
        next if m.unspooky?
        stack.push(obj1)
      end
    end

    until stack.empty?
      thing = stack.pop

      next if spookies.member?(thing)

      if thing.mover?
        # mover is spookyN+1 if about to take from a full buffer
        # and move to something spooky
        obj1 = @entities[thing.source_id]
        if thing.spooky_1?(obj1)
          spookies.add(thing)
          if obj1.machine?
            amounts_taken[obj1.id] ||= 0
            amounts_taken[obj1.id] += thing.buffer.limit
            if obj1.could_run_if_took?(amounts_taken[obj1.id])
              stack.push(obj1)
            end
          end
        end
            
      elsif thing.machine?
        # machine is spookyN+1 if about to take from full input buffer
        # assuming something is about to take from the output buffer
        
      elsif thing.box?
        # consider in-movers, any which are waiting for space in destination
        # add them to spooky
        # add them to stack
      end
    end

    spookies
  end

end
=end

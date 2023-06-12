class GearCutter

  attr_reader :working_slot
  attr_reader :charge

  def initialize
    @working_slot = nil
    @charge = Pb.new(0,100)
    @status = :working
  end

  def wake(now)
    @charge.thaw(now) if @status == :working
  end

  def scan(limit)
    @charge.scan(limit)
  end

  def bang(now, scrap_out)
    @status = :working
    @charge.reset(now)
    @working_slot = :gear
    scrap_out.put(:scrap)
    scrap_out.dispatch(now)
  end

  def charged?(now)
    @charge.full?(now)
  end

  def full?
    !@working_slot.nil?
  end

  def holding?(item)
    @working_slot == item
  end

  def put(item)
    raise("item collision") unless @working_slot.nil?
    @working_slot = item
  end

  def eject
    @working_slot = nil
  end

  def seek(t)
  end

  def stop(now)
    @charge.freeze(now)
  end

  def viz(t)
    slot = @working_slot ? "[#{@working_slot.to_s}]" : "[]"
    charge = @charge.viz(t)
    "gc[#{charge} #{slot}]"
  end

end

class Bucket

  attr_reader :item

  def initialize
    @item = nil
  end
  
  def clear?
    @item.nil?
  end

  def put(item)
    raise("item collision") unless @item.nil?
    @item = item
  end

  def eject
    raise("take error") if @item.nil?
    @item = nil
  end

  def sample
    case @item
    when nil then "(Bucket [])"
    else "(Bucket [#{@item.to_s}])"
    end
  end

end

class BucketMover
  attr_reader :bucket
  attr_reader :location1 #e.g. gear cutter scrap out
  attr_reader :location2 #e.g. a patch of ground
  attr_reader :progress  # 0% right after dispatch, 100% before
  attr_reader :direction # right, left

  # waiting
  # moving

  def initialize
    @bucket = Bucket.new
    @progress = Pb.new(40,40)
    @direction = :left
  end

  def position(t)
    x = @progress.sample(t)
    case @direction
    when :right then x
    when :left then 1.0 - x
    end
  end

  def at_source?(now)
    if @direction == :right
      @progress.empty?(now)
    else
      @progress.full?(now)
    end
  end

  def at_dest?(now)
    if @direction == :right
      @progress.full?(now)
    else
      @progress.empty?(now)
    end
  end

  def delivering?(now)
    at_dest?(now) && @bucket.item
  end

  # called by someone, verb from their perspective
  def accept(now)
    item = @bucket.item
    @bucket.eject
    dispatch(now)
  end

  def accepting?(now)
    at_source?(now) && @bucket.item.nil?
  end

  # called by someone, verb from their perspective
  def deliver(item,now)
    @bucket.put(item)
    dispatch(now)
  end

  def left_scan(limit)
    t = scan(limit)
    return nil if t.nil?
    @direction == :left ? t : nil
  end

  def right_scan(limit)
    t = scan(limit)
    return nil if t.nil?
    @direction == :right ? t : nil
  end

  def scan(limit)
    @progress.scan(limit)
  end

  def put(item)
    @bucket.put(item)
  end

  def clear?
    @bucket.clear?
  end

  def eject
    @bucket.eject
  end

  def arrive(now)
    @progress.freeze(now)
  end

  def stop(now)
    @progress.freeze(now)
  end

  def dump(out)
    raise("item collision") unless out.clear?
    out.put(@bucket.take)
  end

  # make it go
  def dispatch(now)
    @progress.reset(now)
    @direction = @direction == :left ? :right : :left
  end

  def seek(t)
  end

  def holding?(item)
    @bucket.item == item
  end

  def sample(t)
    "(BucketMover #{"%.4f" % position(t)} #{@bucket.sample})"
  end

  def viz(t)
    item = @bucket.item ? "[#{@bucket.item.to_s}]" : "[]"
    x = @progress.sample(t)
    x = @direction == :right ? x : 1.0 - x
    frost = @progress.frozen? ? '*' : ''
    prog = frost + Pb.format(x)
    dir = @direction.to_s
    
    "bm[#{prog} #{dir} #{item}]"
  end

  def wake(now)
    @progress.thaw(now)
  end

  # if a bucket mover arrives at e.g. the gear cutter
  # and it's blocked waiting, it must signal to wake
  # up the machine, it's fine if there is a delay.

  # if a bucket mover arrives at an empty patch of
  # ground, it could dump the contents instantly and
  # begin the return journey right then and there.

  # if a bucket mover arrives at a furnace which has
  # room (because it's empty, or has 0% of the ingredient)
  # it can unload and begin the return journey.

  # if it arrives to find the destination blocked.
  # then it blocks waiting for room in destination.
  # e.g. a chute. It will unload as soon as there is
  # room, no delay. 

  
end

class Void

  attr_writer :in

  def seek(t)
    @in.seek(t)
  end

  def scan(limit)
    @in.right_scan(limit)
  end

  def service(now)
    if @in.delivering?(now)
      item = @in.accept(now)
      nil
    end
  end

  def viz(t)
    "void[]"
  end

end

class Plates

  attr_writer :out

  def seek(t)
    @out.seek(t)
  end

  def scan(limit)
    @out.left_scan(limit)
  end

  def service(now)
    if @out.accepting?(now)
      @out.deliver(:plate, now)
    end
  end

end



class Pb

  attr_accessor :status
  attr_accessor :period
  attr_accessor :cursor
  attr_accessor :t0
  attr_accessor :t1

  def self.running(now,cursor,period)
    p = Pb.new(cursor,period)
    p.thaw(now)
    p
  end

  def self.frozen(cursor,period)
    Pb.new(cursor,period)
  end

  def self.format(x)
    "%.0f%%" % (100 * x)
  end

  def initialize(cursor,period)
    @period = period
    @cursor = cursor
    @status = :frozen
  end

  def thaw(now)
    @t0 = now - cursor
    @t1 = @t0 + period
    @status = :running
  end

  def freeze(now)
    #raise("freeze") if @status == :frozen
    return if @status == :frozen
    @cursor = now - @t0
    @status = :frozen
  end

  def frozen?
    @status == :frozen
  end

  def reset(now)
    @t0 = now
    @t1 = now + @period
    @status = :running
  end

  def scan(limit)
    case @status
    when :frozen then nil
    when :running then @t1 <= limit ? @t1 : nil
    end
  end

  def frozen_percent
    100.0 * @cursor / @period
  end

  def full?(now)
    case @status
    when :frozen then @cursor == @period
    when :running then now == @t1
    end
  end

  def empty?(now)
    case @status
    when :frozen then @cursor == 0
    when :running then now == @t0
    end
  end


  def sample(t)
    case @status
    when :frozen then @cursor.to_f / @period
    when :running then (t - @t0).to_f / @period
    end
  end

  def inspect
    case @status
    when :frozen then "(pb-idle %d/%d)" % [@cursor,@period]
    when :running then "(pb-going %d,%d)" % [@t0,@t1]
    end
  end

  def viz(t)
    x = sample(t)
    frost = @status == :frozen ? '*' : ''
    frost + Pb.format(x)
  end

end


# scan for gear cutter reports a time
# if the time is consistent with the min, gear cutter
# is added to the "hot" locations which will run code

# scan for mover reports a time
# if yadda yadda, one of the two destinations are
# added to the "hot" locations depending on where it will be.





class Chute

  attr_reader :length
  attr_reader :head
  attr_reader :shrinking
  attr_reader :train
  attr_reader :stable
  attr_reader :fuse
  attr_reader :cached_tail
  attr_reader :cached_tail_space

  Block = Struct.new(:length, :item_class)

  class Train
    attr_reader :cars

    def initialize
      @cars = []
    end

    def total_space
      n = 0
      @cars.each do |car|
        n += car.length if car.item_class.nil?
      end
      n
    end

    def append(item,n)
      if @cars.empty?
        @cars.push(Block.new(100*n, item))
      elsif @cars[0].item_class == item
        @cars[0].length += n * 100
      else
        @cars.unshift(Block.new(100*n, item))
      end
    end

    def prepend(item,n)
      if @cars.empty?
        @cars.push(Block.new(100*n, item))
      elsif @cars.last.item_class == item
        @cars.last.length += n * 100
      else
        @cars.push(Block.new(100*n, item))
      end
    end

    def pad_left(amount)
      @cars.unshift(Block.new(amount, nil))
    end

    def pad_right(amount)
      @cars.push(Block.new(amount, nil))
    end

    def remove_item_right
      raise("no item") unless @cars.last
      raise("not an item") unless @cars.last.item_class
      car = @cars.last
      if car.length == 100
        @cars.pop
        nil
      else
        car.length -= 100
      end
    end

    def trim_right
      if @cars.last && @cars.last.item_class.nil?
        @cars.pop
      end
    end

    def bubble
      @cars.reverse_each do |car|
        return car.length if car.item_class.nil?
      end
    end

    def merge!(train)
      car = train.cars.pop
      until car.nil? || car.item_class.nil?
        n = car.length / 100
        append(car.item_class, n)
        car = train.cars.pop
      end
      car ? car.length : 0
    end

    def length
      @cars.sum{|c| c.length}
    end

    def last
      @cars[0]
    end

    def empty?
      @cars.empty?
    end

    def viz
      accum = []
      @cars.each do |car|
        if car.item_class.nil?
          accum.push(car.length)
        else
          n = car.length / 100
          accum.push(n.to_s + car.item_class.to_s)
        end
      end
      '[' + accum.join(' ') + ']'
    end
  end
  
  def initialize(length)
    @length = length * 100
    @head = Train.new # packed
    @shrinking = 0
    @train = Train.new
    @stable = true
    @fuse = nil
  end

  def tail
    @head.length + @shrinking + @train.length
  end

  def last_car
    @stable ? @head.last : @train.last
  end

  def empty?
    @head.empty? && @train.empty?
  end

  def tail_space
    @length - tail
  end

  def clear?
    tail_space >= 100
  end

  def clear_at?(t)
    if @stable
      tail_space >= 100
    else
      # t is after fuse t0 and before any other 'event'
      # space available is (space at t0) + (t - t0)
      tail_space + (t - @fuse.t0) >= 100
    end
  end

  def put(item)
    room = tail_space
    raise("item collision") if room < 100
    if @stable
      if room == 100 # now fully packed
        @head.append(item,1)
      else # now unstable
        @stable = false
        @shrinking = room - 100
        @train.append(item,1)
        @fuse = Pb.new(0,@shrinking)
      end
    else
      @train.pad_left(room-100) if room > 100
      @train.append(item,1)
      if total_space == 0
        @stable = true
      end
    end
  end

  def total_space
    tail_space + @shrinking + @train.total_space
  end

  def left_scan(limit)
    t = scan(limit)
    return nil if t.nil?
    @direction == :right ? t : nil
  end

  def right_scan(limit)
    t = scan(limit)
    return nil if t.nil?
    @direction == :left ? t : nil
  end

  def scan(limit)
    return nil if @stable
    return nil if limit < @fuse.t1
    @fuse.t1
  end

  def shrink
    return if @stable

    bubble = @head.merge!(@train)
    if bubble == 0
      @stable = true
      @shrinking = 0
      @fuse = nil
    else
      @shrinking = bubble
      @fuse = Pb.new(0, @shrinking)
    end
      
  end

  def seek(t)
    return if @stable
    delta = t - @fuse.t0
    @shrinking -= delta # (!)
    if @shrinking == 0
      shrink
      @fuse.thaw(t) if @fuse
    else
      @fuse = Pb.new(0, @shrinking)
      @fuse.thaw(t)
    end
  end

  def wake(now)
    return if @stable
    raise("wake") if @fuse.status == :running?
    @fuse.thaw(now)
  end

  #def inspect
  #  head = @head.inspect
  #  train = @train.inspect
  #  room = tail_space
  #  "(Chute %d %s %d %s)" % [room, train, @shrinking, head]
  #end

  def sample(t)
    delta = @stable ? 0 : t - @fuse.t0
    room = tail_space + delta
    shrinking = @shrinking - delta
    "(Chute %d %s %d %s)" % [room, train.inspect, shrinking, head.inspect]
  end

  def viz(t)
    delta = @stable ? 0 : t - @fuse.t0
    room = tail_space + delta
    shrinking = @shrinking - delta
    train = @train.viz
    head = @head.viz
    frost = @stable ? '*' : ''
    frost + "ch[#{room} #{train} #{shrinking} #{head}]"
  end

end





class Machine1

  attr_writer :in1
  attr_writer :out1
  attr_writer :out2
  attr_reader :gear_cutter

  attr_reader :in1
  attr_reader :out1
  attr_reader :out2

  def initialize
    @gear_cutter = GearCutter.new
  end

    
    

    # should a gear be put in chute
    # should in1 be unloaded and dispatched
    # should out2 be loaded with scrap and dispatched
    # should gear_cutter charge be reset
    # should gear_cutter working_slot be cleared
    # should out2 be stopped
    # should in1 be stopped

    # out1 put gear in if bang happens
    # in1 be unloaded and dispatched if it has plate and bang happens
    # out2 loaded with scrap and dispatched if bang happens
    # gear_cutter charge be reset if bang happens
    # gear_cutter working_slot is cleared if bang happens and in1 no plate
    # out2 is stopped if it's there and bang doesn't happen
    # in1 stops if it's there and working slot is full and bang doesn't happen

    # plate placed in working slot if (complex)
    # charge frozen if fully charged but requirements aren't met

    # bang happens if (and only if) requirements met
    # i.e. fully charged, plate here, output has room

  def seek(now)
    @in1.seek(now)
    @out1.seek(now)
    @out2.seek(now)
    @gear_cutter.seek(now)
  end

  def service(now)
    charged = @gear_cutter.charged?(now)
    plate1 = @gear_cutter.holding?(:plate)
    plate2 = @in1.at_dest?(now) && @in1.holding?(:plate)
    plate = plate1 || plate2
    bucket = @out2.at_source?(now) && @out2.clear?
    chute = @out1.clear?
    room = bucket && chute
    bang = charged && plate && room

=begin
print ['charged', charged], "\n"
print ['plate1', plate1], "\n"
print ['plate2', plate2], "\n"
print ['plate', plate], "\n"
print ['bucket', bucket], "\n"
print ['chute', chute], "\n"
print ['room', room], "\n"
print ['bang', bang], "\n"

puts @out1.inspect
=end

#print @out1.viz(now)

    # the local effects
    if bang
      @out1.put(:gear)
      @out1.wake(now)
      @out2.put(:scrap)
      @out2.dispatch(now)
      @gear_cutter.charge.reset(now)
    end

    if bang && !plate2
      @gear_cutter.eject
    end

    if plate2 && (bang || !plate1)
      @in1.eject 
      @in1.dispatch(now)
    end

    if !bang && @out2.at_source?(now)
      @out2.stop(now)
    end

    if !bang && @in1.at_dest?(now) && @gear_cutter.full?
      @in1.stop(now)
    end

    if charged && !bang
      @gear_cutter.stop(now)
    end

    if !bang && !plate1 && plate2
      @gear_cutter.put(:plate)
    end

  end

  def scan(limit)
    t1 = @in1.right_scan(limit)
    t2 = @out1.left_scan(limit)
    t3 = @out2.left_scan(limit)
    t4 = @gear_cutter.scan(limit)

    answer = t1
    answer = t2 if answer.nil? || (t2 && t2 < answer)
    answer = t3 if answer.nil? || (t3 && t3 < answer)
    answer = t4 if answer.nil? || (t4 && t4 < answer)

    answer
  end

  def wake(now)
    @gear_cutter.wake(now)
  end

  def viz(t)
    gc = @gear_cutter.viz(t)
    "m1[#{gc}]"
  end

end


class Machine2

  attr_writer :in1
  attr_writer :out1
  attr_reader :furnace

  def initialize
  end

  def seek(t)
    @in1.seek(t)
    @out1.seek(t)
    @furnace1.seek(t)
  end

  def service(now)
    # should the furnace be locked/unlocked
    # should scrap be replaced with hot iron
    # should hot iron be replaced with iron plate
    # should scrap be unloaded from in1 and dispatched
    # should plate be ejected
    # should plate be loaded on out1 and dispatched
    # 
    
  end

  def viz(t)
    "m2[_ _ _]"
  end

  # bucket mover in (scrap in)
  # furnace
  # grabber out, takes plate when ready

  # once enough scrap accumulates, lock the furnace
  # begin the processing, replace scrap with iron blob
  # when finished, replace blob with iron plate, unlock door

end

class Scanner

  def earliest_time
    @time
  end

  def disrupted_zones
    @places
  end

  def initialize(limit)
    @places = []
    @time = nil
    @limit = limit
  end

  def insert(place)
    t = place.scan(@limit)
    # t = nil => not disrupted at or before limit
    # t == time => add place to set
    # t < time => update time, clear set, add place to set
    return if t.nil?

    @time ||= t

    if t == @time
      @places.push(place)
    elsif t < @time
      @places = [place]
      @time = t
    end

  end

end




class Driver

  def initialize(zones, links)
    @zones = zones
    @links = links
  end

  def small_step(target_time)
    scanner = Scanner.new(target_time)

    @zones.each do |k,zone|
      scanner.insert(zone)
    end

    t = scanner.earliest_time

    #puts "small step target=#{target_time} result=#{scanner.inspect}"

    if t
      # do what you want with the "before state" now
      scanner.disrupted_zones.each do |zone|
        zone.seek(t)
        zone.service(t)
      end
      # do what you want with the "after state" now
      return t
    else
      return target_time
    end
  end

  def big_step(target_time)
    loop do
      t = small_step(target_time)
      break unless t < target_time
    end
  end

end


# list of common "verbs"
# scan
# seek
# put
# eject  
# holding?
# full?
# clear?
# wake
# stop



v = Void.new
p = Plates.new
m = Machine1.new
supply = BucketMover.new
bm = BucketMover.new
chute = Chute.new(4)
m.in1 = supply
m.out1 = chute
m.out2 = bm
v.in = bm
p.out = supply
chute.wake(0)

m.gear_cutter.put(:plate)
m.wake(0)
supply.wake(0)

driver = Driver.new({3=>m, 5=>v, 7=>p}, nil)

(0..100).each do |t|
  t *= 5
  before = "t=#{t} #{supply.viz(t)} #{m.viz(t)} #{bm.viz(t)} #{chute.viz(t)}"
  driver.big_step(t)
  after = "t=#{t} #{supply.viz(t)} #{m.viz(t)} #{bm.viz(t)} #{chute.viz(t)}"
  if before == after
    puts before
  else
    puts before
    puts after
  end
end



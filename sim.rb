require 'world'

class Sim

  attr_reader :world

  def initialize(world)
    @world = world
  end

  def demo
    machine = add_machine
    b1 = add_box
    b2 = add_box
    b3 = add_box
    mv1 = add_mover(0, b1.key, machine.key)
    mv2 = add_mover(0, machine.key, b2.key)
    mv3 = add_mover(0, machine.key, b3.key)
    b1.buffers.buffers[0] = RestrictedBuffer.new(:iron_plate, 4, 100)
    b2.make_restricted(:gear, 100)
    b3.make_restricted(:iron_scrap, 100)

    @world.build_index

    nil
  end

  def add_box
    k = @world.next_key
    b = Box.new(k)
    @world.add(k,b)
  end

  def add_machine
    k = @world.next_key
    m = Machine.new(k)
    @world.add(k,m)
  end

  def add_mover(now, k1, k2)
    k = @world.next_key
    m = Mover.new(k,now,k1,k2)
    @world.add(k,m)
  end



  def small_step(target_time)
    t1 = @world.current_time
    result = @world.find_end(target_time)
    if result.time.nil?
      @world.seek_to(target_time)
      return target_time
    elsif result.time == target_time
      @world.seek_to(target_time)
      resolve(result.movers, result.machines)
      return target_time
    else
      @world.seek_to(result.time)
      resolve(result.movers, result.machines)
      return result.time
    end
  end


  def resolve(arriving_movers, completing_machines)
    # arriving movers and completing machines
    # comes from the find_end routine

    now = @world.current_time
    hotlist = @world.hotlist

    active_movers = Set.new(arriving_movers)

    if now == hotlist.minimum
      mover_keys = Set.new
      hot_destination_keys = hotlist.take_entries(now)
      list_activated_movers(@world, hot_destination_keys, mover_keys)
      mover_keys.each do |k|
        active_movers.add(@world.things[k])
      end
    end

    boxes = Set.new
    machines = Set.new

    things_at_movers(@world, active_movers, boxes, machines)

    raise "resolve the boxes and machines"

    # find set of all boxes and (separately) set of machines touched
    # by arriving + activated movers
    # now you have boxes_to_inspect and
    # machines_to_inspect (which includes completing machines)

    
    
  end




  def things_at_movers(world, movers, boxes_out, machines_out)
    movers.each do |mover|
      thing = nil

      if mover.at_destination?
        thing = world.things[mover.destination_id]
      elsif mover.at_source?
        thing = world.things[mover.source_id]
      else
        next
      end

      if thing.machine?
        machines_out.add(thing)
      elsif thing.box?
        boxes_out.add(thing)
      end
    end
  end

  def list_activated_movers(world, destination_keys, activated_set)
    destination_keys.each do |k|
      world.ix_movers_in[k].each do |mover_k|
        activated_set.add(mover_k)
      end
    end
  end

  def get_movers_in(world, thing_here)
    pile = []
    k = thing_here.key
    world.things.each do |_, thing|
      next if !thing.mover?
      pile.push(thing) if thing.at_destination?
    end
    pile
  end

  def get_movers_out(world, thing_here)
    pile = []
    k = thing_here.key
    world.things.each do |_, thing|
      next if !thing.mover?
      pile.push(thing) if thing.at_source?
    end
    pile
  end

end


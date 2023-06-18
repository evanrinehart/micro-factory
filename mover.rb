# mover (device/entity)
# in-mover server (server)
# out-mover server (server)
# droppers server
# takers server

INF = Float::INFINITY

class Mover # mv[l=3 v=2 0/3 left [] w=gear]

  attr_reader :sleep
  attr_reader :length
  attr_reader :speed
  attr_reader :position
  attr_reader :direction
  attr_reader :item

  def unload_and_dispatch
    Mover.new(false, @length, @speed, @position, :left, nil)
  end

  def load_and_dispatch(item)
    Mover.new(false, @length, @speed, @position, :right, item)
  end

  def stall
    Mover.new(true, @length, @speed, @position, @direction, @item)
  end

  def grow(t0)
    return [INF, self] if @sleep

    if @direction == :left
      d = @position
      x = 0
    else
      d = @length - @position
      x = @length
    end
    delta = travel_time(d, @speed)
    t1 = t0 + delta
    s1 = Mover.new(false, @length, @speed, x, :left, @item)
  end

  def cut(t,t0,t1,s1)
    delta = t - t0
    Mover.new(@length, @speed, @position + delta*@speed, @direction, @item)
  end

  def travel_time(distance, speed)
    distance.to_r / speed
  end

  def to_dropper(k)
    if @position < @length
      NullServer.new
    else
      InMoverServer.new(k, @item)
    end
  end

  def to_taker(k, wanted)
    if @position > 0
      NullServer.new
    else
      OutMoverServer.new(k, wanted)
    end
  end

end

class InMoverServer

  # represents a mover try to drop something right now
  # it responds to get requests or successful put by
  # changing state to indicate unload and dispatch
  # or it ends up stalled

  attr_reader :key
  attr_writer :downstream

  def initialize(key,item)
    @key = key
    @item = item
    @status = :stalled
  end
  
  def get(desc)
    if @item && (desc == :any || desc == @item)
      @status = :unloaded
      [200, @item]
    else
      404
    end
  end

  def interact
    if @status == :stalled
      code = @downstream.put(@item)
      @status = :unloaded if code == 200
    end
  end

  def commit(t, world)
    @downstream = nil
    mover0 = world.get(@key)
    mover1 = update(mover0)
    world.put(@key, t, mover1)
  end

  def update(mover)
    if @status == :unloaded
      mover.unload_and_dispatch
    else
      mover.stall
    end
  end

end

class OutMoverServer

  OutMoverState = Struct(:item, :wanted, :status)

  attr_reader :key
  attr_writer :upstream

  def initialize(key,wanted)
    @key = key
    @wanted = wanted
    @status = :stalled
    @item = nil
  end

  def put(item)
    if @wanted == :any || @wanted == item || @wanted.include?(item)
      @item = item
      @status = :loaded
      200
    else
      507
    end
  end

  def interact
    if @status == :stalled && @wanted
      code, item = @upstream.get(@wanted)
      if code == 200
        @item = item
        @status = :loaded
      end
    end
  end

  def dump
    OutMoverState.new(@item, @wanted, @status)
  end

  def restore(s)
    @item = s.item
    @wanted = s.wanted
    @status = s.status
  end

  def commit(t,world)
    @upstream = nil
    mover0 = world.get(@key, t)
    mover1 = update(mover0)
    world.put(@key, t, mover1)
  end

  def update(mover)
    if @status == :loaded
      mover.load_and_dispatch(@item)
    else
      mover.stall
    end
  end

end

class DroppersServer
  def initialize(droppers)
    @droppers = droppers
  end

  def downstream=(component)
    @droppers.each{|d| d.downstream = component }
  end

  def get(desc)
    @droppers.each do |d|
      code, item = d.get(desc)
      if code==200
        return [200, item]
      end
    end
    404
  end

  def available_items
    tally = {}
    tally.default = 0
    @droppers.each do |d|
      count, item = @dropper.available_items
      tally[item] += count if item
    end
    tally
  end

  def interact
    @droppers.each{|d| d.interact}
  end

  def commit(t,world)
    @droppers.each{|d| d.commit(t,world)}
  end

end

class TakersServer
  def initialize(takers)
    @takers = takers
  end

  def upstream=(component)
    @takers.each{|x| x.upstream = component }
  end

  def interact
    @takers.each{|x| x.interact }
  end

  def commit(t,world)
    @takers.each{|x| x.commit(t,world) }
  end

  def put(item)
    @takers.each do |taker|
      code = taker.put(item)
      return 200 if code == 200
    end
    507
  end

end


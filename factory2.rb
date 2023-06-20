# timer[71]
# osc[3/7]
# mover[L=180 v=2 0/180 right]






# BIG STEP
# the big step is from tick t0 to tick t1
# it's big because there might be zero or there might be several 'interaction points'
# on the way from t0 to t1. How do you get there.

# When scanned every zone reports a time between t0 and t1, or nothing
# timers and oscillators look the same at that time, but movers and chutes have
# an updated 'state' unique to the interaction time and will be derived if
# that is the soonest interaction time of all.

# All interaction times along with their zones are sorted and grouped.
# The least group in time is singled out. All groups are serviced to get
# effects and in some cases updated states.

# The scan is repeated, the new winning time if any must be greater than
# the one before for consistency. (progress rule)

# When there are no interaction times found at or before t1, then big step
# is complete.


class Scanner

  def initialize(t1)
    @zones = []
    @time = t1
    @limit = t1
  end

  def insert(zone)
    t = zone.scan
    return if t.nil? || @limit < t
    if @time < t
      nil
    elsif t < @time
      @zones.clear
      @zones.push(zone)
      @time = t
    else
      @zones.push(zone)
    end
  end

end


class Driver

  def initialize
    @divisions_per_second = 60
    @current_time = 0 # in 'ticks'
    @zones = []
  end

  def big_step
    t0 = @current_time
    t1 = @current_time + 1

    fin = small_step(t1)
    fin = small_step(t1) while fin
    
    if t1 == @divisions_per_second
      @zones.each do |z|
        z.rebase(@divisions_per_second)
      end
      @current_time = 0
    else
      @current_time = t1
    end
  end

  def small_step(t1)
    # scanner will look at all zones and give the ones that are disrupted next
    scanner = Scanner.new(t1)
    @zones.each do |z|
      scanner.insert(z)
    end
    # the current time is fractional, update the disrupted zones
    scanner.zones.each do |z|
      z.update
    end
  end

end




# a 'device' 'state' 'point' supports two operations
# grow from a point to a second point later in time where something interesting happens.
# splice a mapped path to get a new point.

class Timer
  def initialize(left)
    @left = left
  end

  def viz
    "timer[#{"%g" % @left}]"
  end

  def grow(t0)
    [t0+@left, Timer.new(0)]
  end

  def splice(t,t0,t1,timer1)
    Timer.new(t1 - t)
  end

  def zones_touched(z1,z2,out)
    out.push(z1)
  end
end

class Oscillator
  def initialize(n, hz, t, booting, waiting)
    @n = n
    @t = t
    @hz = hz
    @booting = false
    @waiting = false
  end

  def viz
    @waiting ? "osc[*/#{@hz}]" : "osc[#{@n}/#{@hz}]"
  end

  def grow(t0)
    if @waiting
      [Float::INFINITY, self]
    elsif @booting
      delta = Rational(@n,@hz) - t0
      t1 = t0 + delta
      [t1, Oscillator.new(@n+1,@hz,t1,false,false)]
    else
      delta = Rational(@n,@hz) - t0
      t1 = t0 + delta
      [t1, Oscillator.new(@n,@hz,t1,@booting,@waiting)]
    end
  end

  def splice(t,t0,t1,osc1)
    if @waiting || @booting
      self
    else
      Oscillator.new(@n,@hz,t,false,false)
    end
  end
end

class Mover
  def initialize(l,v,x,dir,sleep,item)
    @l = l
    @v = v
    @x = x
    @dir = dir
    @sleep = sleep
    @item = item
    # @item_demanded (delayed)
  end

  def fmt(rat)
    "%g" % (rat.truncate(5))
  end

  def viz
    frost = @sleep ? '*' : ''
    item = @item ? @item.to_s : ''
    frost + "mover[l=#{@l} v=#{@v} #{fmt(@x)}/#{@l} #{@dir} [#{item}]]"
  end

  def grow(t0)
    return [Float::INFINITY, self] if @sleep

    if @dir == :right
      dt = Rational(@l - @x, @v)
    else
      dt = Rational(@x, @v)
    end

    [t0 + dt, Mover.new(@l,@v,@l,@dir,false,@item)]
  end

  def splice(t,t0,t1,mover1)
    x = @sleep ? @x : @x + @v * (t - t0)
    Mover.new(@l,@v,x,@dir,@sleep,@item)
  end

  def zones_touched(z1,z2,out)
    out.push(z1) if @dir == :left
    out.push(z2) if @dir == :right
  end
end


class Box

  def initialize(pop,item)
    @item = item
    @pop  = pop
  end

  def grow(t0)
    [Float::INFINITY, self]
  end

  def splice(t,t0,t1,box1)
    self
  end
  
  def viz
    if @pop == 0
      "box[]"
    else
      "box[#{@pop} x #{@item}]"
    end
  end

  def zones_touched(z1,z2,out)
    out.push(z1)
  end

end

class Machine
  def initialize(recipe, item, timer)
    @timer = timer
    @slot = item
    @recipe = recipe
  end

  def grow(t0)
    t1, timer1 = @timer.grow(t0)
    [t1, Machine.new(@recipe, @item, timer1)]
  end

  def splice(t,t0,t1,m1)
    Machine.new(@recipe, @item, @timer.splice(t,t0,t1,@timer1))
  end

  def viz
    "machine[]"
  end

  def zones_touched(z1,z2,out)
    out.push(z1)
  end
end


b1 = Box.new(3,:gear)
b2 = Box.new(0,nil)
mv = Mover.new(2,1,1,:left,false,nil)

puts "0 #{b1.viz} #{mv.viz} #{b2.viz}"
b11 = b1.grow(0)
b22 = b2.grow(0)
mvv = mv.grow(0)

t1 = mvv[0]
t = 0.93r
c1 = b1.splice(t,0,t1,b11[1])
c2 = b2.splice(t,0,t1,b22[1])
mw = mv.splice(t,0,t1,mvv[1])

puts "#{"%g" % t} #{c1.viz} #{mw.viz} #{c2.viz}"



# devices
# b1  box
# b2  box
# mv  mover

# zones
# z1  box-type  (b1, mv)
# z2  box-type  (b2, mv)

# devices_zones
# b1  z1
# b2  z2
# mv  z1,z2

# algorithm
# for all k, p at t_min, collect touched zone from each p, merge duplicates
# for all those zones z,
#   answer the questions needed by that zone type (inspect devices, if necessary, splice)
#   using answers, produce effects (updates to devices)
#   replace device k,t_min with updated point, remember k has changed
# for all changed devices, grow

# box-type zone, devices, questions, answers
# a box b and a mover mv taking from it. Questions
# deduct item from box? A: (grab condition) empty mover here and over zero items in box
# credit item to mover and dispatch? A: grab condition
# sleep the mover? A: empty mover arriving and nothing in the box

# a box b and a mover mv trying to deliver items. Questions
# credit item to box? A: (drop condition) loaded mover is here, room in the box exists
# deduct item from mver and dispatch? A: drop condition
# sleep the mover? A: loaded mover is here and there's no space in the box.

# a box b and there's dropper and taker mover.
# unload/dispatch dropper? A: (drop) box empty OR (room in box && same item) OR (empty taker wanting item)
# load/dispatch takers? A: (take) wanted item in box OR loaded dropper is here with wanted item
# credit box? A: drop but not take
# debit box? A: take but not drop

class BoxZone

  def initialize(box,mvi,mvo)
    @box = box # .item .count .limit
    @mvi = mvi # .at_src? .at_dst? .item
    @mvo = mvo
  end

  def effects
    #questions answered (not correctly, yet)
    dropper = @mvi && @mvi.at_dst? && @mvi.item
    taker   = @mvo && @mvo.at_src? && @mvo.empty?
    room    = @box.limit - @box.count
    stash   = room && dropper && 
    drop    = room || taker
    grab    = @box.count > 1 || dropper

    item_taken = dropper ? @mvi.item : @box.item

    out = []
    out.push(@mvi.eject_dispatch) if drop
    out.push(@mvo.dispatch(item_taken)) if grab
    out.push(@box.credit(@mvi.item)) if drop && !grab
    out.push(@box.debit) if grab && !drop
    out
  end

end

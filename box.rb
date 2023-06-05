require 'buffer'

class Box

  attr_reader :key
  attr_reader :buffers

  def initialize(k)
    @key = k
    @buffers = BufferArray.new
    @buffers.add_empties(5)
  end

  def make_restricted(item_class, limit)
    @buffers = BufferArray.new
    @buffers.add_restricted(item_class, limit)
  end

  def seek_to(t)
  end

  def find_end(limit)
    nil
  end

  def item_needed
    @buffers.item_needed
  end

  def full_count(droppers)
    tally = {}
    droppers.each do |m|
      tally[m.item_class] ||= 0
      tally[m.item_class] += m.population
    end
    @buffers.full_count(tally)
    tally
  end
  
  def boot(now)
  end

  def machine?
    false
  end

  def mover?
    false
  end

  def box?
    true
  end

end

class BoxResolver

  def initialize(world, box)
    @world = world
    @box   = box

    @out_movers # here potentially taking stuff
    @in_movers  # here potentially delivering stuff

    # set up whatever you need
  end

  def get_updates(out)

    movers_in  = @world.movers_into(@box.key)
    movers_out = @world.movers_outof(@box.key)

    movers_in.filter!{|m| m.at_destination? }
    movers_out.filter!{|m| m.at_source? }

    movers_in.sort!{|m1,m2| m1.compare_using_destination(m2) }
    movers_out.sort!{|m1,m2| m1.compare_using_source(m2) }

    raise @box.full_count(movers_in).inspect

    raise @world.mover_wants(movers_out[0]).inspect

    raise ({:in => movers_in, :out => movers_out}).inspect

    # sort droppers and takers by sleep time, break ties with priority

    # each taker in the list
    # see if we have what it wants somewhere, prioritize droppers.
    # if droppers is cleared, send it back
    # if taker is full, dispatch it
    # if nothing available anywhere, and they're still empty, put taker to sleep
    # if nothing available anywhere, but have at least 1, dispatch it
    
    # after all takers are serviced, there may still be droppers.
    # for each dropper remaining, see if there is storage for it.
    # if no storage or dropper can't fully unload, put dropper to sleep.
    # otherwise send dropper back (empty)

    # done!

    # push updates to the output array to be executed later
  end

end

=begin

  # this assumes they have compatible item types
  def taker_takes_from_putter(now, takers, putters)
    taker = takers.last
    putter = putter.last
    buf = putter.buffer
    wanted = taker.room
    can_get = buf.population
    if wanted < can_get
      buf.transfer_to(taker.buffer, wanted)
      taker.send_away(now)
      takers.pop
    elsif wanted == can_get
      buf.transfer_to(taker.buffer, wanted)
      taker.send_away(now)
      putter.send_away(now)
      takers.pop
      putters.pop
    else
      buf.transfer_to(taker.buffer, can_get)
      putter.send_away(now)
      putters.pop
    end
  end

  def taker_takes_from_buffer(now, takers)
    taker = takers.last
    wanted = taker.room
    can_get = @buffer.population
    if can_get < wanted
      @buffer.transfer_to(taker.buffer, can_get)
    else
      @buffer.transfer_to(taker.buffer, wanted)
      taker.send_away(now)
      takers.pop
    end
  end

  def resolve(now, movers_in, movers_out)
    putters = movers_in.filter{|mover| mover.putting_position? }.sort
    takers = movers_out.filter{|mover| mover.taking_position? }.sort

    # A (start)
    until takers.empty? || putters.empty? do
      taker_takes_from_putter(now, takers, putters)
    end

    # B (no more putters but still have takers)
    if putters.empty? && !takers.empty?
      until takers.empty? || no_more_items?(putters) do
        taker_takes_from_buffer(now, takers)
      end

      # B'
      if no_more_items?
        if takers.last && takers.last.buffer.population > 0
          takers.last.send_away(now)
          takers.pop
        end

        takers.each{|mover| mover.sleep}

        return
      end
    end

    # C (no more takers but still have putters)
    if takers.empty? && !putters.empty?
      until putters.empty? || no_more_room? do
        putter_puts_in_buffer(now, putters)
      end

      # D (no more room to put anything)
      if no_more_room?
        putters.each{|mover| mover.sleep}
      end
    end
  end

=end

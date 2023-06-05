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

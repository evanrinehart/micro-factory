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
    tally.default = 0
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

    p = BoxProcedure.new(@world, @box, movers_in, movers_out)

    p.go([])

# dumb as hell box resolution
# * make a spreadsheet of the total items of each type either in the box or being dropped off
# * for each taker, put it to sleep if it can't get anything, or credit it and dispatch, record the credits
# * for each item on the bill, pay for it by deducting from droppers or the box.
# * after bill is paid, unload as much as possible from remaining droppers into the box
# * dispatch any dropper that is fully unloaded, put the rest to sleep

    inventory = @box.full_count(movers_in)
    inventory.default = 0
    bill = {}
    bill.default = 0

    updates = []

    movers_out.each do |mover|
      item_class = @world.mover_wants(mover)
      if item_class == :any
        case inventory.find{|ic, n| n > 0 }
        in [item_class, amount_left]
          amount = [amount_left, mover.limit].min
          bill[item_class] += amount
          inventory[item_class] -= amount
          updates.push("credit #{amount} #{item_class} to mover #{mover.key}")
          updates.push("dispatch mover #{mover.key}")
        in nil
          updates.push("suspend mover #{mover.key} can't get anything at all")
        end
      else
        amount_left = inventory[item_class]
        if amount_left > 0
          amount = [amount_left, mover.limit].min
          bill[item_class]      += amount
          inventory[item_class] -= amount
          updates.push("credit #{amount} #{item_class} to mover #{mover.key}")
          updates.push("dispatch mover #{mover.key}")
        else
          updates.push("suspend mover #{mover.key} (waiting_for_source_item)")
        end
      end
    end

    # here, inventory is no longer valid. Must find exact locations for payment
    # it served its purpose
    inventory = nil

    # * for each item on the bill, pay for it by deducting from droppers or the box.
    box_db = @box.buffers.to_rows
    dropper_db = movers_in.map do |m|
      {:key => m.key, :item_class => m.item_class, :population => m.population}
    end

    bill.each do |item_class, amount_owed|

      # FIND item_class DROPPER or BUFFER (guaranteed to exist)

      while amount_owed > 0
        # if the source is in a dropper
        #     amount_owed -= min(amount_owed, amount in dropper)
        #     if dropper empty, dispatch it and remove from DB
        #     otherwise deduct the amount in the dropper accordingly (don't sleep yet)
        # else (source is a buffer with index i)
        #     amount_owed -= min(amount_owed, amount in buffer)
        #     update the buffer

        i = 0
        box_db.each do |row|
          if row.item_class == item_class
            updates.push("buffer #{row.index} deducted #{amount_owed} #{item_class}")
            row.population -= amount_owed
            amount_owed -= amount_owed
            break
          end
        end
      end

        # need to pay for amount_owed item_class
        # 1. find a source amoung the remaining droppers or buffers (guaranteed to exist)
        # 2. deduct min(amount there, amount_owed), bill_total -= that
        # 3. if dropper is unloaded, dispatch
        # 3. if amount paid = amount owed, delete from bill
        # otherwise find another source of item_class  

    end

    raise updates.inspect



#####################
# you counted everything
# for each taker, see what it wants, put it to sleep or dispatch it with >0 items
# record everything takers took
# 2nd phase
# pay down as much as possible by deducting from droppers
# fully unloaded droppers are dispatched
# other droppers are sleeped.
# if something can't be paid using droppers, deduct from buffer
###################

    #raise

    #raise @world.mover_wants(movers_out[0]).inspect

    raise updates.inspect
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



class BoxProcedure

  # this class will start with its own mutable copy of the box
  # buffers and relevant movers. Then an imperative algorithm
  # can read and write the local database and keep a log of
  # which updates to finally do (which is the final answer)

  Dropper = Struct.new(:index, :key, :item_class, :population, :limit)
  Taker   = Struct.new(:index, :key, :wanted, :population, :limit)

  def initialize(world, box, droppers, takers)
    @original_box = box

    @bill = {}
    @bill.default = 0
    @buffers = box.buffers.to_rows

    @inventory = box.full_count(droppers)

    @droppers = []
    droppers.each_with_index do |m,i|
      @droppers.push(Dropper.new(i, m.key, m.item_class, m.population, m.limit))
    end

    @takers = []
    takers.each_with_index do |m,i|
      @takers.push(Taker.new(i, m.key, world.mover_wants(m), 0, m.limit))
    end

  end

  def any_item_left
    @inventory.find do |item_class, amount|
      amount > 0
    end
  end

  def pay_bill_for_item(item_class, amount_owed)
    while amount_owed > 0
      amount_owed -= find_and_deduct(item_class, amount_owed)
    end
  end

  def find_and_deduct(item_class, amount_owed)
    @droppers.each do |dropper|
      if dropper.item_class == item_class && dropper.population > 0
        amount = [amount_owed, dropper.population].min
        dropper.population -= amount
        return amount
      end
    end

    @buffers.each do |b|
      if b.item_class == item_class && b.population > 0
        amount = [amount_owed, b.population].min
        b.population -= amount
        b.item_class = nil if b.population == 0
        return amount
      end
    end
  end

  def unload_dropper(dropper)
    while dropper.population > 0
      n = try_store(dropper.item_class, dropper.population)
      return if n == 0
      dropper.population -= n
    end
  end

  def try_store(item_class, amount)
    # try existing stacks first
    @buffers.each do |b|
      next if b.item_class.nil?
      if b.item_class == item_class && b.population < b.limit
        room = b.limit - b.population
        n = [room, amount].min
        b.population += n
        return n
      end
    end
    @buffers.each do |b|
      next unless b.item_class.nil?
      b.item_class = item_class
      b.limit = 9999 # ????, limit depends on item type?
      n = [b.limit, amount].min
      b.population += n
      return n
    end
    return 0
  end

  def buffers_differ(b1, b2)
    b1.item_class != b2.item_class ||
    b1.population != b2.population
  end

  def go(out)

    # 1. takers - are credited 1 or more items if there are any. Record it in the bill.
    @takers.each do |taker|
      item_class = taker.wanted
      if item_class == :any
        result = any_item_left
        if b.nil?
          # nothing to do
        else
          item_class  = b[0]
          amount_left = b[1]
          amount = [amount_left, taker.limit].min
          taker.population       += amount
          @bill[item_class]      += amount
          @inventory[item_class] -= amount
        end
      else
        amount_left = @inventory[item_class]
        if amount_left > 0
          amount = [amount_left, taker.limit].min
          taker.population       += amount
          @bill[item_class]      += amount
          @inventory[item_class] -= amount
        else
          # nothing to do
        end
      end
    end

    @inventory = nil

    # 2. for each bill item - deduct from droppers first then buffers to get to zero
    @bill.each do |item_class, amount_owed|
      pay_bill_for_item(item_class, amount_owed)
      @bill[item_class] = 0
    end

    # 3. droppers with anything left - attempt to store as much as possible in buffers
    @droppers.each do |dropper|
      unload_dropper(dropper)
    end

    # BELOW, the missing bits involve exactly how to report deferred updates to world

    # 4. finally, droppers empty / not empty - are dispatched / must sleep.
    #    takers empty / not empty - must sleep / are dispatched
    @droppers.each do |dropper|
      # update contents
      if dropper.population == 0
        # dispatch
      else
        # sleep
      end
    end

    @takers.each do |taker|
      # update contents
      if taker.population == 0
        # sleep
      else
        # dispatch
      end
    end

    @buffers.each do |b|
      if buffers_differ(@original_box.buffers.buffers[b.index], b)
        # update contents
      end
    end

    raise @buffers.inspect
  end

end

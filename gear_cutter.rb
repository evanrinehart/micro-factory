class GearCutter

  attr_reader :working_slot
  attr_reader :scrap_chute
  attr_reader :progress_bar
  attr_reader :status
  attr_reader :craft_period

  # status codes
  # :working
  # :waiting_for_ingredient
  # :output_blocked

  def initialize
    @working_slot = nil
    @craft_period = 60
    @progress_bar = Progress.new(@craft_period)
    @status = :waiting_for_ingredient
    @scrap_bin = 0
  end

  def find_end(limit)
    @progress_bar.find_end(limit)
  end

  def bang(t)
    return if @status != :working
    if @working_slot == :iron_plate
      if @scrap_chute == nil
        @progress_bar.reset(t)
        @working_slot = :gear
        @scrap_chute = :iron_scrap
        @status = :working
      else
        @progress_bar.freeze_at(t)
        @status = :output_full
      end
    else
      @progress_bar.freeze_at(t)
      @status = :waiting_for_ingredient
    end
  end

  def wake(t)
    @progress_bar.reset(t)
    @status = :working
  end

end

class Progress
  attr_reader :status
  attr_reader :t0
  attr_reader :t1
  attr_reader :cursor
  attr_reader :period

  def initialize(length)
    @t0 = nil
    @t1 = nil
    @cursor = 0
    @period = length
    @status = :frozen
  end

  def reset(t)
    @t0 = t
    @t1 = t + @period
    @status = :running
  end

  def freeze_at(t)
    @cursor = t - @t0
    @t0 = nil
    @t1 = nil
    @status = :frozen
  end

  def thaw_at(t)
    @t0 = t - @cursor
    @t1 = @t0 + @period
    @cursor = nil
    @status = :running
  end

  def sample(t)
    if @status == :running
      (t - @t0).to_f / @period.to_f
    else
      @cursor.to_f / @period.to_f
    end
  end

  def find_end(limit)
    if @status == :running
      @t1 <= limit ? @t1 : nil
    else
      nil
    end
  end

  def 

end


# an Area can hold an item (plate, gear).
# but could also be partially occupied.
class Area

  attr_reader :item
  attr_reader :item1
  attr_reader :item2
  attr_reader :phase

  # notation
  # [item]
  # [13% item1 | ]
  # [13% item1 | 87% item2 ]
  # [100% item1 | 0% item2 ] = [item1]
  # [0% item1 | 100% item2 ] = [item2]
  # [ | 0% item2 ] = []

  # almost forgot
  # [ 10% item | | 5% item ] (85% space between)

  def initialize
  end

  # as if there's a conveyor, move the item(s) along
  def winch(amount, status0, status1)
    
  end

end


# simple chute which can accept items instantly
# then they move into a destination if it's clear.
# and wins any tie.

class SimpleChute

  attr_reader :item
  attr_reader :percent
  attr_reader :destination_id
  attr_reader :status

  def initialize(destination_id)
    @item = nil
    @percent = 0
    @destination_id = destination_id
    @status = :idle
  end

  def clear?
    @percent == 0
  end

  def unblock
    @status = :unblocked
  end

  def put(item)
    raise("put error") if !clear?
    @item = item
    @percent = 100
    @status = :blocked
  end

  def winch(delta)
    @percent -= delta if @status = :unblocked
  end

end

# a simple chute won't begin chuting unless it
# gets the OK from the destination. 





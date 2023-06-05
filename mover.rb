require 'buffer'
require 'progress_bar'
require 'time'

class Mover

  attr_reader :key
  attr_reader :status
  attr_reader :progress_bar
  attr_reader :direction_flag
  attr_reader :source_id
  attr_reader :destination_id
  attr_reader :item_class
  attr_reader :population
  attr_reader :limit
  attr_reader :swing_period
  attr_reader :sleep_time

  # list of status codes
  # :moving_to_take
  # :moving_to_drop
  # :waiting_to_drop
  # :waiting_for_space_in_destination
  # :waiting_for_source_item

  def initialize(k,now,from,to)
    @key = k
    @status = :moving_to_take
    @swing_period = Time.from_ticks(60)
    @progress_bar = ProgressBarRunning.just_ended(now, @swing_period)
    @direction_flag = :returning
    @source_id = from
    @destination_id = to

    @item_class = nil
    @population = 0
    @limit = 1

    @sleep_time = nil
  end

  def position
    case @direction_flag
    when :returning then 1.0 - @progress_bar.fraction
    when :leaving   then       @progress_bar.fraction
    end
  end

  def position_summary
    # :zero means at source
    # :one means at destination
    # :working means somewhere between
    code = @progress_bar.summary
    if @direction_flag == :leaving
      code
    elsif code == :zero
      :one
    elsif code == :one
      :zero
    else
      code
    end
  end

  def seek_to(t)
    @progress_bar.seek_to(t)
  end

  def find_end(limit)
    @progress_bar.find_end(limit)
  end

  def mover?
    true
  end

  def machine?
    false
  end

  def box?
    false
  end

  def at_source?
    position_summary == :zero
  end

  def at_destination?
    position_summary == :one
  end

  def room
    @buffer.limit - @buffer.population
  end


"""
  def <=>(mover)
    y = @serial_no <=> mover.serial_no
    if @sleep_flag && mover.sleep_flag
      x = @sleep_time <=> mover.sleep_time
      x == 0 ? y : x
    else
      y
    end
  end
"""

end

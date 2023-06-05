require 'buffer'
require 'recipe'
require 'progress_bar'

class Machine

  attr_reader :key
  attr_reader :sleep_flag
  attr_reader :progress_bar
  attr_reader :status

  attr_reader :input_buffers
  attr_reader :output_buffers

  attr_reader :recipe

  def initialize(k)
    craft_time = Time.from_units(1)

    @key = k

    @input_buffers = BufferArray.new
    @input_buffers.add_restricted(:iron_plate, 100)

    @output_buffers = BufferArray.new
    @output_buffers.add_restricted(:gear, 100)
    @output_buffers.add_restricted(:iron_scrap, 100)

    @status = :waiting_input
    @sleep_flag = true
    @progress_bar = ProgressBarFrozen.new(0, craft_time)

    # 1 plate -> 1 gear, 1 scrap
    # 2 scrap -> 1 plate

    gear_recipe = Recipe.new(
      [Ingredient.new(:iron_plate, 1)],
      [Ingredient.new(:gear, 1),Ingredient.new(:iron_scrap, 1)],
      craft_time
    )
    @recipe = gear_recipe

    @num_consumed = 1
    @num_produced = 1
  end

  def machine?
    true
  end

  def mover?
    false
  end

  def box?
    false
  end

  def boot(now)
  end

  # this fails to account for becoming unblocked right now
  # because movers are about to take enough products
  def could_run?(item_class, n)
    return false if @status == :blocked
    return false if @status == :running
    @recipe.inputs.each do |ingredient|
      return false if !@input_buffers.has_enough(ingredient)
    end
    return true
  end

  def spooky_0?
    @input_buffer.full? && @output_buffer.room >= @num_produced
  end

  def spooky_1?
    raise "NYI"
  end

  def could_run_if_took?(n)
    # assuming we are at max progress
    # assuming we have input, if not, not big deal
    @num_produced <= @output_buffer.room - n
  end

  def unspooky?
    @progress_bar.not_full? || @input_buffer.not_full?
  end

  def seek_to(t)
    @progress_bar.seek_to(t)
  end

  def find_end(limit)
    @progress_bar.find_end(limit)
  end

  def take_item
    @output_buffer.take_item
  end

  def sleep
    @sleep_flag = true
    @progress_bar = @progress_bar.freeze
  end

  def item_needed
    @input_buffers.item_needed
  end

  def inmovers_present(inmovers)
    inmovers.filter do |mover|
      mover.progress_bar.full? && mover.status == :putting
    end
  end

  def outmovers_present(outmovers)
    outmovers.filter do |mover|
      mover.progress_bar.full? && mover.status == :taking
    end
  end

  def color_guess(out_movers)
    if @input_buffer.room > 0
      :green
    elsif @progress_bar.full? && @output_buffer.room > 0
      :green
    elsif @progress_bar.full?
      out_movers.any?{|mover| mover.green_mark } ? :green : :yellow
    else
      :red
    end
  end

end

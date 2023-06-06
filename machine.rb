require 'buffer'
require 'recipe'
require 'progress_bar'

class Machine

  attr_reader :key
  attr_reader :status
  attr_reader :progress_bar

  attr_reader :input_buffers
  attr_reader :output_buffers

  attr_reader :recipe

  # status codes for machine
  # :working
  # :waiting_for_inputs
  # :output_full

  def initialize(k)
    craft_time = Time.from_units(1)

    @key = k
    @status = :waiting_for_inputs

    @input_buffers = BufferArray.new
    @input_buffers.add_restricted(:iron_plate, 100)
    #@input_buffers.add_empties(1)

    @output_buffers = BufferArray.new
    @output_buffers.add_restricted(:gear, 100)
    @output_buffers.add_restricted(:iron_scrap, 100)

    @progress_bar = ProgressBarFrozen.new(0, craft_time)

    # 1 plate -> 1 gear, 1 scrap
    # 2 scrap -> 1 plate

    gear_recipe = Recipe.new(
      [Ingredient.new(:iron_plate, 1)],
      [Ingredient.new(:gear, 1),Ingredient.new(:iron_scrap, 1)],
      craft_time
    )
    @recipe = gear_recipe

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

  def seek_to(t)
    @progress_bar.seek_to(t)
  end

  def find_end(limit)
    @progress_bar.find_end(limit)
  end

  def item_needed
    @input_buffers.item_needed
  end

end


class MachineResolver

  # the machine has two sets of movers
  # two buffer arrays
  # and an internal store

  # status codes
  # :waiting_for_ingredients
  # :output_full
  # :working


  # waiting_for_ingredients
  # if the ingredients are now here, begin working
  # and take the ingredients from the dropper first.
  # if any dropper fully unload, send them back.
  # update the status. If not enough ingredients
  # keep waiting. Output takers might need to be
  # serviced at this time.

  # working (not 100% yet)
  # input and output movers need to be serviced

  # working (100%)
  # objects need to be converted and an attempt 
  # to output made. If there's not enough room
  # even after servicing the takers, machine stalls
  # status updated to :output_full. If output is
  # successful input is checked to see if a job can
  # be started. 

  def initialize(world, machine)
    @world = world
    @machine = machine
  end

  def get_updates(out)
  end
  

end

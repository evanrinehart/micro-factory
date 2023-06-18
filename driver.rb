class Driver

  def initialize(world)
    @divisions_per_second = 60
    @current_time = 0r
    @time_per_step = 1r / @divisions_per_second
    @world = world
  end

  def big_step
    next_time = @current_time + @time_per_step
    t = small_step(world, next_time)
    t = small_step(world, next_time) while t < next_time # !
    @current_time = next_time

    # absolute times shouldn't matter
    if @current_time == 1r
      world.sequencer.shift(1r)
      @current_time = 0r
    end
  end

  def small_step(target)
    t = world.sequencer.least_end
    world.interact_at(t) if t <= target
    t
  end

end

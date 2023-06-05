class Clock

  # a clock which simply accumulates time since it was started / created

  def initialize(k, start_time)
    @start_time = start_time
    @current_time = start_time
  end

  def delta
    @current_time - @start_time
  end

  def seek_to(t)
    @current_time = t
  end

  def find_end(limit)
    nil
  end

  def rebase_by(shift)
    @start_time += shift
    @current_time += shift
  end

  def rescale_by(s)
    @start_time *= s
    @current_time *= s
  end

end

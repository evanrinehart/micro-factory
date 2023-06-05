class ProgressBarRunning

  attr_reader :start
  attr_reader :cursor
  attr_reader :end

  def self.just_ended(now, period)
    ProgressBarRunning.new(now - period, now, now)
  end

  def self.just_started(now, period)
    ProgressBarRunning.new(now, now, now + period)
  end

  def initialize(a, x, b)
    @start = a
    @cursor = x
    @end = b
  end

  def copy
    ProgressBarRunning.new(@start, @cursor, @end)
  end

  def fraction
    (@cursor - @start).to_f / (@end - @start).to_f
  end

  def full?
    @cursor == @end
  end

  def empty?
    @cursor == @start
  end

  def seek_to(t)
    raise 'continuity error' if @end < t
    @cursor = t
  end

  def find_end(limit)
    @end <= limit ? @end : nil
  end

  def summary
    if @cursor == @start
      :zero
    elsif @cursor == @end
      :one
    else
      :working
    end
  end

  def freeze
    p = @cursor - @start
    l = @end - @start
    ProgressBarFrozen.new(p, l)
  end

  def thaw(now)
    raise "can't thaw already running progress bar"
  end

end

class ProgressBarFrozen

  attr_reader :progress
  attr_reader :length

  def initialize(p, l)
    @progress = p
    @length = l
  end

  def copy
    ProgressBarFrozen.new(@progress, @length)
  end

  def summary
    if @progress == 0
      :zero
    elsif @progress == @length
      :one
    else
      :working
    end
  end

  def seek_to(t)
  end

  def find_end(limit)
    nil
  end

  def fraction
    @progress.to_f / @length.to_f
  end

  def full?
    @progress == @length
  end

  def empty?
    @progress == 0
  end

  def thaw(now)
    a = now - @progress
    b = now
    c = a + @length
    ProgressBarRunning.new(a, b, c)
  end

  def freeze
    self
  end

end

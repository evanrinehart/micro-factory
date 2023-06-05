class Time

  # 60 ticks in 1 time unit e.g. a second
  # 800 samples per tick
  # makes 48000 samples per second

  # 735 samples per tick
  # makes 44100 samples per second

  @@divisions = 1

  ZERO      =  0
  MINUS_INF = -2**63
  INF       =  2**63 - 1

  # convert number of units to time delta
  def self.from_units(n)
    from_bab([n])
  end

  # convert number of ticks to time delta
  def self.from_ticks(n)
    from_bab([0,n])
  end

  # convert babylonian representation to abstract time delta
  def self.from_bab(parts)
    accum = 0
    part = parts.shift
    accum += part
    @@divisions.times do
      accum *= 60
      part = parts.shift
      accum += part || 0
    end
    accum
  end

  # convert abstract time delta to babylonian representation
  def self.to_bab(n)
    parts = []
    @@divisions.times do
      r = n % 60
      q = n / 60
      parts.unshift(r)
      n = q
    end
    parts.unshift(n)
    parts
  end

end

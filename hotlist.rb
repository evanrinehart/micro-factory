require 'set'

class Hotlist

  ### table : T => SetOf(Key)

  def initialize
    @table = {}
  end

  def add(t, k)
    @table[t] ||= Set.new
    @table[t].add(k)
    nil
  end

  def minimum
    return nil if @table.empty?
    accum = @table.first[0]
    @table.each_key do |t|
      accum = t if t < accum
    end
    accum
  end

  def take_entries(t)
    s = @table[t] || Set.new
    @table.delete(t)
    return s
  end

  def entries_at(t)
    @table[t] || Set.new
  end

  def delete(t)
    @table.delete(t)
  end

  def find_end(limit)
    t = minimum
    t && t <= limit ? t : nil
  end

  def seek_to(t)
  end

  def machine?
    false
  end

  def mover?
    false
  end

end

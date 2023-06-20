class ProgressPoint
  def initialize(p)
    @p = p
  end

  def to_s
    "%.5g%%" % (@p * 100)
  end
end

class SymbolPoint
  def initialize(s)
    @s = s
  end

  def to_s
    @s.inspect
  end
end

class TuplePoint
  def initialize(points)
    @points = points
  end

  def to_s
    "(%s)" % @points.join(',')
  end
end

class RecordPoint
  def initialize(fields, points)
    @fields = fields
    @points = points
  end

  def to_s
    accum = []
    @fields.each_with_index do |name, i|
      accum.push(name.to_s + '=' + @points[i].to_s)
    end
    '(' + accum.join(',') + ')'
  end
end

class StructPoint
  def initialize(struct)
    @struct = struct
  end

  def to_s
    accum = []
    @struct.members.each do |name|
      v = @struct[name]
      if v.is_a?(Symbol)
        accum.push(name.to_s + '=' + v.inspect)
      else
        accum.push(name.to_s + '=' + v.to_s)
      end
    end
    meat = accum.join(',')
    @struct.class.to_s + '[' + meat + ']'
  end
end

class TablePoint
  def initialize(table)
    @table = table
  end

  def to_s
    accum = []
    @table.each do |k,v|
      accum.push(k.to_s + '=>' + v.to_s)
    end
    '{' + accum.join(', ') + '}'
  end
end

class SplitPoint
  def initialize(a,b)
    @a = a
    @b = b
  end
  
  def to_s
    @a.to_s + '|' + @b.to_s
  end
end


class PathSig
  def initialize(a,b)
    @a = a
    @b = b
  end

  def to_s
    @a.to_s + " -> " + @b.to_s
  end
end

a = NumPoint.new(0)
b = ProgressPoint.new(0.25)
puts TuplePoint.new([a,b])
puts RecordPoint.new(
  [:item_class,:population,:limit],
  [SymbolPoint.new(:gear),3,100]
)
puts TablePoint.new({
  :k1 => 0,
  :k2 => ProgressPoint.new(0.33),
  :k3 => SymbolPoint.new(:gear)
})

puts SplitPoint.new(
  TuplePoint.new([0,ProgressPoint.new(0.25)]),
  TuplePoint.new([1,ProgressPoint.new(0.25)])
)

puts PathSig.new(ProgressPoint.new(0),b)

Buffer = Struct.new(:item_class, :population, :limit)

puts StructPoint.new(Buffer.new(:gear, 3, 10))

class TimeSpan
  attr_reader :t1, :t2
  def initialize(t1,t2)
    @t1 = t1
    @t2 = t2
  end
end

# generate point2 and the path from point1 to point2
def generate(t1, t2, point1)
end

# generate smooth path from t1 to t2, we know there's no split points
# between t1 and t2.
def generate_smooth(t1, t2, point1)
  
end

# for starters, imagine the factory is supposed to consist
# of a progress bar which starts at 0% at t=0 and increases
# to 100% at t=60. After that it stays at 100%.



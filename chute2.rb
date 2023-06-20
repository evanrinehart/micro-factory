Layer = Struct.new(:count, :item)

Cake = Struct.new(:layers) do

  def empty?
    layers.empty?
  end

  def initial
    layers.slice(0, layers.length - 1)
  end

  def size
    layers.sum{|l| l.count }
  end

  def append(cake2)
    if empty?
      cake2
    elsif cake2.empty?
      self
    elsif layers.last.item == cake2.layers.first.item
      new_array = initial
      item = layers.last.item
      n = layers.last.count + cake2.layers.first.count
      new_array.push(Layer.new(n, item))
      Cake.new(new_array + cake2.layers.slice(1..))
    end
  end

  def pop
    item = layers[0].item
    n = layers[0].count
    rest = layers.slice(1..)
    if n == 1
      [item, rest]
    else
      rest.unshift(Layer.new(n-1, item))
      [item, rest]
    end
  end

end



class Train < Array

  def split
    if length == 1
      [self[0], nil, nil]
    else
      l = length
      [self[0], self[1], self.slice(2..)]
    end
  end

  def size
    l = 0
    self.each_with_index do |x,i|
      l += i%2==0 ? x.count : x
    end
    l
  end

  def push_space(space,count,item)
    train = self.slice(0..)
    train.push(space)
    train.push(Cake.new([Layer.new(count,item)]))
  end

  def push_nospace(count,item)
    train = self.slice(0..)
    if train[-1].item
  end

end


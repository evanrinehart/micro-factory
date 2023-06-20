class ItemCake

  # a sequence of items packed into run-length encoded layers.

  attr_reader :layers

  Layer = Struct.new(:count, :item) do
    def decrement
      Layer.new(count - 1, item)
    end

    def increment
      Layer.new(count + 1, item)
    end
  end

  def initialize
    @layers = []
  end

  def empty?
    @layers.empty?
  end

  def non_empty?
    !!@layers.last
  end

  def top_item
    @layers.last.item
  end

  def top_count
    @layers.last.count
  end

  def eject
    raise("empty cake") if empty?
    layer = @layers.pop
    @layers.push(layer.decrement) if layer.count > 1
    return layer.item
  end

  def prepend(item)
    if @layers.empty?
      @layers.push(Layer.new(1,item))
    elsif @layers[0].item == item
      layer = @layers.shift
      @layers.unshift(layer.increment)
    else
      @layers.unshift(Layer.new(1,item))
    end
  end

  def prepend_cake(cake)
    if @layers.empty?
      raise("prepend_cake code won't be needed?")
    else
      if cake.top_item == @layers[0].item
        layer = @layers.shift
        n1 = cake.top_count
        n2 = layer.count
        @layers.unshift(Layer.new(n1+n2, cake.top_item))
        (cake.layers.length-2).downto(0).each{|i| @layers.unshift(cake.layers[i])}
      else
        cake.layers.reverse_each{|l| @layers.unshift(l) }
      end
    end
  end

  def total_items
    @layers.sum{|l| l.count}
  end

  def viz
    accum = []
    @layers.each do |l|
      accum.push(l.count.to_s + l.item.to_s)
    end
    '[' + accum.join(' ') + ']'
  end

  def each_item(&block)
    @layers.each do |layer|
      item = layer.item
      layer.count.times do
        yield(item)
      end
    end
  end


end




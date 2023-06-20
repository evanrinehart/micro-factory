class Chute

  Car = Struct.new(:count, :item)

  def initialize
    @length = 5
    @speed = 1r
    @bedrock = []
    @train = []
    @shrinking = nil
    @stable = true
  end

  def put(item)
    # if there's enough space add to train (two possibilities)
    # else fail
  end

  def eject
    if @bedrock[0]
      car = @bedrock[0]
      if car.count > 1
        # decrement first car
      else
        # pop bedrock
      end
      # bedrock now appended to train
    elsif @shrinking == 0
      # decrement first car if > 1
      # else pop first car and next car if it's a space
      # shrinking increased by 1 item
    end
  end

  def cut(t,t0,t1,chute1)
    delta = t - t0
    Chute.new(@shrinking - delta*@speed)
  end

  def shrink
    return self if @stable

    tail, space, head = split(@train)
    if space
      Chute.new(@length, @speed, head.merge(@bedrock), tail, space, false)
    else
      Chute.new(@length, @speed, head.merge(@bedrock), [], nil, true)
    end
  end

  def end_space
    if @stable
      @length - sizeof(@bedrock)
    else
      @length - sizeof(@train) - @shrinking - sizeof(@bedrock)
    end
  end

  def split(train)
    i = train.length - 1
    train.reverse_each do |car|
      if car.item == nil
        break
      else
        i -= 1
      end
    end
    if i < 0
      [nil, nil, train]
    else
      [train.slice(0,i), train[i].count, train.slice(i+1..)]
    end
  end

  def merge(train1,train2)
    if train1.last.item != train2.first.item
      train1 + train2
    else
      n = train1.last.count + train2.first.count
      item = train2.first.item
      car = Car.new(n, item)
      train1.slice(0,train1.length-1) + [car] + train.slice(1..)
    end
  end

  def zones_touched(z1,z2,out)
    # if space just opened up z1
    # if head just become non-empty z2
  end

end



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


# a train is either a single cake
# or two trains joined by an amount of space.
# size of single cake train is the size of the cake
# size of trains joined is size of trains + space

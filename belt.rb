require 'item_cake'

class Belt

  def initialize(length,speed)
    @length = length
    @speed = speed # in items / s
    @front = ItemCake.new
    @train = []
    @shrink_space = 0
    @grow_space = length
  end

  def puttable?
    @grow_space >= 1
  end

  def ejectable?
    @front.non_empty? || (@shrink_space == 0 && @train.last)
  end

  def peek
    if @front.non_empty?
      @front.last.item
    elsif @shrink_space == 0 && @train.last
      @train.last.item
    end
  end

  def put(item)
    return unless puttable?
    #raise("item collision") unless puttable?

    if @train.empty?
      if @grow_space == 1 ## totally packed belt
        @front.prepend(item)
        @grow_space = 0
      else ## new train
        car = ItemCake.new
        car.prepend(item)
        @train = [car]
        @shrink_space = @length - 1 - @front.total_items
        @grow_space = 0
      end
    else
      if @grow_space == 1 ## fits exactly on the end of train
        @train[0].prepend(item)
        @grow_space = 0
      else ## new trailing cake + space on end of train
        space = @grow_space - 1
        @train.unshift(space)
        car = ItemCake.new
        car.prepend(item)
        @train.unshift(car)
        @grow_space = 0
      end
    end
  end

  def eject
    return unless ejectable?
    #raise("empty belt") unless ejectable?

    if @front.non_empty?
      eject_front
    elsif @shrink_space == 0
      eject_train
    end
  end

  def eject_front
    item = @front.eject

    if @train.empty?
      if @front.empty?
        @shrink_space = 0
        @grow_space = @length
      else
        @train.push(@front)
        @shrink_space = 1
        @front = ItemCake.new
      end
    else
      if @front.empty?
        @shrink_space += 1
      else
        # non-empty train and front
        @train.push(@shrink_space)
        @train.push(@front)
        @shrink_space = 1
        @front = ItemCake.new
      end
    end

    item
  end

  def eject_train
    car = @train.last
    space = @train[-2]

    item = car.eject # updates cake

    if car.empty?
      if space
        @shrink_space += 1
        @shrink_space += space
        @train.pop
        @train.pop
      else
        @train = []
        @shrink_space = 0
        @grow_space = @length
      end
    else
      @shrink_space += 1
    end

    item
  end

  def block
  end

  def shrink
    return if @shrink_space == 0

    car   = @train.last
    space = @train[-2]

    if @front.empty?
      @front = car
    else
      @front.prepend_cake(car)
    end

    if space # more train follows
      @grow_space += @shrink_space
      @train.pop
      @train.pop
      @shrink_space = space
    else
      @grow_space += @shrink_space
      @train = []
      @shrink_space = 0
    end
  end

  def winch(delta_t)
    delta_x = @speed*delta_t
    if @shrink_space - delta_x <= 0
      shrink
    else
      @shrink_space -= delta_x
      @grow_space   += delta_x
    end
  end

  def scan_left
    if @train.empty?
      Float::INFINITY
    elsif @grow_space >= 1
      Float::INFINITY
    else
      (1 - @grow_space).to_r / @speed
    end
  end

  def scan_right
    if @front.empty? && @shrink_space > 0
      @shrink_space.to_r / @speed
    else
      Float::INFINITY
    end
  end

  def fmt(x)
    '%g' % x.truncate(4)
  end

  def viz
    accum = ["belt["]
    accum.push("v=%g " % @speed)
    accum.push(fmt(@grow_space))
    accum.push(' ')
    accum.push(viz_train(@train))
    accum.push(' ')
    accum.push(fmt(@shrink_space))
    accum.push(' ')
    accum.push(@front.viz)
    accum.push(']')
    accum.join('')
  end

  def viz_train(train)
    accum = []
    train.each_with_index do |elem,i|
      if i%2==0
        accum.push(elem.viz)
      else
        accum.push(sprintf("%g",elem.truncate(5)))
      end
    end
    '[' + accum.join(' ') + ']'
  end

  def each_item(&block)
    cursor = @grow_space
    @train.each_with_index do |cake_or_space, i|
      if i%2==0
        cake_or_space.each_item do |item|
          yield(cursor, item)
          cursor += 1
        end
      else
        cursor += cake_or_space
      end
    end

    cursor += @shrink_space

    @front.each_item do |item|
      yield(cursor, item)
      cursor += 1
    end
  end

end




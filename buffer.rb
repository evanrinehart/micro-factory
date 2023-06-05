class RestrictedBuffer
  attr_reader :item_class
  attr_reader :population
  attr_reader :limit

  def initialize(item_class, population, limit)
    @item_class = item_class
    @population = population
    @limit = limit
  end

  def restricted?
    true
  end

  def full?
    @population == @limit
  end

  def empty?
    @population == 0
  end

  def room
    @limit - @population
  end

  def change_amount(n)
    @population += n
    raise("buffer underflow") if @population < 0
    raise("buffer overflow")  if @population > @limit
  end
end

class EmptyBuffer

  SINGLETON = EmptyBuffer.new

  def item_class
    nil
  end

  def population
    0
  end

  def restricted?
    false
  end

  def full?
    false
  end

  def empty?
    true
  end

end

class BufferArray

  attr_reader :buffers

  def initialize
    @buffers = []
  end

  def clear_buffers
    @buffers.clear
  end

  def add_empties(n)
    n.times{ @buffers.push(EmptyBuffer::SINGLETON) }
  end

  def add_restricted(item_class, limit)
    @buffers.push(RestrictedBuffer.new(item_class, 0, limit))
  end

  def find_nonfull_buffer_for(item_class)
    @buffers.each_with_index do |b,i|
      return i if b.item_class.nil?
      next if b.item_class != item_class
      return i if b.room > 0
    end
    return nil
  end

  def find_buffer_containing(item_class)
    @buffers.each_with_index do |b,i|
      next if b.item_class.nil?
      next if b.item_class != item_class
      return i
    end
    return nil
  end

  def find_something
    @buffers.each_with_index do |b,i|
      next if b.item_class.nil?
      next if b.empty?
      return i
    end
    return nil
  end

  def item_needed
    @buffers.each do |b|
      return :any if b.item_class.nil?
      next if b.full?
      return b.item_class
    end
    return nil
  end

  def has_enough(ingredient)
    count_item(ingredient.item_class) >= ingredient.amount
  end

  def count_item(klass)
    accum = 0
    @buffers.each do |b|
      next if b.item_class != klass
      accum += b.population
    end
    accum
  end

end

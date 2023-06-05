class EndFinder

  attr_reader :time
  attr_reader :enders

  def initialize(limit)
    @enders = []
    @time = nil
    @limit = limit
  end

  def insert(obj)
    t = obj.find_end(@limit)
    return if t.nil?
    return if @time && @time < t
    @time = t if @time.nil?
    if t < @time
      @enders.clear
      @enders.push(obj)
      @time = t
    else # equal
      @enders.push(obj)
    end
  end

  def machines
    @enders.filter{|x| x.machine? }
  end

  def movers
    @enders.filter{|x| x.mover? }
  end
    
end

class Mapping

  # relies on objects supporting interface
  # s0.grow(t0) => [t1, s1]
  # s0.cut(t,t0,t1,s1) => s at intermediate time

  # relies on time points supporting
  # equality test ==
  # less than test <
  # point at the end of time

  Path = Struct.new(:t0, :s0, :t1, :s1)

  def initialize
    @current_time = 0
    @paths = {}
  end

  def put(k,t0,s0)
    t1,s1 = s0.grow(t0)
    @paths[k] = Struct.new(t0,s0,t1,s1)
  end

  def delete(k)
    @paths.delete(k)
  end

  def least_end
    t = Float::INFINITY
    @paths.each{|p| t = p.t1 if p.t1 < t}
    t
  end

  def devices_ending_at(t)
    r = {}
    @paths.each{|p,k| r[k] = p.s1 if p.t1 == t }
    r
  end

  def cut(k,t)
    p = @path[k]
    @path[k].s0.cut(t,p.t0,p.t1,p.s1)
  end

  def shift(dt)
    paths = {}
    @paths.each do |k,p|
      paths[k] = Path.new(p.t0 - dt, p.s0, p.t1 - dt, p.s1)
    end
    @paths = paths
  end
  
end

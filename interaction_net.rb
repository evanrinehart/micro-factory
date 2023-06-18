class InteractionNet

  # [a]⇆[b]⇆[c]⇆[d]⇆[e]

  def initialize(components)
    @components = components

    @components.each_cons(2) do |a,b|
      a.downstream = b
      b.upstream   = a
    end
  end

  def interact
    @components.reverse_each{|c| c.interact }
    :ok
  end

  def commit(t,world)
    @components.each{|c| c.commit(t, world) }
    :ok
  end

end

class NullServer

  attr_writer :upstream
  attr_writer :downstream

  def get(desc)
    404
  end

  def put(item)
    507
  end

  def interact
  end

  def commit(t,world)
    @upstream = nil
    @downstream = nil
  end

end


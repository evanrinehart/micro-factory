class SourceZone

  # chute is connected
  # as soon as there is room in the chute, item is output to it

  def initialize(item, chute)
    @item = item
    @chute = chute
  end

  def open_interact_commit_close(t, world)
    world.modify(@chute, t){|chute| chute.put(@item) }
  end

end



class SinkZone

  def initialize(chute)
    @chute = chute
  end 

  def open_interact_commit_close(t, world)
    world.modify(@chute, t){|chute| chute.eject }
  end

end

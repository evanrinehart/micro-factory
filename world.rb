class World

  # world contains everything in the world

  def initialize
    @sequencer = Mapping.new
    @zones = {}
  end

  def add_zone(k,zone)
    # a zone or interaction zone is a collection of devices which
    # interact in a certain way, e.g. a machine with all the things connected to it
    @zones[k] = zone
  end

  def get(k,t)
    @sequencer.cut(k,t)
  end

  def put(k,t,s)
    @sequencer.put(k,t,s)
  end

  def print_zone(k)
    @zones[k].print
  end

  def zones_touched_by(t, k)
    raise("the data might not exist")
    # e.g. craft core touches machine zone
    # chute touches up to two zones depending
    # mover touching zone it has arrived at
  end

  def interact_at(t)
    enders = @sequencer.devices_ending_at(t)

    active_zones = Set.new
    enders.each do |k|
      zones_touched_by(t, k).each{|zone| active_zones.add(zone)}
    end

    # when done, the timelines which end at t must now end some time after t
    active_zones.each do |zone|
      zone.open_interact_commit_close(t, self)
    end
  end

end




=begin

Speed1 = Struct.new(:time)
Speed2 = Struct.new(:per_second)

Stack  = Struct.new(:count, :item) do
  def credit(n)
    Stack.new(count + n, item)
  end

  def debit(n)
    raise("debit error") if count < n
    count == n ? nil : Stack.new(count - n, item)
  end
end

Recipe = Struct.new(:ingredients, :products, :speed)


CraftingCore = Struct.new(:recipe, :heart, :input_array, :output_array)


re = Recipe.new(
  [Stack.new(1,:plate)],
  [Stack.new(1,:gear), Stack.new(1,:scrap)],
  Speed1.new(60)
)

=end

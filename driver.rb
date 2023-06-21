class Driver

  # there's a set of zones where interactions take place
  # there's a set of 'sprites' which animate until activating zones
  # there's edge sprites which connect two zones
  # there's node sprites which are associated with 1 zone
  # there's "stills" which don't animate and only react

  Edge = Struct.new(:sprite, :z1, :z2)
  Node = Struct.new(:sprite, :z)

  def initialize
    @zones = {}
    @edge_sprites = {}
    @node_sprites = {}
    @stills = {}
  end

  def add_zone(z, zone)
    @zones[z] = zone
  end

  def add_edge_sprite(k, sprite, z1, z2)
    @edge_sprites[k] = Edge.new(sprite, z1, z2)
  end

  def add_node_sprite(k, sprite, z)
    @node_sprites[k] = Node.new(sprite, z)
  end

  def add_still(k, still)
    @stills[k] = still
  end

  def scan(current_time)
    zones = Set.new
    least_t = Float::INFINITY

    @node_sprites.each do |k,node|
      t = current_time + node.sprite.scan
      if t == least_t
        zones.add(node.z)
      elsif t < least_t
        zones.clear
        zones.add(node.z)
        least_t = t
      end
    end

    @edge_sprites.each do |k,node|
      t1 = current_time + node.sprite.scan_left
      t2 = current_time + node.sprite.scan_right

#puts "k=#{k} sl=#{t1} sr=#{t2}"

      if t1 == least_t
        zones.add(node.z1)
      elsif t1 < least_t
        zones.clear
        zones.add(node.z1)
        least_t = t1
      end

      if t2 == least_t
        zones.add(node.z2)
      elsif t2 < least_t
        zones.clear
        zones.add(node.z2)
        least_t = t2
      end
    end

    [least_t, zones]
  end

  def winch(delta)
    @node_sprites.each do |k,node|
      node.sprite.winch(delta)
    end

    @edge_sprites.each do |k,edge|
      edge.sprite.winch(delta)
    end
  end

  def small_step(t0,t1)
    t, zs = scan(t0)
#puts "small_step t=#{t} t0=#{t0} t1=#{t1}"
    if t <= t1
      winch(t - t0)
      zs.each do |z|
        @zones[z].interact
      end
      t
    else
      winch(t1 - t0)
      t1
    end
  end

  def big_step(t0,t1)
  #puts ""
  #puts "big step t0=#{t0} t1=#{t1}"
    t = small_step(t0,t1)
    raise 'constraint violation 1' if t == t0
    while t < t1
      previous_t = t
      t = small_step(t,t1)
      raise 'constraint violation 2' if t == previous_t
    end
      
  end

  def time_shift(delta_t)
    # currently nothing caches absolute times
  end

end

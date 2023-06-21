class Driver

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

      if t == current_time
        raise "progress error (k=#{k} z=#{node.z})"
      end

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

      if t1 == current_time || t2 == current_time
        raise "progress error (k=#{k} z1=#{node.z1} z2=#{node.z2})"
      end
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

    if t > t1
      winch(t1 - t0)
      t1
    else
      winch(t  - t0)
      zs.each{|z| @zones[z].interact }
      t
    end
  end

  def big_step(t0,t1)
    t = small_step(t0,t1)
    t = small_step(t, t1) while t < t1
  end

end

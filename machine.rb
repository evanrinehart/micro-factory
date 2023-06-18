# machine (zone)
# crafting core (device / entity)
# output server (server)
# input server  (server)
# crafting core server (server)


class MachineZone

  def initialize(droppers,input,core,output,takers)
    # zone holds all the keys to its components
    @droppers = droppers
    @input = input
    @core = core
    @output = output
    @takers = takers
  end

  def open_interact_commit_close(t, world)
    inmover_servers = @droppers.map{|k| world.get(k,t).to_dropper(k) }
    c1 = DroppersServer.new(inmover_servers)
    c2 = InputServer.new
    c3 = CraftingCore.new(@core, world.get(@core, t))
    c4 = OutputServer.new
    outmover_servers = @takers.map{|k| world.get(k,t).to_taker(k) }
    c5 = TakersServer.new(outmover_servers)
    
    net = InteractionNet.new([c1,c2,c3,c4,c5])
    net.interact
    net.commit(t, world)
  end

end

=begin
class MachineZoneInteracting

  def initialize(droppers,input,core,output,takers)
    # [>] [I] [X] [O] [>]
    @droppers = droppers
    @droppers.downstream = input
    @input = input
    @input.droppers = droppers
    @input.downstream = core
    @core = core
    @core.upstream = input
    @core.downstream = output
    @output = output
    @output.upstream = core
    @output.takers = takers
    @takers = takers
    @takers.upstream = output
  end

  def go
    @takers.each{|taker| taker.go}
    @core.go
    @droppers.each{|dropper| dropper.go}
  end

  def close(t,world)
    @droppers.each{|obj| update(t,world,obj)}
    @input.update(t,world)
    update(t,world,@core)
    update(t,world,@output)
    @takers.each{|obj| update(t,world,obj)}
  end

  def update(t,world,serv)
    k = serv.key
    dev0 = world.get(k)
    dev1 = serv.close(dev0)
    world.put(k, t, dev1) 
  end

end
=end


class CraftingCore

  # [[stuff] 45% []]

  attr_reader :heart      # a timer or an oscillator
  attr_reader :recipe
  attr_reader :buffer_in  # array of stacks/nil
  attr_reader :buffer_out # array of stacks/nil

  def initialize(heart, recipe, buffer_in, buffer_out)
    @heart = heart
    @recipe = recipe
    @buffer_in = buffer_in
    @buffer_out = buffer_out
  end

  def grow(t0)
    t1, heart1 = @heart.grow(t0)
    [t1, CraftingCore.new(heart1, @recipe, @buffer_in, @buffer_out)]
  end

  def cut(t,t0,t1,cc1)
    h = @heart.cut(t,t0,t1,cc1.heart)
    CraftingCore.new(h, @recipe, @buffer_in, @buffer_out)
  end

  def to_server
    if @heart.timeout?
      CraftingCoreServer.new(
    else
      
    end
  end


end


class Timer

  # absolute time here relies on support for
  # t0 + delta = t1
  # t1 - t0 = delta

  def initialize(left)
    @left = left
  end

  def grow(t0)
    [t0 + @left, Timer.new(0)]
  end

  def cut(t,t0,t1,timer1)
    Timer.new(t1 - t)
  end

  def timeout?
    @left == 0
  end

end

class Oscillator

  def initialize(stage, per_second, t)
    @stage = stage # 0 to per_second
    @per_second = per_second
    @timeout = t == alarm_time
  end

  def alarm_time
    Rational(@stage, @per_second)
  end

  def grow(t0)
    t1 = alarm_time
    [t1, Oscillator.new(@stage, @per_second, t1)]
  end

  def cut(t,t0,t1,osc1)
    Oscillator.new(@stage, @per_second, t)
  end

  def timeout?
    @timeout
  end

end

class OutputServer

  attr_writer :upstream
  attr_writer :downstream

  def put_many(items)

    begin_transaction

    items.each do |count, item|
      count.times do
        ok = false
        @downstream.each do |taker|
          if taker.put(item) == 200
            ok = true
            break
          end
        end
        if ok == false
          rollback_transaction
          return 507
        end
      end
    end

    commit_transaction

  end

  def begin_transaction
    # backup the state of internal buffers and
    # backup the state of takers
    @backup = {}
    @downstream.each do |taker|
      @backup[taker.key] = taker.dump
    end
  end

  def rollback_transaction
    # restore state of internal buffers and takers
    # forget backup
    @backup.each do |k,s|
      @downstream[k].restore(s)
    end
  end

  def commit_transaction
    @backup = nil
  end

  def commit(t,world)
    @upstream = nil
    @downstream = nil
  end

end

class InputServer

  attr_writer :downstream
  attr_writer :upstream # array of droppers

  def get(desc)
    @upstream.get(desc)
  end

  def put(item)
    @downstream.put(item)
  end

  def interact
  end

  def available_items
    @upstream.available_items
  end

  def commit(t,world)
    @upstream   = nil
    @downstream = nil
  end

end


class CraftingCoreServer

  attr_writer :upstream
  attr_writer :downstream

  def initialize(key, cc)
    @key = key
    @recipe = cc.recipe
    @status = :working # have exactly the ingredients internally buffered
    @status = :working_done # same
    @status = :ejecting # have the products internally buffered
    @status = :intaking # have nothing buffered
  end

  def get(desc)
    # if they could take everything, they would have gotten everything
    # so either they can't take everything (or anything) or there's nothing here.
    404
  end

  def put(item)
  end

  def interact
    case @status
    when :working
      nil
    when :working_done
      # ingredients consumed, products produced. In principle
      @status = :ejecting
      interact
    when :ejecting
      # ATTEMPT TO OUTPUT ALL THE PRODUCTS DOWNSTREAM.
      case @downstream.put_many(@recipe.products)
      when 200
        @status = :intaking
        interact
      else
        nil
      end
    when :intaking
      # get all the ingredients if it would work
      item_list = @upstream.available_items
      if @recipe.enough_ingredients_in(item_list)
        @recipe.ingredients.each do |count,item|
          count.times{ @upstream.get(item) }
        end
        @status = :working
      end
      nil
    end
  end

  def commit(t,world)
    @upstream = nil
    @downstream = nil
    cc_minus = world.get(@key,t)
    cc_plus  = update(cc_minus)
    world.put(@key,t,cc_plus)
  end

  def update(cc)
    case @status
    when :working
      cc.start_craft
    when :working_done
      raise("you wouldn't end up in this state")
    when :ejecting
      cc.output_stall
    when :intaking
      cc.input_stall
    end
  end

end

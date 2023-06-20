require 'belt'

class VoidZone

  def initialize(input)
    @input = input
  end

  def interact
    @input.eject
  end

end

class ItemGenZone

  def initialize(item,output)
    @item = item
    @output = output
  end

  def interact
    @output.put(@item)
  end

end

class SplitZone

  def initialize(input,out0,out1)
    @state = 0
    @input = input
    @out0 = out0
    @out1 = out1
  end

  def interact
    if !@input.ejectable?
      nil
    elsif @out0.puttable? && (@state == 0 || !@out1.puttable?)
      @out0.put(@input.eject)
      @state = 1
    elsif @out1.puttable? && (@state == 0 || !@out0.puttable?)
      @out1.put(@input.eject)
      @state = 0
    else
      @input.block
    end
  end

end


b = Belt.new(20,1/7r)
igz = ItemGenZone.new(:gear,b)
vz = VoidZone.new(b)

igz.interact

def small_step(b,igz,vz,t0,t1)
  u1 = b.left_end(t0)
  u2 = b.right_end(t0)
  t = u1 < u2 ? u1 : u2

  #puts "small step t0=#{t0} t1=#{t1} t=#{t.to_f}"
  if t <= t1
    b.winch(t-t0)
    igz.interact if t == u1
    vz.interact  if t == u2
    t
  else
    b.winch(t1-t0)
    t1
  end

end


t0 = 0
100.times do
  t1 = t0 + 0.1r
  #puts "#{t0.to_f} #{t1.to_f}"
  t = small_step(b,igz,vz,t0,t1)
  t = small_step(b,igz,vz,t,t1) while t < t1
  t0 = t1
  puts "t=#{t1.to_f} #{b.viz}"
end



class Driver

  

end

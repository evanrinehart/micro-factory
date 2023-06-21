class NoopZone

  def interact
  end

end

class VoidZone

  def initialize(input)
    @input = input
  end

  def interact
    @input.eject
  end

end

class BlockageEdge

  def puttable?
    false
  end

  def ejectable?
    false
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
#puts "split zone #{self.inspect}"
#puts "state = #{@state}"
#puts "out0 puttable #{@out0.puttable?}"
#puts "out1 puttable #{@out1.puttable?}"
#puts "in ejectable #{@input.ejectable?}"
    if !@input.ejectable?
      nil
    elsif @out0.puttable? && (@state == 0 || !@out1.puttable?)
      @out0.put(@input.eject)
      @state = 1
    elsif @out1.puttable? && (@state == 1 || !@out0.puttable?)
      @out1.put(@input.eject)
      @state = 0
    else
      #@input.block
    end
  end

end

class MergeZone

  def initialize(in0, in1, output)
    @state = 0
    @in0 = in0
    @in1 = in1
    @output = output
  end

  def interact
    if !@output.puttable?
      nil
    elsif @in0.ejectable? && (@state == 0 || !@in1.puttable?)
      @output.put(@in0.eject)
      @state = 1
    elsif @in1.ejectable? && (@state == 1 || !@in0.puttable?)
      @output.put(@in1.eject)
      @state = 0
    end
  end

end

class ConversionZone

  def initialize(item1,item2,input,output)
    @item1 = item1
    @item2 = item2
    @input = input
    @output = output
  end

  def interact
    if @input.ejectable? && @output.puttable?
      item = @input.peek
      if item == @item1
        @input.eject
        @output.put(@item2)
      end
    end
  end

end

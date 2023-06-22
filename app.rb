require 'ruby2d'

require 'belt'
require 'zones'
require 'driver'

set title: "FactIOry"
#set fullscreen: true

def spawn_line(x1,y1,x2,y2)
  Line.new(
    x1: x1, y1: y1,
    x2: x2, y2: y2,
    width: 1
  )
end

def spawn_circle(x,y)
  Circle.new(
    x: x+8,
    y: y+8,
    radius: 6,
    color: "red",
    sectors: 15
  )
end

def spawn_block(x,y)
  Square.new(x: x+2, y: y+2, size: 12, color: 'blue')
end

def spawn_triangle(x,y)
  Triangle.new(
    x1: x+2, y1: y+14,
    x2: x+8, y2: y+2,
    x3: x+14, y3: y+14,
    color: 'green'
  )
end

def spawn_cell(x,y)
  Square.new(
    x: x, y: y,
    size: 16,
    color: 'green'
  )
end

def spawn_box(x,y)
  Line.new(x1: x, y1: y, x2: x+16, y2: y, color: 'gray', width: 1)
  Line.new(x1: x+16, y1: y, x2: x+16, y2: y+16, color: 'gray', width: 1)
  Line.new(x1: x+16, y1: y+16, x2: x, y2: y+16, color: 'gray', width: 1)
  Line.new(x1: x, y1: y+16, x2: x, y2: y, color: 'gray', width: 1)
end

def polyline(points)
  p0 = points[0]
  p1 = nil
  (1..points.length-1).each do |i|
    p1 = points[i]
    Line.new(x1: p0.x, y1: p0.y, x2: p1.x, y2: p1.y, width: 1)
    p0 = p1
  end
end

P = Struct.new(:x, :y) do
  def plus_x(arg)
    P.new(x+arg, y)
  end
  def plus_y(arg)
    P.new(x, y+arg)
  end
end

class TestArticles

  def initialize
    @art1 = spawn_circle(16,16)
    @art2 = spawn_block(32,16)
    @art3 = spawn_triangle(32,32)
    @art4 = spawn_box(16,16)
  end

  def refresh
  end

end


class Layouter

  def initialize(start)
    p = start.plus_x(8).plus_y(8)
    @points = [p]
    @cursor = p
  end

  def right(n)
    @cursor = @cursor.plus_x(n*16)
    @points.push(@cursor)
    self
  end

  def down(n)
    @cursor = @cursor.plus_y(n*16)
    @points.push(@cursor)
    self
  end

  def left(n)
    @cursor = @cursor.plus_x(-n*16)
    @points.push(@cursor)
    self
  end

  def up(n)
    @cursor = @cursor.plus_y(-n*16)
    @points.push(@cursor)
    self
  end

  def path
    @points
  end
    
end


class BeltTrace

  def initialize(path)
    @path = path
  end

  def distance(p0,p1)
    if p0.x == p1.x
      (p1.y - p0.y).abs
    elsif p0.y == p1.y
      (p1.x - p0.x).abs
    else
      raise("diagonal distance")
    end
  end

  def item_coord_to_screen_coord(x)
    x * 16 + 8
  end

  def lerp_x(frac,p0,p1)
    # a + (b - a)*frac
    a = p0.x
    b = p1.x
    a + (b - a)*frac
  end

  def lerp_y(frac,p0,p1)
    # a + (b - a)*frac
    a = p0.y
    b = p1.y
    a + (b - a)*frac
  end

  def render_belt(belt)
    total_dist = 0
    cursor_x = 0
    cursor_i = 0

    p0 = @path[cursor_i]
    p1 = @path[cursor_i+1]
    len = distance(p0,p1)

    belt.each_item do |d,item|
      delta = d - total_dist
      total_dist = d
      cursor_x += delta*16
      while cursor_x > len
        cursor_x -= len
        cursor_i += 1
        p0 = p1
        p1 = @path[cursor_i+1]
        len = distance(p0,p1)
      end

      x = lerp_x(cursor_x.to_f / len, p0, p1) - 8
      y = lerp_y(cursor_x.to_f / len, p0, p1) - 8

      spawn_triangle(x,y)
    end
  end
end

b   = Belt.new(26,6)
b2  = Belt.new(9,3)
b3  = Belt.new(11,3)
igz = ItemGenZone.new(:gear,b)
vz1  = VoidZone.new(b2)
vz2  = VoidZone.new(b3)
spl = SplitZone.new(b,b2,b3)

igz.interact

driver = Driver.new
driver.add_zone(1, igz)
driver.add_zone(2, vz1)
driver.add_zone(3, vz2)
driver.add_zone(4, spl)
driver.add_edge_sprite(5, b, 1, 4)
driver.add_edge_sprite(6, b2, 4, 2)
driver.add_edge_sprite(7, b3, 4, 3)

@b = b
@b2 = b2
@b3 = b3
@driver = driver
@t0 = 0
@t1 = nil

split_point = P.new(16+15*16, 128)
@path1 = Layouter.new(P.new(16,128)).right(5).down(5).right(10).up(5).path
@path2 = Layouter.new(split_point).left(3).up(5).path
@path3 = Layouter.new(split_point).right(5).down(5).path
@trace1 = BeltTrace.new(@path1)
@trace2 = BeltTrace.new(@path2)
@trace3 = BeltTrace.new(@path3)

@frame = 0
@second_counter = 0

@sixty = 60

def format_driver_time(n,t)
  ticks = sprintf '%02d', (t * @sixty).to_i
  "#{n}:#{ticks}"
end

font = 'fonts/RobotoCondensed-Regular.ttf'
@text  = Text.new( '', x: 0, y: 0, font: font, size: 12, z: 10)
@text2 = Text.new('?',x: 0, y: 10, font: font, size: 12, z: 10)
#@text.remove

@test_articles = TestArticles.new

def one_update
  #puts "t=#{format_driver_time(@second_counter, @t0)} b2=#{@b2.viz}"

  @t1 = @t0 + 1r/@sixty
  @driver.big_step(@t0,@t1)
  @t0 = @t1

  @frame += 1

  if @t1 == 1
    @t1 = 0
    @t0 = 0
    @second_counter += 1
    #@driver.time_shift(1)
  end
end

on :key_down do
  close
end

on :mouse_move do |event|
  x = event.x
  y = event.y
  dx = event.delta_x
  dy = event.delta_y
  
  msg = "mouse[x=#{x} y=#{y} dx=#{dx} dy=#{dy}]"

  @text2.text = msg
end

update do
  clear

  one_update

  # display the items on the 3 belts, along the given paths
  @trace1.render_belt(@b)
  @trace2.render_belt(@b2)
  @trace3.render_belt(@b3)

  # several 'test' shapes
  #@test_articles.refresh
  
  # these lines trace over the paths of the 3 belts
  polyline @path1
  polyline @path2
  polyline @path3

  # display the game clock
  @text.text = "t = #{format_driver_time(@second_counter, @t0)}"
  @text.add
  @text2.add
end

show



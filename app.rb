require 'ruby2d'

set title: "FactIOry"
#set fullscreen: true

@gears = []

@master_gear = Sprite.new(
  'gear.png',
  x: rand(640),
  y: rand(480),
  width: 16, height: 16,
  #color: [1.0,1.0,1.0,1.0],
  #rotate: 0,
  #z: 10
)
@master_gear.remove

def spawn_gear(x,y)
  gear = @master_gear.dup
  gear.x = x
  gear.y = y
  gear.add
  @gears.push(gear)
end

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

on :key_down do
  
  close
end

P = Struct.new(:x, :y) do
  def plus_x(arg)
    P.new(x+arg, y)
  end
  def plus_y(arg)
    P.new(x, y+arg)
  end
end

class Layouter

  def initialize(start)
    puts start.inspect
    p = start.plus_x(8).plus_y(8)
    puts p.inspect
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

@path = Layouter.new(P.new(16,128)).right(5).down(5).right(10).up(5).path

t = 0
update do
  clear

  spawn_circle(16,16)
  spawn_block(32,16)
  spawn_triangle(32,32)
  spawn_box(16,16)
  
  polyline @path
  @path.each do |p|
    spawn_box(p.x-8, p.y-8)
  end
end


show

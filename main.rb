require 'world'
require 'sim'

require 'pp'

w = World.new
sim = Sim.new(w)
sim.demo

puts "Before:"
pp w
puts ""

puts w.things[2].item_needed.inspect

puts "After:"
t_reached = sim.small_step(Time.from_units(5))
pp w
puts "time reached = #{t_reached}"

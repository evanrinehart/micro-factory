require 'world'
require 'sim'

require 'pp'

w = World.new
sim = Sim.new(w)
sim.demo

puts "Before:"
pp w
puts ""

puts "After:"
puts "from_bab '12:34:56' => #{Time.from_bab([12,34,56])}"
puts "to_bab 45296 => #{Time.to_bab(45296)}"
puts "from_units 345 => #{Time.from_units 345}"
puts "from_ticks 100 => #{Time.from_ticks 100}"
t_reached = sim.small_step(1800)
pp w
pp t_reached



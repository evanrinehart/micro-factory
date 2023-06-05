require 'time'

Ingredient = Struct.new(
  :item_class,
  :amount
)

Recipe = Struct.new(
  :inputs,
  :outputs,
  :time
)


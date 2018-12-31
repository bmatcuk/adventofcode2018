defmodule AoC.Day9.Game do
  defstruct counter_clockwise: %{0 => 0}, clockwise: %{0 => 0}

  def clockwise(_game, marble, 0) do
    marble
  end

  def clockwise(game, marble, num) when num > 0 do
    clockwise(game, Map.get(game.clockwise, marble), num - 1)
  end

  def counter_clockwise(_game, marble, 0) do
    marble
  end

  def counter_clockwise(game, marble, num) when num > 0 do
    counter_clockwise(game, Map.get(game.counter_clockwise, marble), num - 1)
  end

  def insert_after(game, marble, value) do
    %{game |
      counter_clockwise: Map.put(
        Map.put(game.counter_clockwise, value, marble),
        Map.get(game.clockwise, marble),
        value),
      clockwise: Map.put(
        Map.put(game.clockwise, value, Map.get(game.clockwise, marble)),
        marble,
        value),
    }
  end

  def remove(game, marble) do
    %{game |
      counter_clockwise: Map.put(
        game.counter_clockwise,
        Map.get(game.clockwise, marble),
        Map.get(game.counter_clockwise, marble)),
      clockwise: Map.put(
        game.clockwise,
        Map.get(game.counter_clockwise, marble),
        Map.get(game.clockwise, marble)),
    }
  end
end

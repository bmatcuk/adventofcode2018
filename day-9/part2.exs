# run with elixir -r game.ex part2.exs
defmodule AoC.Day9.Part2 do
  @moduledoc """
  --- Part Two ---
  Amused by the speed of your answer, the Elves are curious:

  What would the new winning Elf's score be if the number of the last marble
  were 100 times larger?
  """

  alias AoC.Day9.Game, as: Game

  @input_regex ~r/(?<num_players>\d+) players; last marble is worth (?<last_marble>\d+) points/

  def run(filename) do
    File.read!(filename)
    |> (&Regex.named_captures(@input_regex, &1)).()
    |> Enum.into(%{}, fn {k, v} -> {k, String.to_integer(v)} end)
    |> play_game
    |> elem(1)
    |> Map.values
    |> Enum.max
  end

  def play_game(%{"num_players" => num_players, "last_marble" => last_marble}) do
    Enum.reduce(1..(last_marble * 100), {%Game{}, %{}, 0}, fn marble, {game, players, current} ->
      if rem(marble, 23) == 0 do
        remove = Game.counter_clockwise(game, current, 7)
        score = marble + remove
        {
          Game.remove(game, remove),
          Map.update(players, rem(marble, num_players), score, &(&1 + score)),
          Game.clockwise(game, remove, 1)
        }
      else
        {
          Game.insert_after(
            game,
            Game.clockwise(game, current, 1),
            marble
          ),
          players,
          marble
        }
      end
    end)
  end
end

IO.puts AoC.Day9.Part2.run 'input.txt'

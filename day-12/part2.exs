defmodule AoC.Day12.Part2 do
  @moduledoc """
  --- Part Two ---
  You realize that 20 generations aren't enough. After all, these plants will
  need to last another 1500 years to even reach your timeline, not to mention
  your future.

  After fifty billion (50000000000) generations, what is the sum of the numbers
  of all pots which contain a plant?
  """

  @generations 50_000_000_000

  def run(filename) do
    [initial, _blank | rules] =
      File.stream!(filename, [encoding: :latin1])
      |> Enum.map(&String.trim_trailing/1)

    # I tried using my "part 1" algorithm, but it ran forever and ever... it
    # also would have taken a lot of memory. So, I switched to a "sparse" data
    # structure: a MapSet that contains the index of every pot with a plant.
    initial =
      String.trim_leading(initial, "initial state: ")
      |> String.to_charlist
      |> Stream.with_index
      |> Stream.filter(fn {p, _i} -> p == ?# end)
      |> Enum.into(MapSet.new, fn {_p, i} -> i end)
    rules =
      Stream.map(rules, &String.split(&1, " => "))
      |> Stream.map(fn [k, <<v>> | _] -> {String.to_charlist(k), v} end)
      |> Stream.filter(fn {_p, result} -> result == ?# end)
      |> Enum.into(MapSet.new, fn {pattern, _r} -> pattern end)

    # For each pot that has a plant, we construct a "key" of nine pots: the pot
    # we're interested in, plus four pots on either side: ie, all positions
    # which include the pot we're interested in for comparison to our rules. To
    # make the computational loop below faster, we pre-compute the result of
    # every possible nine pot key here into a Map. Each key of the Map is the
    # nine pot key and the value is a list of indexes, centered around the pot
    # of interest, that will contain pots in the next generation. In other
    # words, indexes range from -2..2 with 0 being the pot of interest.
    combined_rules =
      Stream.iterate('.........', &iterate_rule/1)
      |> Stream.take_while(&(&1 != '.........#'))
      |> Enum.reduce(%{}, fn keys, acc ->
        Map.put(acc, keys,
          Enum.chunk_every(keys, 5, 1)
          |> Stream.with_index(-2)
          |> Stream.filter(fn {key, _i} -> MapSet.member?(rules, key) end)
          |> Enum.map(fn {_key, i} -> i end)
        )
      end)

    # After all that, it still took forever to run, so I decided to see if
    # there was a pattern. In the Game of Life, a "glider" is a pattern that
    # repeats itself indefinitely. Perhaps something like that is happening
    # here. We can detect a pattern if the difference between generations
    # becomes constant; ie, if generation X has a sum of 100, and X+1 is 110,
    # and X+2 is 120, then each generation is just sliding to the right and we
    # can just calculate the result instead of going through each generation
    #
    # Oddly, with my input, after 120 generations the diff repeats ONCE, but
    # then doesn't converge. Therefore, I needed to wait until 3 diffs in a row
    # matched to find convergence. That happened at 187 generations.
    Enum.reduce_while(1..@generations, {initial, 0, [0]}, fn generation_i, {generation, last_sum, last_diff} ->
      new_generation =
        Enum.reduce(generation, MapSet.new, fn pot, new_generation ->
          MapSet.union(new_generation,
            Enum.map((pot-4)..(pot+4), &(if(MapSet.member?(generation, &1), do: ?#, else: ?.)))
            |> (&(Map.get(combined_rules, &1, []))).()
            |> Enum.into(MapSet.new, &(&1 + pot))
          )
        end)
      this_sum = Enum.sum(new_generation)
      this_diff = this_sum - last_sum
      if Enum.all?(last_diff, &(&1 == this_diff)) do
        {:halt, "Pattern after #{generation_i} generations! diff: #{this_diff}, total: #{this_sum + (@generations - generation_i) * this_diff}"}
      else
        {:cont, {new_generation, this_sum, Enum.take([this_diff | last_diff], 2)}}
      end
    end)
  end

  defp iterate_rule([?. | tl]) do
    [?# | tl]
  end

  defp iterate_rule([?# | tl]) do
    [?. | iterate_rule(tl)]
  end

  defp iterate_rule([]) do
    [?#]
  end
end

IO.puts AoC.Day12.Part2.run "input.txt"

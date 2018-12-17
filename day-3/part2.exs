defmodule AoC.Day3.Part2 do
  @moduledoc """
  --- Part Two ---
  Amidst the chaos, you notice that exactly one claim doesn't overlap by even a
  single square inch of fabric with any other claim. If you can somehow draw
  attention to it, maybe the Elves will be able to make Santa's suit after all!

  For example, in the claims above, only claim 3 is intact after all claims are
  made.

  What is the ID of the only claim that doesn't overlap?
  """

  def run(filename) do
    rgx = ~r{
      # #<id> @ <x>,<y>: <width>x<height>
      \#(?<id>\d+)\s
      @\s(?<x>\d+),(?<y>\d+):\s
      (?<width>\d+)x(?<height>\d+)
    }x
    {candidates, _} =
      File.stream!(filename, [encoding: :latin1])
      |> Stream.map(&(Regex.named_captures(rgx, &1)))
      |> Stream.map(fn m -> for {k, v} <- m, into: %{}, do: {String.to_atom(k), String.to_integer(v)} end)
      |> Enum.reduce({MapSet.new(), :array.new(1_000 * 1_000)}, fn claim, acc ->
        {candidates, fabric, candidate?} =
          Stream.flat_map(claim.y..(claim.y + claim.height - 1), fn j ->
            Stream.map(claim.x..(claim.x + claim.width - 1), &(&1 + j * 1_000))
          end)
          |> Enum.reduce(Tuple.append(acc, true), fn i, {set, fabric, candidate?} ->
            case :array.get(i, fabric) do
              :undefined -> {set, :array.set(i, {:claimed, claim.id}, fabric), candidate?}
              {:claimed, id} -> {MapSet.delete(set, id), :array.set(i, :overlap, fabric), false}
              _ -> {set, fabric, false}
            end
          end)
        {
          if(candidate?, do: MapSet.put(candidates, claim.id), else: candidates),
          fabric
        }
      end)
    List.first MapSet.to_list candidates
  rescue
    e in File.Error -> "Error reading file: #{e.reason}"
  end
end

IO.puts AoC.Day3.Part2.run 'input.txt'

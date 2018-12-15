defmodule AoC.Day2.Part2 do
  @moduledoc """
  Confident that your list of box IDs is complete, you're ready to find the
  boxes full of prototype fabric.

  The boxes will have IDs which differ by exactly one character at the same
  position in both strings. For example, given the following box IDs:

  abcde
  fghij
  klmno
  pqrst
  fguij
  axcye
  wvxyz

  The IDs abcde and axcye are close, but they differ by two characters (the
  second and fourth). However, the IDs fghij and fguij differ by exactly one
  character, the third (h and u). Those must be the correct boxes.

  What letters are common between the two correct box IDs? (In the example
  above, this is found by removing the differing character from either ID,
  producing fgij.)
  """

  def run(filename) do
    File.stream!(filename, [encoding: :latin1])
    |> Stream.map(&String.trim_trailing/1)
    |> Enum.reduce(MapSet.new(), fn box_id, set ->
      Enum.reduce(0..(String.length(box_id) - 1), set, fn i, _ ->
        {prefix, suffix} = String.split_at(box_id, i)
        check = prefix <> String.slice(suffix, 1..-1)
        if MapSet.member?(set, check) do
          throw check
        else
          MapSet.put(set, check)
        end
      end)
    end)
    "No matching box ids."
  rescue
    e in File.Error -> "Error reading file: #{e.reason}"
  catch
    result -> result
  end
end

IO.puts AoC.Day2.Part2.run 'input.txt'

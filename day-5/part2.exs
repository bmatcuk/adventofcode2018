defmodule AoC.Day5.Part1 do
  @moduledoc """
  --- Part Two ---
  Time to improve the polymer.

  One of the unit types is causing problems; it's preventing the polymer from
  collapsing as much as it should. Your goal is to figure out which unit type
  is causing the most problems, remove all instances of it (regardless of
  polarity), fully react the remaining polymer, and measure its length.

  For example, again using the polymer dabAcCaCBAcCcaDA from above:

  - Removing all A/a units produces dbcCCBcCcD. Fully reacting this polymer
    produces dbCBcD, which has length 6.
  - Removing all B/b units produces daAcCaCAcCcaDA. Fully reacting this polymer
    produces daCAcaDA, which has length 8.
  - Removing all C/c units produces dabAaBAaDA. Fully reacting this polymer
    produces daDA, which has length 4.
  - Removing all D/d units produces abAcCaCBAcCcaA. Fully reacting this polymer
    produces abCBAc, which has length 6.

  In this example, removing all C/c units was best, producing the answer 4.

  What is the length of the shortest polymer you can produce by removing all
  units of exactly one type and fully reacting the result?
  """

  def run(filename) do
    File.stream!(filename, [encoding: :latin1], 1)
    |> Stream.reject(&(&1 == "\n"))
    |> Enum.reduce({[], %{}}, &reactions_with_count/2)
    |> stream_without_unit
    |> Enum.reduce([], &reactions/2)
    |> length
  end

  defp stream_without_unit({polymer, cnts}) do
    {unit, _} = Enum.max_by(cnts, fn {_, v} -> v end)
    Stream.reject(polymer, &(String.downcase(&1) == unit))
  end

  defp reactions_with_count(unit, {[], _}) do
    {[unit], %{String.downcase(unit) => 1}}
  end

  defp reactions_with_count(unit, {acc, cnts}) do
    opposite_polarity = if "a" <= unit and unit <= "z", do: String.upcase(unit), else: String.downcase(unit)
    case acc do
      [^opposite_polarity | rest] -> {
          rest,
          Map.update(cnts, String.downcase(unit), 0, &(&1 - 1))
      }
      _ -> {
          [unit | acc],
          Map.update(cnts, String.downcase(unit), 1, &(&1 + 1))
      }
    end
  end

  defp reactions(unit, []) do
    [unit]
  end

  defp reactions(unit, acc) do
    opposite_polarity = if "a" <= unit and unit <= "z", do: String.upcase(unit), else: String.downcase(unit)
    case acc do
      [^opposite_polarity | rest] -> rest
      _ -> [unit | acc]
    end
  end
end

IO.puts AoC.Day5.Part1.run 'input.txt'

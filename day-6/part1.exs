defmodule AoC.Day6.Part1 do
  @moduledoc """
  --- Day 6: Chronal Coordinates ---
  The device on your wrist beeps several times, and once again you feel like
  you're falling.

  "Situation critical," the device announces. "Destination indeterminate.
  Chronal interference detected. Please specify new target coordinates."

  The device then produces a list of coordinates (your puzzle input). Are they
  places it thinks are safe or dangerous? It recommends you check manual page
  729. The Elves did not give you a manual.

  If they're dangerous, maybe you can minimize the danger by finding the
  coordinate that gives the largest distance from the other points.

  Using only the Manhattan distance, determine the area around each coordinate
  by counting the number of integer X,Y locations that are closest to that
  coordinate (and aren't tied in distance to any other coordinate).

  Your goal is to find the size of the largest area that isn't infinite. For
  example, consider the following list of coordinates:

  1, 1
  1, 6
  8, 3
  3, 4
  5, 5
  8, 9

  If we name these coordinates A through F, we can draw them on a grid, putting
  0,0 at the top left:

  ..........
  .A........
  ..........
  ........C.
  ...D......
  .....E....
  .B........
  ..........
  ..........
  ........F.

  This view is partial - the actual grid extends infinitely in all directions.
  Using the Manhattan distance, each location's closest coordinate can be
  determined, shown here in lowercase:

  aaaaa.cccc
  aAaaa.cccc
  aaaddecccc
  aadddeccCc
  ..dDdeeccc
  bb.deEeecc
  bBb.eeee..
  bbb.eeefff
  bbb.eeffff
  bbb.ffffFf

  Locations shown as . are equally far from two or more coordinates, and so
  they don't count as being closest to any.

  In this example, the areas of coordinates A, B, C, and F are infinite - while
  not shown here, their areas extend forever outside the visible grid. However,
  the areas of coordinates D and E are finite: D is closest to 9 locations, and
  E is closest to 17 (both including the coordinate's location itself).
  Therefore, in this example, the size of the largest area is 17.

  What is the size of the largest area that isn't infinite?
  """

  def run(filename) do
    File.stream!(filename, [encoding: :latin1])
    |> Enum.reduce(nil, &prepare_input/2)
    |> find_most_isolated_area
  end

  defp prepare_input(line, acc) do
    [x | [y | _]] =
      String.trim_trailing(line)
      |> String.split(", ")
      |> Stream.take(2)
      |> Enum.map(&String.to_integer/1)
    case acc do
      nil -> {x, y, x, y, [{x, y}]}
      {minx, miny, maxx, maxy, points} ->
        {
          min(x, minx), min(y, miny),
          max(x, maxx), max(y, maxy),
          [{x, y} | points]
        }
    end
  end

  defp find_most_isolated_area({minx, miny, maxx, maxy, points}) do
    width = maxx - minx + 1
    height = maxy - miny + 1
    Stream.with_index(points)
    |> Enum.reduce({:array.new(width * height), %{}}, fn {{x, y}, idx}, acc ->
      Stream.flat_map(miny..maxy, fn j ->
        Stream.map(minx..maxx, fn i ->
          {(j - miny) * width + (i - minx), abs(i - x) + abs(j - y)}
        end)
      end)
      |> Enum.reduce(acc, fn {aryidx, mdist}, {point_map, cnts} ->
        case :array.get(aryidx, point_map) do
          {cidx, cmdist} ->
            cond do
              mdist < cmdist -> {
                  :array.set(aryidx, {idx, mdist}, point_map),
                  Map.update(Map.update(cnts, cidx, 0, &(&1 - 1)), idx, 1, &(&1 + 1))
              }
              mdist == cmdist -> {
                  :array.set(aryidx, {-1, mdist}, point_map),
                  Map.update(cnts, cidx, 0, &(&1 - 1))
              }
              true -> {point_map, cnts}
            end
          _ -> {
              :array.set(aryidx, {idx, mdist}, point_map),
              Map.update(cnts, idx, 1, &(&1 + 1))
          }
        end
      end)
    end)
    |> remove_infinite_areas(width, height)
    |> Map.values
    |> Enum.max
  end

  defp remove_infinite_areas({point_map, cnts}, width, height) do
    Stream.concat([
      0..(width - 1),
      (width * (height - 1))..(width * height - 1),
      Stream.map(1..(height - 2), &(&1 * width)),
      Stream.map(2..(height - 1), &(&1 * width - 1))
    ])
    |> Enum.reduce(cnts, fn aryidx, cnts ->
      Map.delete(cnts, elem(:array.get(aryidx, point_map), 0))
    end)
    |> Map.delete(-1)
  end
end

IO.puts AoC.Day6.Part1.run 'input.txt'

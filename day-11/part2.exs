defmodule AoC.Day11.Part2 do
  @moduledoc """
  --- Part Two ---
  You discover a dial on the side of the device; it seems to let you select a
  square of any size, not just 3x3. Sizes from 1x1 to 300x300 are supported.

  Realizing this, you now must find the square of any size with the largest
  total power. Identify this square by including its size as a third parameter
  after the top-left coordinate: a 9x9 square with a top-left corner of 3,5 is
  identified as 3,5,9.

  For example:

  - For grid serial number 18, the largest total square (with a total power of
    113) is 16x16 and has a top-left corner of 90,269, so its identifier is
    90,269,16.
  - For grid serial number 42, the largest total square (with a total power of
    119) is 12x12 and has a top-left corner of 232,251, so its identifier is
    232,251,12.

  What is the X,Y,size identifier of the square with the largest total power?
  """

  def run(serial_number) do
    rows = Enum.map(1..300, &(build_row(&1, serial_number)))
    Enum.reduce(1..300, {"", 0}, fn size, acc ->
      Stream.map(rows, fn row -> Stream.chunk_every(row, size, 1) |> Enum.map(&Enum.sum/1) end)
      |> Stream.chunk_every(size, 1)
      |> Stream.with_index(1)
      |> Enum.reduce(acc, fn {size_rows, y}, {result, largest} ->
        {sum, maxx} =
          Stream.zip(size_rows)
          |> Stream.map(&Tuple.to_list/1)
          |> Stream.map(&Enum.sum/1)
          |> Stream.with_index(1)
          |> Enum.max_by(&(elem(&1, 0)))
        if sum > largest do
          {"#{maxx},#{y},#{size}", sum}
        else
          {result, largest}
        end
      end)
    end)
    |> elem(0)
  end

  defp build_row(y, serial_number) do
    Enum.map(1..300, fn x ->
      rack_id = x + 10
      power_level = (rack_id * y + serial_number) * rack_id
      rem(div(power_level, 100), 10) - 5
    end)
  end
end

IO.puts AoC.Day11.Part2.run 7347

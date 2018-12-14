defmodule ApplyFreqChanges do
  def read(filename) do
    Stream.cycle(File.stream!(filename, [encoding: :latin1]))
      |> Stream.map(&String.trim_trailing/1)
      |> Enum.reduce({0, MapSet.new()}, &parse_and_check/2)
  rescue
    e in File.Error -> "Error reading file: #{e.reason}"
  catch
    x -> x
  end

  defp parse_and_check(line, tupl) do
    {acc, set} = tupl
    new_acc = parser(line, acc)
    cond do
      MapSet.member?(set, new_acc) -> throw(new_acc)
      true -> {new_acc, MapSet.put(set, new_acc)}
    end
  end

  defp parser(line, acc) do
    case line do
      "+" <> adj -> acc + String.to_integer(adj)
      "-" <> adj -> acc - String.to_integer(adj)
      _ -> acc
    end
  end
end

IO.puts ApplyFreqChanges.read 'input.txt'

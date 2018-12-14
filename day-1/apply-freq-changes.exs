defmodule ApplyFreqChanges do
  def read(filename) do
    File.stream!(filename, [encoding: :latin1])
      |> Stream.map(&String.trim_trailing/1)
      |> Enum.reduce(0, &parser/2)
  rescue
    e in File.Error -> "Error reading file: #{e.reason}"
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

defmodule AoC.Day7.Part1 do
  @moduledoc """
  --- Part Two ---
  As you're about to begin construction, four of the Elves offer to help. "The
  sun will set soon; it'll go faster if we work together." Now, you need to
  account for multiple people working on steps simultaneously. If multiple
  steps are available, workers should still begin them in alphabetical order.

  Each step takes 60 seconds plus an amount corresponding to its letter: A=1,
  B=2, C=3, and so on. So, step A takes 60+1=61 seconds, while step Z takes
  60+26=86 seconds. No time is required between steps.

  To simplify things for the example, however, suppose you only have help from
  one Elf (a total of two workers) and that each step takes 60 fewer seconds
  (so that step A takes 1 second and step Z takes 26 seconds). Then, using the
  same instructions as above, this is how each second would be spent:

  Second   Worker 1   Worker 2   Done
     0        C          .
     1        C          .
     2        C          .
     3        A          F       C
     4        B          F       CA
     5        B          F       CA
     6        D          F       CAB
     7        D          F       CAB
     8        D          F       CAB
     9        D          .       CABF
    10        E          .       CABFD
    11        E          .       CABFD
    12        E          .       CABFD
    13        E          .       CABFD
    14        E          .       CABFD
    15        .          .       CABFDE

  Each row represents one second of time. The Second column identifies how many
  seconds have passed as of the beginning of that second. Each worker column
  shows the step that worker is currently doing (or . if they are idle). The
  Done column shows completed steps.

  Note that the order of the steps has changed; this is because steps now take
  time to finish and multiple workers can begin multiple steps simultaneously.

  In this example, it would take 15 seconds for two workers to complete these
  steps.

  With 5 workers and the 60+ second step durations described above, how long
  will it take to complete all of the steps?
  """

  @input_regex ~r/Step (?<v>\w) must be finished before step (?<w>\w) can begin./

  def run(filename) do
    File.stream!(filename, [encoding: :latin1])
    |> build_graph
    |> find_roots
    |> walk_graph
  end

  defp build_graph(stream) do
    graph = :digraph.new()
    Stream.map(stream, &(Regex.named_captures(@input_regex, &1)))
    |> Enum.each(fn %{"v" => v, "w" => w} ->
      if :digraph.vertex(graph, v) == false, do: :digraph.add_vertex(graph, v)
      if :digraph.vertex(graph, w) == false, do: :digraph.add_vertex(graph, w)
      :digraph.add_edge(graph, v, w)
    end)
    graph
  end

  defp find_roots(graph) do
    {
      graph,
      Enum.reduce(:digraph.vertices(graph), [], fn vertex, acc ->
        if :digraph.in_degree(graph, vertex) == 0 do
          [vertex | acc]
        else
          acc
        end
      end)
      |> Enum.sort
    }
  end

  defp walk_graph({graph, roots}) do
    walk_graph(graph, roots, "", MapSet.new())
  end

  defp walk_graph(_graph, [], result, _visited) do
    result
  end

  defp walk_graph(graph, [vertex | available], result, visited) do
    visited = MapSet.put(visited, vertex)
    available = update_available(available, graph, vertex, visited)
    walk_graph(graph, available, result <> vertex, visited)
  end

  defp update_available(available, graph, from_vertex, visited) do
    Enum.reduce(:digraph.out_neighbours(graph, from_vertex), available, fn vertex, acc ->
      if MapSet.subset?(MapSet.new(:digraph.in_neighbours(graph, vertex)), visited) do
        [vertex | acc]
      else
        acc
      end
    end)
    |> Enum.sort
  end
end

IO.puts AoC.Day7.Part1.run 'input.txt'

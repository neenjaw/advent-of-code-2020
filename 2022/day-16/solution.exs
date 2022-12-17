#! /usr/bin/env elixir

Mix.install([:jason, {:libgraph, "~> 0.16.0"}])

{:ok, ex_contents} = File.read("./2022/day-16/example.txt")
{:ok, input_contents} = File.read("./2022/day-16/input.txt")

defmodule Solution do
  def parse(contents) do
    contents
    |> String.split(~r{\n}, trim: true)
    |> Enum.reduce({Graph.new(), %{}}, &do_parse(&1, &2))
  end

  def do_parse(line, {graph, vertex_metadata}) do
    parser =
      ~r/^Valve ([A-Z]{2}) has flow rate=(\d+); tunnels? leads? to valves? (([A-Z]{2}(, )?)+)$/

    [_, node, flow, connections | _] =
      Regex.scan(parser, line)
      |> hd()

    graph =
      connections
      |> String.split(~r{, }, trim: true)
      |> Enum.reduce(graph, &Graph.add_edge(&2, node, &1, weight: 1))

    vertex_metadata = Map.put(vertex_metadata, node, String.to_integer(flow))

    {graph, vertex_metadata}
  end

  def simulate({graph, vertex_metadata}, time \\ 30) do
    state = %{
      total_time: time,
      time_remaining: time,
      graph: graph,
      vertices: vertex_metadata,
      opened: %{},
      steps_taken: [{:start, "AA", 30}],
      stops: ["AA"]
    }

    do_simulate(state)
  end

  def do_simulate(
        state = %{
          graph: graph,
          vertices: vs,
          opened: open_vs,
          steps_taken: steps = [last_step | _],
          time_remaining: time_remaining
        }
      ) do
    case last_step do
      {:start, current, _} ->
        do_simulate(%{
          state
          | steps_taken: [{:look_for_next, current} | steps]
        })

      {:open, current} ->
        do_simulate(%{
          state
          | steps_taken: [{:look_for_next, current} | steps]
        })

      {:look_for_next, current} ->
        case find_next_moves(graph, current, vs, open_vs, time_remaining) do
          [] ->
            state

          moves ->
            moves
            |> Enum.map(fn {goal, path, cost} ->
              %{
                state
                | time_remaining: time_remaining - cost,
                  steps_taken: [{:move, goal, path, cost, time_remaining - cost} | steps],
                  stops: state.stops ++ [goal]
              }
              |> do_simulate()
            end)
            |> Enum.max_by(&score/1)
        end

      {:move, current, _, _, _} ->
        if not Map.has_key?(open_vs, current) do
          %{
            state
            | time_remaining: time_remaining - 1,
              steps_taken: [{:open, current} | steps],
              opened: Map.put(open_vs, current, time_remaining - 1)
          }
          |> do_simulate()
        end
    end
  end

  def find_next_moves(graph, current, vs, open_vs, time_remaining) do
    visited_vs = Map.keys(open_vs)

    vs
    |> Map.keys()
    |> Enum.filter(&(&1 != current and &1 not in visited_vs and Map.get(vs, &1) > 0))
    |> Enum.map(fn v ->
      [_ | path] = Graph.dijkstra(graph, current, v)
      {v, path, length(path)}
    end)
    |> Enum.filter(fn {_v, _path, cost} -> time_remaining - cost > 0 end)
  end

  def score(vs, open_vs, total_time) do
    open_vs
    |> Enum.reduce(0, fn {v, time_opened}, acc ->
      acc + time_opened * Map.get(vs, v)
    end)
  end

  def score(state) do
    score(state.vertices, state.opened, state.total_time)
  end
end

ex_contents
|> Solution.parse()
|> Solution.simulate()
|> then(fn sol -> {sol.stops, Solution.score(sol)} end)
|> IO.inspect(label: "example part 1")

# VERY SLOW
input_contents
|> Solution.parse()
|> Solution.simulate()
|> then(fn sol -> {sol.stops, Solution.score(sol)} end)
|> IO.inspect(label: "input part 1")

# ex_contents
# |> IO.inspect(label: "example part 2")

# input_contents
# |> IO.inspect(label: "input part 1")

# input_contents
# |> IO.inspect(label: "input part 2")

# AA, DD, BB, JJ, HH, EE, CC

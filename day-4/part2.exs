defmodule AoC.Day4.Part2 do
  @moduledoc """
  --- Part Two ---
  Strategy 2: Of all guards, which guard is most frequently asleep on the same
  minute?

  In the example above, Guard #99 spent minute 45 asleep more than any other
  guard or minute - three times in total. (In all other cases, any guard spent
  any minute asleep at most twice.)

  What is the ID of the guard you chose multiplied by the minute you chose? (In
  the above example, the answer would be 99 * 45 = 4455.)
  """

  @typedoc """
  Each line of data is parsed into a datetime and an action. The action is one
  of:
  - :begins_shift
  - :asleep
  - :awake

  If the action is that a guard begins a new shift, the datum will also contain
  a guard_id.
  """
  @type datum_t :: %{
    datetime: NaiveDateTime.t(),
    action: :begins_shift | :asleep | :awake,
    guard_id: String.t()
  }

  @typedoc "A simple tuple of start and end dates."
  @type daterange_t :: {NaiveDateTime.t(), NaiveDateTime.t()}

  @typedoc """
  For each guard, we store which minute they are asleep the most, the number of
  times they were asleep at that minute, and a map of minute to number of times
  they were asleep that minute.
  """
  @type schedule_t :: {number, number, %{number => number}}

  @typedoc """
  A map of guard_id to their schedule_t
  """
  @type schedules_t :: %{String.t() => schedule_t}

  @typedoc """
  While processing the data, we need to keep track of which guard is currently
  on shift, the datetime of the last event, and a map of guard_id to schedule.
  """
  @type process_state_t :: {String.t(), NaiveDateTime.t(), schedules_t}

  @parse_regex ~r/
    # [YYYY-MM-dd HH:mm] ACTION
    # ACTION is one of:
    #   - Guard #\d+ begins shift
    #   - falls asleep
    #   - wakes up
    \[(?<datetime>\d{4}-\d\d-\d\d\s\d\d:\d\d)\]\s
    (?<action>
      Guard\s\#(?<guard_id>\d+)\sbegins\sshift
      | falls\sasleep
      | wakes\sup
    )
  /x

  def run(filename) do
    File.stream!(filename, [encoding: :latin1])
    |> Enum.sort()
    |> Stream.map(&parse/1)
    |> Enum.reduce({"", ~N[1970-01-01 00:00:00], %{}}, &process_schedules/2)
    |> elem(2)
    |> Enum.max_by(fn {_guard_id, {_min, cnt, _}} -> cnt end)
    |> compute_result
  end

  @spec parse(String.t()) :: datum_t
  defp parse(line) do
    Regex.named_captures(@parse_regex, line)
    |> Enum.into(%{}, fn {k, v} ->
      {
        String.to_atom(k),
        case k do
          "datetime" -> elem(NaiveDateTime.from_iso8601(v <> ":00"), 1)
          "action" ->
            case v do
              "wakes up" -> :awake
              "falls asleep" -> :asleep
              _ -> :begins_shift
            end
          _ -> v
        end
      }
    end)
  end

  @spec process_schedules(datum_t, process_state_t) :: process_state_t
  defp process_schedules(%{action: :begins_shift, guard_id: guard_id, datetime: datetime}, {_, _, schedules}) do
    {guard_id, datetime, schedules}
  end

  defp process_schedules(%{action: :asleep, datetime: datetime}, {guard_id, _, schedules}) do
    {guard_id, datetime, schedules}
  end

  defp process_schedules(%{action: :awake, datetime: datetime}, {guard_id, asleep_at, schedules}) do
    {
      guard_id,
      datetime,
      update_schedules(schedules, guard_id, {asleep_at, datetime})
    }
  end

  @spec update_schedules(schedules_t, String.t(), daterange_t) :: schedules_t
  defp update_schedules(schedules, guard_id, daterange) do
    case schedules do
      %{^guard_id => schedule} ->
        Map.put(schedules, guard_id, update_schedule(schedule, daterange))

      _ ->
        Map.put(schedules, guard_id, update_schedule({nil, 0, %{}}, daterange))
    end
  end

  @spec update_schedule(schedule_t, daterange_t) :: schedule_t
  defp update_schedule(schedule, daterange) do
    Enum.reduce(generate_minutes(daterange), schedule, fn minute, {best, best_cnt, minutes_cnt} ->
      {cnt, new_minutes_cnt} = Map.get_and_update(minutes_cnt, minute, fn current_cnt ->
        new_cnt = if current_cnt == nil, do: 1, else: current_cnt + 1
        {new_cnt, new_cnt}
      end)
      if cnt > best_cnt do
        {minute, cnt, new_minutes_cnt}
      else
        {best, best_cnt, new_minutes_cnt}
      end
    end)
  end

  @spec generate_minutes(daterange_t) :: Enumerable.t()
  defp generate_minutes({d1, d2}) do
    Stream.iterate(d1.minute, &(if(&1 == 59, do: 0, else: &1 + 1)))
    |> Stream.take_while(&(&1 != d2.minute))
  end

  @spec compute_result({String.t(), schedule_t}) :: number
  defp compute_result({guard_id, {minute, _cnt, _cnts}}) do
    String.to_integer(guard_id) * minute
  end
end

IO.puts AoC.Day4.Part2.run 'input.txt'

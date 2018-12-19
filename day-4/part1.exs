defmodule AoC.Day4.Part1 do
  @moduledoc """
  --- Day 4: Repose Record ---
  You've sneaked into another supply closet - this time, it's across from the
  prototype suit manufacturing lab. You need to sneak inside and fix the issues
  with the suit, but there's a guard stationed outside the lab, so this is as
  close as you can safely get.

  As you search the closet for anything that might help, you discover that
  you're not the first person to want to sneak in. Covering the walls, someone
  has spent an hour starting every midnight for the past few months secretly
  observing this guard post! They've been writing down the ID of the one guard
  on duty that night - the Elves seem to have decided that one guard was enough
  for the overnight shift - as well as when they fall asleep or wake up while
  at their post (your puzzle input).

  For example, consider the following records, which have already been
  organized into chronological order:

  [1518-11-01 00:00] Guard #10 begins shift
  [1518-11-01 00:05] falls asleep
  [1518-11-01 00:25] wakes up
  [1518-11-01 00:30] falls asleep
  [1518-11-01 00:55] wakes up
  [1518-11-01 23:58] Guard #99 begins shift
  [1518-11-02 00:40] falls asleep
  [1518-11-02 00:50] wakes up
  [1518-11-03 00:05] Guard #10 begins shift
  [1518-11-03 00:24] falls asleep
  [1518-11-03 00:29] wakes up
  [1518-11-04 00:02] Guard #99 begins shift
  [1518-11-04 00:36] falls asleep
  [1518-11-04 00:46] wakes up
  [1518-11-05 00:03] Guard #99 begins shift
  [1518-11-05 00:45] falls asleep
  [1518-11-05 00:55] wakes up

  Timestamps are written using year-month-day hour:minute format. The guard
  falling asleep or waking up is always the one whose shift most recently
  started. Because all asleep/awake times are during the midnight hour (00:00 -
  00:59), only the minute portion (00 - 59) is relevant for those events.

  Visually, these records show that the guards are asleep at these times:

  Date   ID   Minute
              000000000011111111112222222222333333333344444444445555555555
              012345678901234567890123456789012345678901234567890123456789
  11-01  #10  .....####################.....#########################.....
  11-02  #99  ........................................##########..........
  11-03  #10  ........................#####...............................
  11-04  #99  ....................................##########..............
  11-05  #99  .............................................##########.....

  The columns are Date, which shows the month-day portion of the relevant day;
  ID, which shows the guard on duty that day; and Minute, which shows the
  minutes during which the guard was asleep within the midnight hour. (The
  Minute column's header shows the minute's ten's digit in the first row and
  the one's digit in the second row.) Awake is shown as ., and asleep is shown
  as #.

  Note that guards count as asleep on the minute they fall asleep, and they
  count as awake on the minute they wake up. For example, because Guard #10
  wakes up at 00:25 on 1518-11-01, minute 25 is marked as awake.

  If you can figure out the guard most likely to be asleep at a specific time,
  you might be able to trick that guard into working tonight so you can have
  the best chance of sneaking in. You have two strategies for choosing the best
  guard/minute combination.

  Strategy 1: Find the guard that has the most minutes asleep. What minute does
  that guard spend asleep the most?

  In the example above, Guard #10 spent the most minutes asleep, a total of 50
  minutes (20+25+5), while Guard #99 only slept for a total of 30 minutes
  (10+10+10). Guard #10 was asleep most during minute 24 (on two days, whereas
  any other minute the guard was asleep was only seen on one day).

  While this example listed the entries in chronological order, your entries
  are in the order you found them. You'll need to organize them before they can
  be analyzed.

  What is the ID of the guard you chose multiplied by the minute you chose? (In
  the above example, the answer would be 10 * 24 = 240.)
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
  For each guard, we record the total number of minutes spent sleeping and a
  list of every date range where they are asleep.
  """
  @type schedule_t :: {number, [daterange_t]}

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
    |> Enum.max_by(fn {_guard_id, {total, _}} -> total end)
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
      update_schedule(schedules, guard_id, {asleep_at, datetime})
    }
  end

  @spec update_schedule(schedules_t, String.t(), daterange_t) :: schedules_t
  defp update_schedule(schedules, guard_id, daterange) do
    case schedules do
      %{^guard_id => {total, schedule}} ->
        Map.put(schedules, guard_id, {
          total + compute_minutes(daterange),
          [daterange | schedule]
        })

      _ ->
        Map.put(schedules, guard_id, {compute_minutes(daterange), [daterange]})
    end
  end

  @spec compute_minutes(daterange_t) :: number
  defp compute_minutes({d1, d2}) do
    NaiveDateTime.diff(d2, d1) / 60
  end

  @spec compute_result({String.t(), schedule_t}) :: number
  defp compute_result({guard_id, {_total, schedule}}) do
    String.to_integer(guard_id) * find_best_time(schedule)
  end

  @spec find_best_time([daterange_t]) :: number
  defp find_best_time(schedule) do
    Enum.reduce(schedule, {nil, 0, %{}}, fn daterange, state ->
      Enum.reduce(generate_minutes(daterange), state, fn minute, {best, best_cnt, minutes_cnt} ->
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
    end)
    |> elem(0)
  end

  @spec generate_minutes(daterange_t) :: Enumerable.t()
  defp generate_minutes({d1, d2}) do
    Stream.iterate(d1.minute, &(if(&1 == 59, do: 0, else: &1 + 1)))
    |> Stream.take_while(&(&1 != d2.minute))
  end
end

IO.puts AoC.Day4.Part1.run 'input.txt'

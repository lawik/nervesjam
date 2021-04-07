defmodule Nervespub.Githubber do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(Nervespub.Githubber, nil, name: Nervespub.Githubber)
  end

  @impl GenServer
  def init(_) do
    state = %{
      rate_limit: %{limit: 1, remaining: 1, reset: DateTime.utc_now()},
      requests: [],
      client: Tentacat.Client.new(%{access_token: System.get_env("GITHUB_PERSONAL_TOKEN", nil)})
    }

    Logger.info("Githubber started!")

    {:ok, state}
  end

  def request!(module, function, arguments, callback) do
    GenServer.cast(Nervespub.Githubber, {:action, {module, function, arguments}, callback})
  end

  @impl GenServer
  def handle_cast({:action, mfa, callback}, %{requests: requests} = state) do
    Logger.info("Scheduling GitHub request: #{inspect(mfa)}")
    schedule_run(1)
    {:noreply, %{state | requests: requests ++ [{mfa, callback}]}}
  end

  @impl GenServer
  def handle_info(:run, %{requests: []} = state), do: {:noreply, state}

  @impl GenServer
  def handle_info(:run, %{requests: [{mfa, callback} | tail], rate_limit: rate_limit} = state) do
    Logger.info("Running Github request: #{inspect(mfa)}")
    if rate_limit.remaining > 0 or DateTime.compare(rate_limit.reset, DateTime.utc_now()) == :lt do
      {module, function, arguments} = mfa
      state = case request(module, function, [state.client | arguments]) do
        {:error, :skip} ->
          schedule_run(1)
          %{state | requests: tail}
        {:ok, result, limit} ->
          Logger.info("Processing GitHub response...")
          callback.(result)
          Logger.info("GitHub callback completed.")
          schedule_run(1)
          %{state | rate_limit: limit, requests: tail}
      end

      schedule_run(1)
      {:noreply, state}
    else
      Logger.info("Rate limited")
      diff = DateTime.diff(rate_limit.reset, DateTime.utc_now(), :second)
      diff = if diff > 0, do: diff, else: 1
      schedule_run(diff * 1000)
    end
  end

  defp request(module, function, arguments) do
    {status, result, response} = apply(module, function, arguments)
    case status do
      200 ->
        rate_limits = get_rate_limit(response)
        {:ok, result, rate_limits}
      _ ->
        Logger.error("Received a #{status} status from GitHub")
        Logger.debug("Response: #{inspect(response)}")
        {:error, :skip}
    end
  end

  defp get_rate_limit(response) do
    mapped = response.headers
    |> Enum.filter(& String.starts_with?(elem(&1, 0), "X-RateLimit"))
    |> Enum.into(%{})

    %{
      "X-RateLimit-Limit" => limit,
      "X-RateLimit-Remaining" => remaining,
      "X-RateLimit-Reset" => reset
    } = mapped

    %{
      limit: String.to_integer(limit),
      remaining: String.to_integer(remaining),
      reset: DateTime.from_unix!(String.to_integer(reset))
    }
  end

  defp schedule_run(delay) do
    Process.send_after(self(), :run, delay)
  end
end

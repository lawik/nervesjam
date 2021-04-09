defmodule Nervespub.Scheduler do
  use GenServer

  # 6 hours in ms
  @delay 6 * 3600 * 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    schedule()
    {:ok, nil}
  end

  def handle_info(:run, state) do
    Nervespub.Sourcing.pull_all()
    schedule()
    {:noreply, state}
  end

  def schedule() do
    Process.send_after(self(), :run, @delay)
  end
end

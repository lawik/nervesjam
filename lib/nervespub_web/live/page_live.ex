defmodule NervespubWeb.PageLive do
  use NervespubWeb, :live_view
  use Phoenix.HTML
  import NervespubWeb.ErrorHelpers

  alias Nervespub.Sourcing
  alias Nervespub.Sourcing.Source

  require Logger

  @types ["GitHub Repo": "github-repo", "GitHub Organization": "github-org"]
  @default_period 14 * (3600 * 24)
  @default_unit :second
  @activity_types ["release", "tag"]
  @default_activity_types ["release"]

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Nervespub.PubSub, "sources")
    Phoenix.PubSub.subscribe(Nervespub.PubSub, "updates")
    new_source = Sourcing.change_source(%Source{}, %{})
    starting_dt = DateTime.utc_now() |> DateTime.add(-@default_period, @default_unit)
    sources = Sourcing.list_activity(starting_dt)
    all_sources = Sourcing.list_source()
    activities = Sourcing.list_activity_chronological(starting_dt, @default_activity_types)
    socket = assign(socket,
      starting_dt: starting_dt,
      new_source: new_source,
      sources: sources,
      all_sources: all_sources,
      types: @types,
      activities: activities,
      activity_types: @default_activity_types
    )

    {:ok, socket}
  end

  @impl true
  def handle_info(:pulled, socket) do
    Logger.info("pulled status received, updating state")
    sources = Sourcing.list_activity(socket.assigns.starting_dt)
    all_sources = Sourcing.list_source()
    socket = assign(socket, sources: sources, all_sources: all_sources)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:source_created, _source}, socket) do
    sources = Sourcing.list_activity(socket.assigns.starting_dt)
    all_sources = Sourcing.list_source()
    socket = assign(socket, sources: sources, all_sources: all_sources)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_filter", %{"dt" => dt_iso}, socket) do
    {:ok, dt, _} = DateTime.from_iso8601(dt_iso)
    sources = Sourcing.list_activity(dt)
    socket = assign(socket, starting_dt: dt, sources: sources)
    {:noreply, socket}
  end

  @impl true
  def handle_event("pull_source", %{"id" => id}, socket) do
    id
    |> String.to_integer()
    |> Sourcing.pull_source()

    {:noreply, socket}
  end

  @impl true
  def handle_event("pull_all", _, socket) do
    Sourcing.pull_all()
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_source", %{"source" => args}, socket) do
    socket =
      case Sourcing.create_source(args) do
        {:ok, _source} ->
          new_source = Sourcing.change_source(%Source{}, %{})
          assign(socket, new_source: new_source)

        {:error, changeset} ->
          assign(socket, new_source: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_source", %{"id" => id}, socket) do
    socket = case Sourcing.delete_source(Sourcing.get_source!(id)) do
      {:ok, _} ->
        new_source = Sourcing.change_source(%Source{}, %{})
        sources = Sourcing.list_activity(socket.assigns.starting_dt)
        assign(socket, new_source: new_source, sources: sources)
      {:error, _} -> socket
    end

    {:noreply, socket}
  end
end

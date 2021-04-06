defmodule NervespubWeb.PageLive do
  use NervespubWeb, :live_view
  use Phoenix.HTML
  import NervespubWeb.ErrorHelpers

  alias Nervespub.Sourcing
  alias Nervespub.Sourcing.Source

  @types ["GitHub Repo": "github-repo", "GitHub Organization": "github-org"]

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Nervespub.PubSub, "sources")
    new_source = Sourcing.change_source(%Source{}, %{})
    sources = Sourcing.list_source()
    socket = assign(socket, new_source: new_source, sources: sources, types: @types)
    {:ok, socket}
  end

  @impl true
  def handle_info({:source_created, source}, %{assigns: %{sources: sources}} = socket) do
    socket = socket
    |> assign(sources: [source | sources])

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
        sources = Sourcing.list_source()
        assign(socket, new_source: new_source, sources: sources)
      {:error, _} -> socket
    end

    {:noreply, socket}
  end
end

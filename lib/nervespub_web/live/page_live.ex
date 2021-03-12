defmodule NervespubWeb.PageLive do
  use NervespubWeb, :live_view
  use Phoenix.HTML
  import NervespubWeb.ErrorHelpers

  alias Nervespub.Sourcing
  alias Nervespub.Sourcing.Source

  @types ["GitHub Repo": "github-repo", "GitHub Organization": "github-org"]

  @impl true
  def mount(_params, _session, socket) do
    new_source = Sourcing.change_source(%Source{}, %{})
    sources = Sourcing.list_source()
    socket = assign(socket, new_source: new_source, sources: sources, types: @types)
    {:ok, socket}
  end

  @impl true
  def handle_event("save_source", %{"source" => args}, socket) do
    socket =
      case Sourcing.create_source(args) do
        {:ok, _source} ->
          new_source = Sourcing.change_source(%Source{}, %{})
          sources = Sourcing.list_source()
          assign(socket, new_source: new_source, sources: sources)

        {:error, changeset} ->
          assign(socket, new_source: changeset)
      end

    {:noreply, socket}
  end
end

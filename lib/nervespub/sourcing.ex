defmodule Nervespub.Sourcing do
  @moduledoc """
  The Sourcing context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias Nervespub.Repo

  alias Nervespub.Sourcing.Source
  alias Nervespub.Sourcing.Update

  @default_types ["release", "tag"]

  def list_activity(from_dt, types \\ @default_types) do
    from(s in Source,
      left_join: u in assoc(s, :updates),
      order_by: {:desc, u.occurred_at},
      distinct: true,
      # where: u.occurred_at > ^from_dt and u.type != "commit"
      where: u.occurred_at > ^from_dt and u.type in ^types
    )
    |> Repo.all()
    |> Repo.preload(
      updates: from(u in Update,
        order_by: {:desc, u.occurred_at},
        # where: u.occurred_at > ^from_dt and u.type != "commit"
        where: u.occurred_at > ^from_dt and u.type in ^types
      )
    )
  end

  def pull_all do
    list_source()
    |> Enum.map(&pull_source/1)
  end

  def pull_source(source_id) when is_integer(source_id) do
    source_id
    |> get_source!()
    |> pull_source()
  end

  def pull_source(%{type: "github-repo"} = source) do
    Logger.info("Pulling repo: #{source.name}")
    commit_filters = case get_latest_update(source.id, "commit") do
      nil -> []
      update -> [since: DateTime.to_iso8601(update.occurred_at)]
    end

    [owner, repo_name] = String.split(source.identifier, "/", parts: 2)

    Nervespub.Githubber.request!(Tentacat.Commits, :filter, [owner, repo_name, commit_filters], fn commits ->
      Enum.map(commits, fn commit ->
        {:ok, _} = commit_to_update(source.id, commit)
      end)
      Logger.info("Pulled #{Enum.count(commits)} commits from #{source.name}")

      Nervespub.Githubber.request!(Tentacat.Repositories.Tags, :list, [owner, repo_name], fn tags ->
        Enum.map(tags, fn tag ->
          tag_to_update(source.id, tag)
        end)
        Logger.info("Pulled #{Enum.count(tags)} tags from #{source.name}")


        Nervespub.Githubber.request!(Tentacat.Releases, :list, [owner, repo_name], fn releases ->
          Enum.map(releases, fn release ->
            release_to_update(source.id, release)
          end)

          Logger.info("Pulled #{Enum.count(releases)} releases from #{source.name}")
          Phoenix.PubSub.broadcast!(Nervespub.PubSub, "updates", :pulled)
        end)
      end)
    end)
    # {200, commits, _} = Tentacat.Commits.filter(client, owner, repo_name, commit_filters)
    # {200, tags, _} = Tentacat.Repositories.Tags.list(client, owner, repo_name)
    # {200, releases, _} = Tentacat.Releases.list(client, owner, repo_name)
  end

  def pull_source(%{type: "github-org"} = source) do
    Logger.info("Pulling org: #{source.name}")
    client = Tentacat.Client.new(%{access_token: System.get_env("GITHUB_PERSONAL_TOKEN", nil)})

    {200, repos, _} = Tentacat.Repositories.list_orgs(client, source.identifier)

    repos_known =
      list_source()
      |> Enum.filter(fn source -> source.type == "github-repo" end)
      |> Enum.map(fn source -> source.identifier end)

    new_sources =
      repos
      |> Enum.reject(fn repo -> repo["archived"] or repo["full_name"] in repos_known end)
      |> Enum.map(fn repo ->
        create_source(%{
          identifier: repo["full_name"],
          name: repo["name"],
          type: "github-repo",
          official: source.official,
          url: repo["html_url"]
        })
      end)

    count = Enum.count(new_sources)

    if count > 0 do
      Logger.info("Added #{count} repositories from #{source.type} #{source.name}.")
    else
      Logger.info("No new repositories from #{source.type} #{source.name}.")
    end
    Phoenix.PubSub.broadcast!(Nervespub.PubSub, "sources", :pulled)
  end

  @doc """
  Returns the list of source.

  ## Examples

      iex> list_source()
      [%Source{}, ...]

  """
  def list_source do
    Repo.all(Source)
  end

  @doc """
  Gets a single source.

  Raises `Ecto.NoResultsError` if the Source does not exist.

  ## Examples

      iex> get_source!(123)
      %Source{}

      iex> get_source!(456)
      ** (Ecto.NoResultsError)

  """
  def get_source!(id), do: Repo.get!(Source, id)

  @doc """
  Creates a source.

  ## Examples

      iex> create_source(%{field: value})
      {:ok, %Source{}}

      iex> create_source(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_source(attrs \\ %{}) do
    result = %Source{}
    |> Source.changeset(attrs)
    |> Repo.insert()

    case result do
      {:ok, source} ->
        Phoenix.PubSub.broadcast!(Nervespub.PubSub, "sources", {:source_created, source})
        {:ok, source}
      other -> other
    end
  end

  @doc """
  Updates a source.

  ## Examples

      iex> update_source(source, %{field: new_value})
      {:ok, %Source{}}

      iex> update_source(source, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_source(%Source{} = source, attrs) do
    source
    |> Source.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a source.

  ## Examples

      iex> delete_source(source)
      {:ok, %Source{}}

      iex> delete_source(source)
      {:error, %Ecto.Changeset{}}

  """
  def delete_source(%Source{} = source) do
    Repo.delete(source)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking source changes.

  ## Examples

      iex> change_source(source)
      %Ecto.Changeset{data: %Source{}}

  """
  def change_source(%Source{} = source, attrs \\ %{}) do
    Source.changeset(source, attrs)
  end


  @doc """
  Returns the list of update.

  ## Examples

      iex> list_update()
      [%Update{}, ...]

  """
  def list_update do
    Repo.all(Update)
  end

  @doc """
  Gets a single update.

  Raises `Ecto.NoResultsError` if the Update does not exist.

  ## Examples

      iex> get_update!(123)
      %Update{}

      iex> get_update!(456)
      ** (Ecto.NoResultsError)

  """
  def get_update!(id), do: Repo.get!(Update, id)

  @doc """
  Creates a update.

  ## Examples

      iex> create_update(%{field: value})
      {:ok, %Update{}}

      iex> create_update(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_update(attrs \\ %{}) do
    %Update{}
    |> Update.changeset(attrs)
    |> Repo.insert()
  end

  def commit_to_update(source_id, commit) do
    {:ok, dt, _} = DateTime.from_iso8601(commit["commit"]["committer"]["date"])
    {:ok, _} = store_update(source_id, commit["sha"], %{
      type: "commit",
      url: commit["html_url"] || commit["url"],
      text: commit["commit"]["message"],
      occurred_at: dt
    })
  end

  def tag_to_update(source_id, tag) do
    case Repo.get_by(Update,
      type: "tag",
      source_id: source_id,
      reference: tag["name"]
    ) do
      nil ->
        case Repo.get_by(Update,
          type: "commit",
          source_id: source_id,
          reference: tag["commit"]["sha"]
        ) do
          nil -> {:error, :no_commit_for_tag}
          commit ->
            create_update(%{
              name: tag["name"],
              type: "tag",
              occurred_at: commit.occurred_at,
              reference: tag["name"],
              url: commit.url,
              source_id: source_id
            })
        end
      update -> {:ok, update}
    end
  end

  def release_to_update(source_id, release) do
    {:ok, dt, _} = DateTime.from_iso8601(release["created_at"])
    {:ok, _} = store_update(source_id, release["tag_name"], %{
      name: release["tag_name"],
      type: "release",
      url: release["html_url"] || release["url"],
      text: release["body"],
      occurred_at: dt
    })
  end

  def store_update(source_id, reference, attrs \\ %{}) do
    case Repo.get_by(Update, source_id: source_id, reference: reference) do
      nil ->
        attrs
        |> Map.put(:source_id, source_id)
        |> Map.put(:reference, reference)
        |> create_update
      update -> {:ok, update}
    end
  end

  @doc """
  Updates a update.

  ## Examples

      iex> update_update(update, %{field: new_value})
      {:ok, %Update{}}

      iex> update_update(update, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_update(%Update{} = update, attrs) do
    update
    |> Update.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a update.

  ## Examples

      iex> delete_update(update)
      {:ok, %Update{}}

      iex> delete_update(update)
      {:error, %Ecto.Changeset{}}

  """
  def delete_update(%Update{} = update) do
    Repo.delete(update)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking update changes.

  ## Examples

      iex> change_update(update)
      %Ecto.Changeset{data: %Update{}}

  """
  def change_update(%Update{} = update, attrs \\ %{}) do
    Update.changeset(update, attrs)
  end

  def get_latest_update(source_id, type) do
    from(u in Update,
      where: [type: ^type, source_id: ^source_id],
      limit: 1)
    |> Repo.all()
    |> case do
      [] -> nil
      [update] -> update
    end
  end
end

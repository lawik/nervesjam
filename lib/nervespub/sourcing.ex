defmodule Nervespub.Sourcing do
  @moduledoc """
  The Sourcing context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias Nervespub.Repo

  alias Nervespub.Sourcing.Source

  def pull_source(source_id) when is_integer(source_id) do
    source_id
    |> get_source!()
    |> pull_source()
  end

  def pull_source(%{type: "github-repo"} = source) do
    # TODO: pull latest update to get latest change timestamp
    client = Tentacat.Client.new(%{access_token: System.get_env("GITHUB_PERSONAL_TOKEN", nil)})
    [owner, repo_name] = String.split(source.identifier, "/", parts: 2)

    {200, commits, _} = Tentacat.Commits.list(client, owner, repo_name)
  end

  def pull_source(%{type: "github-org"} = source) do
    client = Tentacat.Client.new(%{access_token: System.get_env("GITHUB_PERSONAL_TOKEN", nil)})

    {200, repos, _} = Tentacat.Repositories.list_orgs(client, source.identifier)

    repos_known =
      list_source()
      |> Enum.filter(fn source -> source.type == "github-repo" end)
      |> Enum.map(fn source -> source["identifier"] end)

    new_sources =
      repos
      |> Enum.reject(fn repo -> repo["archived"] or repo["name"] in repos_known end)
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
    %Source{}
    |> Source.changeset(attrs)
    |> Repo.insert()
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

  alias Nervespub.Sourcing.Update

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
end

defmodule Nervespub.SourcingTest do
  use Nervespub.DataCase

  alias Nervespub.Sourcing

  describe "source" do
    alias Nervespub.Sourcing.Source

    @valid_attrs %{identifier: "some identifier", name: "some name", official: true, type: "some type", url: "some url"}
    @update_attrs %{identifier: "some updated identifier", name: "some updated name", official: false, type: "some updated type", url: "some updated url"}
    @invalid_attrs %{identifier: nil, name: nil, official: nil, type: nil, url: nil}

    def source_fixture(attrs \\ %{}) do
      {:ok, source} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Sourcing.create_source()

      source
    end

    test "list_source/0 returns all source" do
      source = source_fixture()
      assert Sourcing.list_source() == [source]
    end

    test "get_source!/1 returns the source with given id" do
      source = source_fixture()
      assert Sourcing.get_source!(source.id) == source
    end

    test "create_source/1 with valid data creates a source" do
      assert {:ok, %Source{} = source} = Sourcing.create_source(@valid_attrs)
      assert source.identifier == "some identifier"
      assert source.name == "some name"
      assert source.official == true
      assert source.type == "some type"
      assert source.url == "some url"
    end

    test "create_source/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sourcing.create_source(@invalid_attrs)
    end

    test "update_source/2 with valid data updates the source" do
      source = source_fixture()
      assert {:ok, %Source{} = source} = Sourcing.update_source(source, @update_attrs)
      assert source.identifier == "some updated identifier"
      assert source.name == "some updated name"
      assert source.official == false
      assert source.type == "some updated type"
      assert source.url == "some updated url"
    end

    test "update_source/2 with invalid data returns error changeset" do
      source = source_fixture()
      assert {:error, %Ecto.Changeset{}} = Sourcing.update_source(source, @invalid_attrs)
      assert source == Sourcing.get_source!(source.id)
    end

    test "delete_source/1 deletes the source" do
      source = source_fixture()
      assert {:ok, %Source{}} = Sourcing.delete_source(source)
      assert_raise Ecto.NoResultsError, fn -> Sourcing.get_source!(source.id) end
    end

    test "change_source/1 returns a source changeset" do
      source = source_fixture()
      assert %Ecto.Changeset{} = Sourcing.change_source(source)
    end
  end

  describe "update" do
    alias Nervespub.Sourcing.Update

    @valid_attrs %{text: "some text", type: "some type"}
    @update_attrs %{text: "some updated text", type: "some updated type"}
    @invalid_attrs %{text: nil, type: nil}

    def update_fixture(attrs \\ %{}) do
      {:ok, update} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Sourcing.create_update()

      update
    end

    test "list_update/0 returns all update" do
      update = update_fixture()
      assert Sourcing.list_update() == [update]
    end

    test "get_update!/1 returns the update with given id" do
      update = update_fixture()
      assert Sourcing.get_update!(update.id) == update
    end

    test "create_update/1 with valid data creates a update" do
      assert {:ok, %Update{} = update} = Sourcing.create_update(@valid_attrs)
      assert update.text == "some text"
      assert update.type == "some type"
    end

    test "create_update/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sourcing.create_update(@invalid_attrs)
    end

    test "update_update/2 with valid data updates the update" do
      update = update_fixture()
      assert {:ok, %Update{} = update} = Sourcing.update_update(update, @update_attrs)
      assert update.text == "some updated text"
      assert update.type == "some updated type"
    end

    test "update_update/2 with invalid data returns error changeset" do
      update = update_fixture()
      assert {:error, %Ecto.Changeset{}} = Sourcing.update_update(update, @invalid_attrs)
      assert update == Sourcing.get_update!(update.id)
    end

    test "delete_update/1 deletes the update" do
      update = update_fixture()
      assert {:ok, %Update{}} = Sourcing.delete_update(update)
      assert_raise Ecto.NoResultsError, fn -> Sourcing.get_update!(update.id) end
    end

    test "change_update/1 returns a update changeset" do
      update = update_fixture()
      assert %Ecto.Changeset{} = Sourcing.change_update(update)
    end
  end
end

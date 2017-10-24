defmodule IndexComparison do
  @id_field_name "_id"
  @type_field_name "_type"
  @source_field_name "_source"

  @moduledoc """
  The main module that is the entrypoint for the CLI app.
  It parses options, parses 2 files, compares them, produces a report
  and format it somehow based on the `formatter` parameter
  """

  alias Inconsistency.{DifferentValues, DifferentKeys, MissingDocument}
  alias Poison.Parser

  @spec main(list(String.t)) :: no_return
  def main(args) do
    case ArgsParser.parse(args) do
      {:error, message} ->
        IO.puts(message)
      {:ok, options} ->
        options |> Options.inspect_fields |> IO.puts

        old_index = load_dump(options.old_dump_path, options)
        new_index = load_dump(options.new_dump_path, options)

        old_index
        |> compare(new_index, options)
        |> options.formatter.format
    end
  end

  @spec load_dump(String.t, Options.t) :: map
  def load_dump(path, options) do
    path
    |> File.open!
    |> IO.stream(:line)
    |> Stream.map(&parse_dump_entry(&1, options))
    |> Enum.into(%{})
  end

  @spec parse_dump_entry(String.t, Options.t) :: {String.t, map}
  def parse_dump_entry(entry, options) do
    json = Parser.parse!(entry)
    # TODO: make it a CLI parameter
    id = json[@id_field_name]
    type_name = json[@type_field_name]
    unique_id = type_name <> "#" <> id

    {
      unique_id,
      json
      |> Map.fetch!(@source_field_name)
      |> filter_fields(options)
    }
  end

  @spec filter_fields(map, Options.t) :: map
  def filter_fields(document, options) do
    case options.type_of_checking do
      :all -> document
      # TODO: make it work for nested objects
      :only -> Map.take(document, [:id | options.field_names])
      :except -> Map.drop(document, options.field_names)
    end
  end

  @spec compare(map, map, Options.t) :: list(Inconsistency.t)
  def compare(old_index, new_index, options) do
    {old, new, missing_inconsistencies} = filter_missing_documents(old_index, new_index)
    document_inconsistencies = check_documents(old, new, options)
    missing_inconsistencies ++ document_inconsistencies
  end

  @spec filter_missing_documents(map, map) :: {map, map, list(Inconsistency.t)}
  def filter_missing_documents(index, another_index) do
    {filtered_index, inconsistencies} = filter_missing_documents(index, another_index, [], :new)

    {another_filtered_index, all_inconsistencies} =
      filter_missing_documents(another_index, filtered_index, inconsistencies, :old)

    {filtered_index, another_filtered_index, all_inconsistencies}
  end

  @spec filter_missing_documents(map, map, list(Inconsistency.t), MissingDocument.where) :: {map, list(Inconsistency.t)}
  def filter_missing_documents(index, another_index, inconsistencies, where) do
    ids = index |> Map.keys |> MapSet.new
    another_ids = another_index |> Map.keys |> MapSet.new
    diff = MapSet.difference(ids, another_ids)
    new_index = Map.drop(index, diff)
    new_inconsistencies = Enum.map(diff, fn id -> %MissingDocument{id: id, where: where} end)
    {new_index, new_inconsistencies ++ inconsistencies}
  end

  @spec check_documents(map, map, Options.t) :: list(Inconsistency.t)
  def check_documents(dump, another_dump, _options) do
    Enum.reduce(dump, [], fn ({id, document}, inconsistencies) ->
      another_document = another_dump[id]

      # If the keys are different we skip checking the values
      # TODO: add CLI flag to use stricter behaviour
      case check_keys(id, document, another_document) do
        :ok -> check_document_values(id, document, another_document) ++ inconsistencies
        key_inconsistency -> [key_inconsistency | inconsistencies]
      end
    end)
  end

  @spec check_keys(String.t, map, map) :: :ok | Inconsistency.t
  def check_keys(id, document, another_document) do
    keys = document |> Map.keys |> Enum.sort
    another_keys = another_document |> Map.keys |> Enum.sort

    if keys == another_keys do
      :ok
    else
      %DifferentKeys{id: id, keys: keys, another_keys: another_keys}
    end
  end

  @spec check_document_values(String.t, map, map) :: [Inconsistency.t]
  def check_document_values(id, document, another_document) do
    Enum.reduce(document, [], fn ({key, value}, inconsistencies) ->
      another_value = another_document[key]

      # TODO: add check for lists. if their sort is only different then it should be another inconsistency type
      if another_value != value do
        [%DifferentValues{id: id, key: key, value: value, another_value: another_value} | inconsistencies]
      else
        inconsistencies
      end
    end)
  end
end

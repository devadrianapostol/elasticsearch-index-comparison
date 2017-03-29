defmodule IndexComparison do
  @necessary_arguments [:old_dump, :new_dump]
  @id_field "_id"
  @type_field "_type"

  def main(args) do
    options = parse_args(args)

    check_only = if options[:check_only] do
      String.split(options[:check_only], ",")
    else
      []
    end
    # timeout = if options[:timeout] do
    #   String.to_integer(options[:timeout])
    # else
    #   30_000
    # end

    unless Enum.empty?(check_only) do
      IO.puts "Checking only these fields: #{Enum.join(check_only, ", ")}"
    end

    new_index = index(options[:new_dump], check_only)
    old_index = index(options[:old_dump], check_only)

    compare(old_index, new_index, check_only)
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args)
    if Enum.all?(@necessary_arguments, fn arg -> arg in Keyword.keys(options) end) do
      options
    else
      IO.puts "You must provide --old-dump and --new-dump parameters"
      System.halt(1)
    end
  end

  defp index(file_name, check_only) do
    file = file(file_name)

    IO.stream(file, :line)
    |> Stream.map(fn document ->
      json = Poison.Parser.parse!(document)

      id = json[@id_field]
      type = json[@type_field]
      source = Map.put(json["_source"], @id_field, "#{type}_#{id}")

      if Enum.empty?(check_only) do
        source
      else
        Map.take(source, Enum.uniq([@id_field | check_only]))
      end
    end)
  end

  defp file(file_name) when is_nil(file_name) do
    IO.puts("Wrong filename! #{file_name}")
    System.halt(1)
  end

  defp file(file_name) do
    case File.open(file_name, [:read]) do
      {:ok, file} -> file
      _ ->
        IO.puts("Cannot open file #{file_name}")
        System.halt(1)
    end
  end

  defp compare(old_index, new_index, check_only) do
    new_index_map = Stream.map(new_index, fn(obj) ->
      {obj[@id_field], obj}
    end) |> Map.new

    result = Stream.map(old_index, fn(old) ->
      new = new_index_map[old[@id_field]]
      message = cond do
        !new ->
          "Document #{old[@id_field]} is absent in new dump"
        old != new ->
          entry_diff(old, new)
        true ->
          nil
      end
      {old[@id_field], message}
    end) |> Map.new

    old_ids = Map.keys(result)
    new_excess = Map.drop(new_index_map, old_ids)

    if Enum.count(new_excess) > 0 do
      IO.puts("New idex contains #{Enum.count(new_excess)} excess entries: #{Map.keys(new_excess) |> Enum.join(", ")}")
    end

    errors = Map.values(result) |> List.flatten  |> Enum.reject(&is_nil/1)

    if Enum.empty?(errors) do
      IO.puts("#{Enum.count(new_index_map)} documents were checked for equality. All good!")
    else
      Enum.each(errors, &IO.puts/1)
    end
  end

  defp entry_diff(source1, source2) do
    id = Map.get(source1, @id_field)
    keys = Map.keys(source1)
    Enum.map(keys, fn key ->
      el1 = Map.get(source1, key)
      el2 = Map.get(source2, key)
      if el1 != el2 do
        if is_list(el1) && Enum.sort(el1) == Enum.sort(el2) do
          "'#{key}' is equal only when sorted!"
        else
          "--------------\n'#{key}' key is not equal for document: #{id}\n------OLD------" <>
          "#{inspect(el1)}\n------NEW------\n#{inspect(el2)}"
        end
      end
    end)
  end
end

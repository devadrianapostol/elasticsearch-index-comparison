defmodule IndexComparison do
  @necessary_arguments [:old_dump, :new_dump]
  @id_field "_id"

  def main(args) do
    options = parse_args(args)

    check_only = if options[:check_only] do
      String.split(options[:check_only], ",")
    else
      []
    end
    timeout = if options[:timeout] do
      String.to_integer(options[:timeout])
    else
      30_000
    end

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
    file_name
    |> file
    |> IO.stream(:line)
    |> Stream.map(fn document ->
      json = Poison.Parser.parse!(document)

      id = json[@id_field]
      source =
        json["_source"]
        |> Map.put(@id_field, id)
        |> Map.put("type", json["_type"])

      if Enum.empty?(check_only) do
        source
      else
        Map.take(source, Enum.uniq([@id_field | check_only]))
      end
    end)
    |> Enum.sort_by(fn x -> "#{x["type"]}#{x[@id_field]}" end)
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

  defp compare(index1, index2, check_only) do
    results =
      Stream.zip(index1, index2)
      |> Enum.map(fn {o, n} ->
        if o != n do
          if o[@id_field] != n[@id_field] do
            IO.puts("Document #{o[@id_field]} is absent in new dump or ordering is different")
            System.halt(1)
          else
            show_diff(o, n)
          end
        end
      end)

    errors = results |> List.flatten |> Enum.filter(&!is_nil(&1))

    if Enum.empty?(errors) do
      IO.puts "#{length(results)} documents were checked for equality. All good!"
    else
      Enum.each(errors, &IO.puts/1)
    end
  end

  defp show_diff(source1, source2) do
    keys = Map.keys(source1)
    Enum.map(keys, fn key ->
      el1 = Map.get(source1, key)
      el2 = Map.get(source2, key)
      if el1 != el2 do
        if is_list(el1) && Enum.sort(el1) == Enum.sort(el2) do
          "'#{key}' is equal only when sorted!"
        else
          id = source1[@id_field]
          type = source1["type"]
          "--------------\n'#{key}' key is not equal for document: #{type}##{id}\n------OLD------" <>
          "#{inspect(el1)}\n------NEW------\n#{inspect(el2)}\n"
        end
      end
    end)
  end
end

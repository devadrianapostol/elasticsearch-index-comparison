defmodule IndexComparison do
  @necessary_arguments [:old_dump, :new_dump]

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

    old_index_pid = index(options[:old_dump], check_only)
    new_index = Task.await(index(options[:new_dump], check_only), timeout)

    compare(Task.await(old_index_pid, timeout), new_index, check_only)
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

    Task.async(fn ->
      IO.stream(file, :line)
       |> Enum.reduce(%{}, fn el, acc ->
        {:ok, json} = Poison.Parser.parse(el)
        filtered_json = json |> Map.get("_source")
        filtered_json = if Enum.empty?(check_only) do
            filtered_json
          else
            filtered_json |> Map.take(check_only)
          end
        record_id = json |> Map.get("_id")
        record_type = json |> Map.get("_type")
        Map.put(acc, record_type <> "#" <> record_id, filtered_json)
      end)
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

  defp compare(index1, index2, check_only) do
    if index1 == index2 do
      IO.puts "#{length(Map.keys(index1))} documents were checked for equality. All good!"
      true
    else
      if Map.keys(index1) |> Enum.sort != Map.keys(index2) |> Enum.sort && Enum.empty?(check_only)  do
        IO.puts "keys are not equal"
        show_not_equal_keys(index1, index2)
      else
        IO.puts "keys are equal, but documents are not"
        Map.keys(index1) |> Enum.each(fn el ->
          show_diff(Map.get(index1, el), Map.get(index2, el), el)
        end)
      end
      false
    end
  end

  defp show_not_equal_keys(origin, changed) do
    differences = changed |> Enum.filter(fn el -> !Enum.member?(origin, el) end)
    IO.inspect length(differences)
    IO.inspect Enum.at(origin, 0)
    IO.inspect differences
  end

  defp show_diff(source1, source2, id) do
    keys = Map.keys(source1)
    Enum.each(keys, fn key ->
      el1 = Map.get(source1, key)
      el2 = Map.get(source2, key)
      if el1 != el2 do
        if is_list(el1) && Enum.sort(el1) == Enum.sort(el2) do
          IO.puts "'#{key}' is equal only when sorted!\n"
        else
          IO.puts "--------------\n'#{key}' key is not equal for document: #{id}\n------OLD------"
          IO.inspect el1
          IO.puts "------NEW------"
          IO.inspect el2
        end
      end
    end)
  end
end

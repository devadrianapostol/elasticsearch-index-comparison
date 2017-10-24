defmodule Formatter.CLI do
  alias Inconsistency.{DifferentValues, DifferentKeys, MissingDocument}

  @moduledoc """
  This formatter simply writes the report to STDOUT.
  """

  @behaviour Formatter

  @spec format(list(Inconsistency.t)) :: any
  def format([]), do: IO.puts("Documents are consistent")
  def format(inconsistencies) do
    Enum.each(inconsistencies, fn i -> i |> format_inconsistency |> IO.puts end)
  end

  # TODO: use ExUnit differ
  @spec format_inconsistency(Inconsistency.t) :: String.t
  def format_inconsistency(inconsistency) do
    case inconsistency do
      %DifferentValues{id: id, key: key, value: value, another_value: another_value} ->
        "Document #{id} is inconsistent between indices on field: #{key}\n" <>
          "In old: #{inspect value}" <> "\nIn new: #{inspect another_value}\n"

      %DifferentKeys{id: id, keys: keys, another_keys: another_keys} ->
        "Keys for document #{id} are inconsistent between indices\n" <>
          "In old: #{inspect keys}" <> "\nIn new: #{inspect another_keys}\n"

      %MissingDocument{id: id, where: where} ->
        "Document #{id} is missing in #{where} index"
    end
  end
end

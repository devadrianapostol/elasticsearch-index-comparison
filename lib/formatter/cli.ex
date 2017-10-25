defmodule Formatter.CLI do
  alias Inconsistency.{DifferentValues, DifferentKeys, MissingDocument, DifferentOrder}

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
          "In old: #{inspect value}\n" <> "In new: #{inspect another_value}\n"

      %DifferentKeys{id: id, keys: keys, another_keys: another_keys} ->
        "Keys for document #{id} are inconsistent between indices\n" <>
          "In old: #{inspect keys}\n" <> "In new: #{inspect another_keys}\n"

      %DifferentOrder{id: id, key: key, values: values, another_values: another_values} ->
        "Values in document #{id} under key #{key} are the same but have different order\n" <>
          "In old: #{inspect values}\n" <> "In new: #{inspect another_values}\n"

      %MissingDocument{id: id, where: where} ->
        "Document #{id} is missing in #{where} index"
    end
  end
end

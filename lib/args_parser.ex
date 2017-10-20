defmodule ArgsParser do
  @necessary_arguments [:old_dump, :new_dump]

  @moduledoc """
  This module parses passed CLI options

  Available options:
    * `old_dump` - path to the old dump file. required
    * `new_dump` - path to the new dump file. required
    * `formatter` - the type of formatter of the results. at the moment only `cli` is avaliable
    * `only_fields` - comma separated field names that will be checked. by default the script checks all fields
    * `except_fields` - comma separated field names that won't be checked. cannot be used with `only_fields`

  """

  @spec parse(list(String.t)) :: {:ok, Options.t} | {:error, String.t}
  def parse(args) do
    {raw_options, _, _} = OptionParser.parse(args)

    if required_options_present?(raw_options) do
      {:ok, parse_raw_options(raw_options)}
    else
      {:error, "You must provide --old-dump and --new-dump parameters"}
    end
  end

  @spec parse_raw_options(Keyword.t) :: Options.t
  def parse_raw_options(raw_options) do
    %Options{old_dump_path: raw_options[:old_dump],
             new_dump_path: raw_options[:new_dump]}
    |> assign_formatter(raw_options)
    |> assign_fields(raw_options)
  end

  @spec required_options_present?(Keyword.t) :: boolean
  defp required_options_present?(options) do
    Enum.all?(@necessary_arguments, & Keyword.has_key?(options, &1))
  end

  @spec assign_fields(Options.t, Keyword.t) :: Options.t
  defp assign_fields(options, raw_options) do
    cond do
      Keyword.has_key?(raw_options, :only_fields) ->
        %{options | type_of_checking: :only,
                    field_names: String.split(raw_options[:only_fields], ",")}
      Keyword.has_key?(raw_options, :except_fields) ->
        %{options | type_of_checking: :except,
                    field_names: String.split(raw_options[:except_fields], ",")}
      true -> options
    end
  end
end

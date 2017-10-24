defmodule Options do
  defstruct old_dump_path: nil, new_dump_path: nil, field_names: [],
            type_of_checking: :all, formatter: Formatter.CLI

  @type t :: %__MODULE__{old_dump_path: String.t, new_dump_path: String.t,
                         type_of_checking: :only | :except | :all,
                         field_names: list(String.t), formatter: Formatter.t}

  @moduledoc """
  Options module defines the Options struct with all available CLI options
  """

  @spec inspect_fields(t) :: String.t
  def inspect_fields(options) do
    case options.type_of_checking do
      :all -> "Checking all fields"
      :only -> "Checking only " <> Enum.join(options.field_names, ", ")
      :except -> "Checking all fields except " <> Enum.join(options.field_names, ", ")
    end
  end
end

defmodule Inconsistency do
  @type t :: Inconsistency.DifferentValues.t
             | Inconsistency.DifferentKeys.t
             | Inconsistency.MissingDocument.t

  defmodule DifferentValues do
    defstruct [:id, :key, :value, :another_value]
    @type t :: %__MODULE__{id: String.t, key: String.t,
                           value: any, another_value: any}
  end

  defmodule DifferentKeys do
    defstruct [:id, :keys, :another_keys]
    @type t :: %__MODULE__{id: String.t, keys: list(String.t),
                           another_keys: list(String.t)}
  end

  defmodule MissingDocument do
    defstruct [:id, :where]
    @type where :: :old | :new
    @type t :: %__MODULE__{id: String.t, where: where}
  end
end

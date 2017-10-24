defmodule Inconsistency do
  @type t :: Inconsistency.DifferentValues.t
             | Inconsistency.DifferentKeys.t
             | Inconsistency.MissingDocument.t

  @moduledoc """
  This module defines all types of possible issues
  """

  defmodule DifferentValues do
    defstruct [:id, :key, :value, :another_value]
    @type t :: %__MODULE__{id: String.t, key: String.t,
                           value: any, another_value: any}

    @moduledoc """
    The simplest case. When we compare 2 documents and
    values under the same keys are different we use this struct
    """
  end

  defmodule DifferentKeys do
    defstruct [:id, :keys, :another_keys]
    @type t :: %__MODULE__{id: String.t, keys: list(String.t),
                           another_keys: list(String.t)}

    @moduledoc """
    This struct is used for the case when
    we have 2 documents with different set of keys
    """
  end

  defmodule MissingDocument do
    defstruct [:id, :where]
    @type where :: :old | :new
    @type t :: %__MODULE__{id: String.t, where: where}

    @moduledoc """
    This struct is needed for the case when
    some document is missing in either of index dumps
    """
  end
end

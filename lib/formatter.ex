defmodule Formatter do
  @type t :: Formatter.CLI

  @moduledoc """
  This module provides an interface of formatting reports
  """

  @callback format(list(Inconsistency.t)) :: any
end

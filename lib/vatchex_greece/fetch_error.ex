defmodule VatchexGreece.FetchError do
  @moduledoc """
  Exception raised when a fetch operation fails.
  """
  defexception [:message, :errors]

  @impl true
  def exception(errors) do
    %__MODULE__{
      message: "Errors during fetch operation: #{inspect(errors)}",
      errors: errors
    }
  end
end

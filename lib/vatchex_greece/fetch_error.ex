defmodule VatchexGreece.FetchError do
  @moduledoc """
  Exception raised by `fetch!/1` when the fetch operation fails.

  ## Fields

  - `:message` — human-readable error summary
  - `:errors` — the error map from the pipeline (validation, HTTP, or service errors)
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

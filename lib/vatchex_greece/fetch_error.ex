defmodule VatchexGreece.FetchError do
  @moduledoc """
  Exception raised by `fetch!/1` when the fetch operation fails.

  ## Fields

  - `:message` — human-readable error summary
  - `:errors` — the error map from the pipeline (validity checks, HTTP errors, service errors)
  """

  defexception [:message, :errors]

  @impl true
  @doc """
  Builds a `FetchError` from an errors map.

  The errors map may contain:
  - `:validity_source` — source VAT ID failed checksum/length check
  - `:validity_target` — target VAT ID failed checksum/length check
  - `:http_not_ok` — non-200 HTTP response
  - `:service_error` — GSIS service returned an `error_rec`
  """
  def exception(errors) do
    %__MODULE__{
      message: "Errors during fetch operation: #{inspect(errors)}",
      errors: errors
    }
  end
end

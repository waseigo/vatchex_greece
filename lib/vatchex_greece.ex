defmodule VatchexGreece do
  require EEx

  @moduledoc """
  Documentation for `VatchexGreece`.
  """
  @moduledoc since: "0.1.0"

  alias VatchexGreece.{Request, Process, Fixes, Validate}

  @doc """
  Pull information from the web service. Note: the function sanitizes the
  requested VAT ID using `VatchexGreece.Validate.minimize()`, checks it
  using `VatchexGreece.Validate.is_valid?()` and only sends the request
  to the API if the `minimize`d VAT ID is valid.

  ## Examples

  Typically, you will pass a valid 9-digit VAT ID, with or without the "EL" prefix:
  ```
  get("123456783") # valid (dummy) 9-digit VAT ID
  get("EL123456783") # ditto, with "EL" prefix that will get stripped
  ```

  Older VAT IDs only have 8 digits, and will get leading-zero-padded to 9 digits:
  ```
  get("11111067") # valid (dummy) 8-digit VAT ID
  ```

  """
  def get(afmCalledFor) do
    vat_id = Validate.minimize(afmCalledFor)

    if Validate.is_valid?(vat_id) do
      vat_id
      |> Request.prepare()
      |> Request.post()
      |> Process.from_request()
      |> Process.to_map()
      |> Fixes.apply_all()
    else
      {:error, "VAT ID is not valid"}
    end
  end
end

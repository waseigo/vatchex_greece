# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece do
  require EEx

  @moduledoc """
  Main module of `VatchexGreece` that contains high-level functions that the
  user typically will interact with.
  """
  @moduledoc since: "0.1.0"

  alias VatchexGreece.{Request, Process, Fixes, Validate}

  @doc """
  Pull information from the web service for the target VAT ID `afm_called_for`.
  Note: the function minimizes and checks the source and target VAT IDs, and only
  sends the request to the API if both  minimized VAT IDs are valid.

  You need to pass authentication parameters `username`, `password` and the
  source VAT ID `afm_called_by` as parameters.

  ## Examples

  Typically, you will pass a valid 9-digit VAT ID, with or without the "EL" prefix:
  ```
  get("123456783", ...) # valid (dummy) 9-digit VAT ID
  get("EL123456783", ...) # ditto, with "EL" prefix that will get stripped
  ```

  Older VAT IDs only have 8 digits, and will get leading-zero-padded to 9 digits:
  ```
  get("11111067", ...) # valid (dummy) 8-digit VAT ID
  ```

  """
  def get(afm_called_for, username, password, afm_called_by) do
    afm_called_for = Validate.minimize(afm_called_for)
    afm_called_by = Validate.minimize(afm_called_by)

    vat_validity =
      Enum.map([afm_called_by, afm_called_for], &Validate.valid?(&1))

    case vat_validity do
      [false, false] ->
        {:error,
         "Neither the source VAT ID #{afm_called_by} nor the target VAT ID #{afm_called_for} is valid."}

      [false, true] ->
        {:error, "Source VAT ID #{afm_called_by} is not valid"}

      [true, false] ->
        {:error, "Target VAT ID #{afm_called_for} is not valid"}

      _ ->
        afm_called_for
        |> Request.prepare(username, password, afm_called_by)
        |> Request.post()
        |> Process.from_request()
        |> Process.to_map()
        |> Fixes.apply_all()
    end
  end

  @doc """
  Unsafe version of get/4.
  """
  def get!(afm_called_for, username, password, afm_called_by) do
    case get(afm_called_for, username, password, afm_called_by) do
      {:ok, vat_id} -> vat_id
      {:error, message} -> raise RuntimeError, message: message
    end
  end

  @doc """
  Arity-2 version of get/4 that takes a keyword list or map as the second parameter.
  """
  def get(afm_called_for, auth_settings) do
    auth_settings = Map.new(auth_settings)
    username = auth_settings[:username]
    password = auth_settings[:password]
    afm_called_by = auth_settings[:afmcalledby]

    get(afm_called_for, username, password, afm_called_by)
  end

  @doc """
  Unsafe version of get/2.
  """
  def get!(afm_called_for, auth_settings) do
    case get(afm_called_for, auth_settings) do
      {:ok, vat_id} -> vat_id
      {:error, message} -> raise RuntimeError, message: message
    end
  end
end

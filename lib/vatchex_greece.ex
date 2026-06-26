# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece do
  @moduledoc """
  Client for the Greek GSIS RgWsPublic2 SOAP service (VAT / ΑΦΜ registry lookup).

  ## Public API

  ```elixir
  VatchexGreece.fetch(
    afm_called_for: "the_target_afm_to_query",
    username: "your_token_username",
    password: "your_special_access_code",
    afm_called_by: "your_own_afm_or_delegator"
  )
  ```

  See `fetch/1` for authentication instructions, automatic normalization of
  VAT IDs (EL/GR prefix handling, 8→9 digit padding), and the exact shape
  of the returned data map.

  The implementation is internal; only `fetch/1` and `fetch!/1` are the
  supported public API.
  """
  @moduledoc since: "0.1.0"

  alias VatchexGreece.{
    Request,
    Processing,
    Validate,
    APIauth,
    GSISdata,
    Results,
    FetchError
  }

  @doc """
  Pull information from the web service for the target VAT ID `:afm_called_for`, by the source VAT ID `:afm_called_by`, with authentication parameters `:username` and `:password`.

  To create the authentication credentials:
  1. Sign up to the ["wspublicreg" service](https://www1.aade.gr/webtax/wspublicreg/faces/pages/wspublicreg/menu.xhtml) using your TAXISnet credentials.
  2. Create "special access codes" through the ["Διαχείριση Ειδικών Κωδικών" application on TAXISnet](https://www1.aade.gr/sgsisapps/tokenservices/protected/displayConsole.htm).

  Regarding the target and source VAT IDs, you will typically pass a valid 9-digit VAT ID, with or without the "EL" prefix. The "EL" prefix will get stripped. Older VAT IDs only have 8 digits, and will get leading-zero-padded to 9 digits.

  Note: the function minimizes and checks the source and target VAT IDs, and only sends the request to the API if both minimized VAT IDs are valid.

  ## Caching

  Pass a `:cache` option to enable caching. The value must implement the `VatchexGreece.Cache` protocol.

  ```elixir
  VatchexGreece.fetch(
    afm_called_for: "998144460",
    username: "user",
    password: "pass",
    afm_called_by: "123456789",
    cache: VatchexGreece.CachexCache
  )
  ```

  Successful results are cached; errors are never cached. When no `:cache` option is provided, caching is disabled.

  ## VIES fallback

  If the `fetch_vies_fallback: true` option is passed and the GSIS lookup fails,
  an additional lookup against the EU VIES API is attempted (requires the
  `vatchex_vies` package).

  ```elixir
  VatchexGreece.fetch(
    afm_called_for: "998144460",
    username: "user",
    password: "pass",
    afm_called_by: "123456789",
    fetch_vies_fallback: true
  )
  ```

  When the VIES fallback succeeds, the response map includes `source: :vies`
  (instead of the full GSIS data structure).
  """
  @doc since: "0.8.0"
  def fetch(opts) do
    cache = Keyword.get(opts, :cache, nil)
    vies_fallback? = Keyword.get(opts, :fetch_vies_fallback, false)

    case do_fetch(opts, cache) do
      {:ok, data} = result ->
        maybe_cache(cache, cache_key(opts), data)
        result

      {:error, errors} ->
        if vies_fallback?,
          do: vies_fallback(errors, opts),
          else: {:error, errors}
    end
  end

  @doc """
  Same as `VatchexGreece.fetch/1`, but the resulting tuple is unwrapped.

  Returns the resulting data if successful. Raises `VatchexGreece.FetchError` if there were errors, containing the errors list in the `errors` field of the exception.
  """
  @doc since: "0.8.0"
  def fetch!(opts) do
    case fetch(opts) do
      {:ok, data} ->
        data

      {:error, errors} ->
        raise FetchError, errors
    end
  end

  # --- Caching ---

  defp do_fetch(opts, cache) do
    afm_called_for = Keyword.get(opts, :afm_called_for)
    username = Keyword.get(opts, :username)
    password = Keyword.get(opts, :password)
    afm_called_by = Keyword.get(opts, :afm_called_by)

    case cache_get(cache, cache_key(opts)) do
      {:ok, data} ->
        {:ok, data}

      :miss ->
        afm_called_for
        |> build_initial_results(username, password, afm_called_by)
        |> run()
        |> case do
          {:ok, %Results{data: data}} -> {:ok, mapize(data)}
          {:error, %Results{errors: errors}} -> {:error, errors}
        end
    end
  end

  defp cache_key(opts) do
    target = Keyword.get(opts, :afm_called_for, "")
    source = Keyword.get(opts, :afm_called_by, "")
    "vatchex:#{target}:#{source}"
  end

  defp maybe_cache(nil, _key, _data), do: :ok

  defp maybe_cache(cache, key, data),
    do: VatchexGreece.Cache.put(cache, key, data, cache_ttl())

  defp cache_get(nil, _key), do: :miss
  defp cache_get(cache, key), do: VatchexGreece.Cache.get(cache, key)

  defp cache_ttl,
    do: Application.get_env(:vatchex_greece, :cache_ttl, 3_600_000)

  # --- VIES fallback ---

  defp vies_fallback(errors, opts) do
    afm = Keyword.get(opts, :afm_called_for, "")

    with :ok <- ensure_vies_loaded(),
         normalized <- Validate.minimize(afm),
         true <- Validate.correct_checksum?(normalized),
         {:ok, vies_data} <- VatchexVies.lookup("EL", normalized) do
      {:ok, vies_data}
    else
      _ ->
        {:error, errors}
    end
  end

  defp ensure_vies_loaded do
    case Application.ensure_all_started(:vatchex_vies) do
      {:ok, _} ->
        :ok

      {:error, {:already_started, _}} ->
        :ok

      _ ->
        {:error, :vatchex_vies_not_available}
    end
  end

  # --- Legacy pipeline (internal) ---

  defp build_initial_results(afm_called_for, username, password, afm_called_by) do
    %Results{
      auth: %APIauth{
        username: username,
        password: password,
        afm_called_by: afm_called_by
      },
      data: %GSISdata{afm: afm_called_for}
    }
  end

  defp run(%Results{} = input) do
    input
    |> Validate.validate()
    |> Request.prepare()
    |> Request.post()
    |> Processing.parse()
  end

  defp mapize(x) when is_struct(x) do
    x
    |> Map.from_struct()
    |> mapize()
  end

  defp mapize(x) when is_map(x) do
    x
    |> Enum.map(fn {k, v} -> {k, mapize(v)} end)
    |> Map.new()
  end

  defp mapize(x) when is_list(x), do: Enum.map(x, &mapize/1)

  defp mapize(x), do: x
end

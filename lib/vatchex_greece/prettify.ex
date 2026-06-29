# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Prettify do
  @moduledoc """
  Optional post-processing for `VatchexGreece.fetch/1` results.

  Reshapes the raw GSIS response map into a more ergonomic form:

  - Adds `afm_full` derived from `afm`.
  - Combines postal address fields into a `%{street_address: ..., raw: ...}` submap.
  - Adds `is_active` derived from `stop_date`.
  - Reshapes `activities` list into `%{primary: map | nil, secondary: [maps]}`.

  Pass `pretty: true` to `fetch/1` to apply this automatically.
  """

  @doc """
  Reshape a successful fetch result.

  Transparently passes through `{:error, reason}` tuples unchanged.
  """
  def pretty({:error, reason}), do: {:error, reason}

  def pretty({:ok, data}) when is_map(data) do
    {:ok, do_pretty(data)}
  end

  defp do_pretty(data) do
    data
    |> maybe_add_afm_full()
    |> reshape_postal_address()
    |> maybe_add_is_active()
    |> maybe_add_year_founded()
    |> reshape_activities()
  end

  # --- afm_full ---

  defp maybe_add_afm_full(%{afm: afm} = data) when is_binary(afm) do
    Map.put(data, :afm_full, "EL" <> afm)
  end

  defp maybe_add_afm_full(data), do: data

  # --- postal address ---

  defp reshape_postal_address(%{postal_address: _} = data) do
    raw = %{
      postal_address: data.postal_address,
      postal_address_no: data.postal_address_no,
      postal_zip_code: data.postal_zip_code,
      postal_area_description: data.postal_area_description
    }

    addr_line1 =
      [data.postal_address, data.postal_address_no]
      |> Enum.map(&trim_or_nil/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    addr_line2 =
      [data.postal_zip_code, data.postal_area_description]
      |> Enum.map(&trim_or_nil/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    street_address =
      case {addr_line1, addr_line2} do
        {"", ""} -> nil
        {"", line2} -> line2
        {line1, ""} -> line1
        {line1, line2} -> line1 <> ", " <> line2
      end

    data
    |> Map.put(:postal_address, %{street_address: street_address, raw: raw})
    |> Map.drop([:postal_address_no, :postal_zip_code, :postal_area_description])
  end

  defp reshape_postal_address(data), do: data

  defp trim_or_nil(nil), do: nil

  defp trim_or_nil(value) do
    value
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  # --- is_active ---

  defp maybe_add_is_active(%{stop_date: stop_date} = data) do
    # stop_date nil => active; string date => inactive
    Map.put(data, :is_active, is_nil(stop_date))
  end

  defp maybe_add_is_active(data), do: data

  # --- year_founded ---

  defp maybe_add_year_founded(%{regist_date: regist_date} = data)
       when is_binary(regist_date) do
    case Date.from_iso8601(regist_date) do
      {:ok, %Date{year: year}} -> Map.put(data, :year_founded, year)
      _error -> Map.put(data, :year_founded, nil)
    end
  end

  defp maybe_add_year_founded(data), do: Map.put(data, :year_founded, nil)

  # --- activities ---

  defp reshape_activities(%{activities: activities} = data) when is_list(activities) do
    {primary_list, secondary_list} =
      activities
      |> Enum.split_with(fn act ->
        prio = act[:prio] || act["prio"]
        String.trim(to_string(prio)) == "1"
      end)

    primary =
      case primary_list do
        [act] ->
          %{code: act[:code] || act["code"], descr: act[:descr] || act["descr"]}

        _ ->
          nil
      end

    secondary =
      secondary_list
      |> Enum.map(fn act ->
        %{code: act[:code] || act["code"], descr: act[:descr] || act["descr"]}
      end)

    Map.put(data, :activities, %{
      primary: primary,
      secondary: secondary
    })
  end

  defp reshape_activities(data), do: data
end

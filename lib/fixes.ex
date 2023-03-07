defmodule VatchexGreece.Fixes do
  # SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
  # SPDX-License-Identifier: Apache-2.0

  @moduledoc """
  Fix/correct some elements of the response map.
  """
  @moduledoc since: "0.4.0"

  @key_information :RgWsPublicBasicRt_out
  @key_activities :arrayOfRgWsPublicFirmActRt_out

  @doc """
  Apply all fixes, i.e. fix activities list, unquote commercial if quoted, and
  convert the registration date to YYYY-MM-DD format.
  """
  def apply_all(response_tuple) do
    case response_tuple do
      {:ok, response_map} ->
        {:ok,
         response_map
         |> fix_activities_list()
         |> unquote_commercial_title()
         |> make_iso_registration_date()}

      _ ->
        response_tuple
    end
  end

  defp fix_activities_list(response_map) do
    key = @key_activities

    activities =
      response_map[key]
      |> Enum.map(fn {_, v} -> {"n" <> v.firmActCode, v} end)
      |> Map.new()

    %{response_map | key => activities}
  end

  defp unquote_commercial_title(response_map) do
    keys = [@key_information, :commerTitle]
    current_value = get_in(response_map, keys)
    to_replace = "\""

    if current_value != %{} and String.contains?(current_value, to_replace) do
      new_value =
        get_in(response_map, keys)
        |> String.replace(to_replace, "")

      put_in(response_map, keys, new_value)
    else
      response_map
    end
  end

  defp make_iso_registration_date(response_map) do
    keys = [@key_information, :registDate]

    new_value =
      get_in(response_map, keys)
      |> String.slice(0, 10)
      |> Date.from_iso8601!()
      |> Date.to_string()

    put_in(response_map, keys, new_value)
  end
end

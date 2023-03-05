defmodule VatchexGreece.Fixes do
  @moduledoc """
  Fix/correct some elements of the response.
  """
  @moduledoc since: "0.4.0"

  @key_information :RgWsPublicBasicRt_out
  @key_activities :arrayOfRgWsPublicFirmActRt_out

  @doc """
  Apply all fixes, i.e. fix activities list, unquote commercial if quoted, and
  convert the registration date to YYYY-MM-DD format.
  """
  def apply_all(m) do
    m
    |> fix_activities_list()
    |> unquote_commercial_title()
    |> make_iso_registration_date()
  end

  defp fix_activities_list(m) do
    key = @key_activities

    activities =
      m[key]
      |> Enum.map(fn {_, v} -> {"n" <> v.firmActCode, v} end)
      |> Map.new()

    %{m | key => activities}
  end

  defp unquote_commercial_title(m) do
    keys = [@key_information, :commerTitle]
    current_value = get_in(m, keys)
    to_replace = "\""

    if current_value != %{} and String.contains?(current_value, to_replace) do
      new_value =
        get_in(m, keys)
        |> String.replace(to_replace, "")

      put_in(m, keys, new_value)
    else
      m
    end
  end

  defp make_iso_registration_date(m) do
    keys = [@key_information, :registDate]

    new_value =
      get_in(m, keys)
      |> String.slice(0, 10)
      |> Date.from_iso8601!()
      |> Date.to_string()

    put_in(m, keys, new_value)
  end
end

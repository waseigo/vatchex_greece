# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Processing do
  @moduledoc false

  require Logger
  import SweetXml
  alias VatchexGreece.{NACEactivity, GSISdata, Results}

  @doc """
  Extract strings of attribute within the XML of the response body.
  """
  @doc since: "0.7.0"
  def extract_string(xml, attribute) do
    s =
      xml
      |> xpath(~x"//#{attribute}/text()"s)
      |> String.trim()
      |> String.replace("\"", "")
      |> String.split()
      |> Enum.join(" ")

    if s == "" do
      nil
    else
      s
    end
  end

  @doc """
  Extract service error from error_rec in the XML response body, if any.
  Returns nil if no error, or a map with :code and :descr.
  """
  @doc since: "0.9.0"
  def extract_error(xml) do
    code = extract_string(xml, "error_code")
    descr = extract_string(xml, "error_descr")

    if is_nil(code) and is_nil(descr) do
      nil
    else
      %{code: code, descr: descr}
    end
  end

  @doc """
  Extract list of activities from the XML of the response body and convert
  them into a list of legacy activity structs (internal to the pipeline).
  """
  @doc since: "0.7.0"
  def extract_activities(xml) do
    activities =
      SweetXml.xpath(xml, ~x"//item"l,
        firm_act_code: ~x"./firm_act_code/text()"s,
        firm_act_descr: ~x"./firm_act_descr/text()"s,
        firm_act_kind: ~x"./firm_act_kind/text()"i,
        firm_act_kind_descr: ~x"./firm_act_kind_descr/text()"s
      )

    if Enum.any?(activities, &needs_fix?/1) do
      Logger.info(
        "Detected broken firm_act_code and firm_act_descr field values in activities list. Will fix."
      )
    end

    Enum.map(activities, &map_to_nace(&1))
  end

  defp map_to_nace(activity) when is_map(activity) do
    activity = maybe_fix_activity(activity)

    %NACEactivity{
      code: activity.firm_act_code,
      prio: activity.firm_act_kind,
      descr: activity.firm_act_descr,
      prio_text: activity.firm_act_kind_descr
    }
  end

  defp needs_fix?(activity) do
    case parse_kad(activity.firm_act_descr) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp maybe_fix_activity(activity) when is_map(activity) do
    case parse_kad(activity.firm_act_descr) do
      {:ok, %{kad: kad, descr: descr}} ->
        %{activity | firm_act_code: kad, firm_act_descr: descr}

      {:error, :invalid_format} ->
        activity
    end
  end

  @doc """
  Extracts the 8-digit ΚΑΔ and the description from a raw string that is sometimes returned from the RgWsPublic2 API, with the `firm_act_code` field value being some kind of non-ΚΑΔ internal ID (apparently), and the `firm_act_descr` field value containing the actual 8-digit ΚΑΔ, separated with spaces from the actual description.

  Returns `{:ok, %{kad: kad, descr: descr}}` on success or `{:error, :invalid_format}`.
  """
  def parse_kad(input) when is_binary(input) do
    # Matches 8 digits, followed by one or more whitespace characters,
    # followed by the rest of the string.
    case Regex.run(~r/^(\d{8})\s+(.*)$/, String.trim(input)) do
      [_, kad, description] ->
        {:ok, %{kad: kad, descr: String.trim(description)}}

      _ ->
        {:error, :invalid_format}
    end
  end

  @doc """
  Parse the response body into a legacy `%GSISdata{}` (and optionally a service
  error) and wrap it back into the `%Results{}` accumulator.

  This is an internal step of the (deprecated) pipeline.
  """
  @doc since: "0.7.0"
  def parse({:ok, %Results{response: response, data: data} = input}) do
    body = response.body
    service_error = extract_error(body)

    strings_to_extract =
      data
      |> Map.keys()
      |> List.delete(:__struct__)
      |> List.delete(:activities)
      |> List.delete(:address_collapsed)

    data_map =
      strings_to_extract
      |> Map.new(fn k -> {k, extract_string(body, k)} end)

    data_struct = struct(GSISdata, data_map)

    data_struct = %{
      data_struct
      | activities: extract_activities(body),
        address_collapsed: collapse_address(data_struct)
    }

    if service_error do
      errors = Map.put(input.errors || %{}, :code, service_error.code)
      errors = Map.put(errors, :descr, service_error.descr)
      {:error, %Results{input | data: data_struct, errors: errors}}
    else
      {:ok, %Results{input | data: data_struct}}
    end
  end

  def parse({:error, input}) do
    {:error, input}
  end

  defp collapse_address(%{postal_address: nil, postal_address_no: nil, postal_zip_code: nil, postal_area_description: nil}), do: nil

  defp collapse_address(data) do
    [data.postal_address, data.postal_address_no, data.postal_zip_code, data.postal_area_description]
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> case do
      "" -> nil
      s -> s
    end
  end
end

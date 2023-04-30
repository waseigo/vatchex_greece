# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Process do
  @moduledoc """
  Process the response and convert it to a map within a response tuple.
  """
  @moduledoc since: "0.3.0"

  import SweetXml

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
  Extract list of activities from the XML of the response body and convert the resulting map to a list of `NACEactivity` structs.
  """
  @doc since: "0.7.0"
  def extract_activities(xml) do
    map_to_nace = fn %{
                       firm_act_code: code,
                       firm_act_kind: prio,
                       firm_act_descr: descr,
                       firm_act_kind_descr: prio_text
                     } ->
      %NACEactivity{code: code, prio: prio, descr: descr, prio_text: prio_text}
    end

    xml
    |> SweetXml.xpath(~x"//item"l,
      firm_act_code: ~x"./firm_act_code/text()"s,
      firm_act_descr: ~x"./firm_act_descr/text()"s,
      firm_act_kind: ~x"./firm_act_kind/text()"i,
      firm_act_kind_descr: ~x"./firm_act_kind_descr/text()"s
    )
    |> Enum.map(&map_to_nace.(&1))
  end

  @doc """
  Parse the XML of the response body and update the `Results` struct.
  """
  @doc since: "0.7.0"
  def parse({:ok, %Results{response: response, data: data} = input}) do
    strings_to_extract =
      data
      |> Map.keys()
      |> List.delete(:__struct__)
      |> List.delete(:activities)

    data_map =
      strings_to_extract
      |> Map.new(fn k ->
        {k, VatchexGreece.Process.extract_string(response.body, k)}
      end)

    data_struct = struct(GSISdata, data_map)

    data_struct = %GSISdata{
      data_struct
      | activities: extract_activities(response.body)
    }

    {:ok, %Results{input | data: data_struct}}
  end

  def parse({:error, input}) do
    {:error, input}
  end
end

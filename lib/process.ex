defmodule VatchexGreece.Process do
  # SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
  # SPDX-License-Identifier: Apache-2.0

  @moduledoc """
  Process the response and convert it to a map.
  """
  @moduledoc since: "0.3.0"

  @doc """
  Convert the response to a map if valid, otherwise return an empty map.
  """
  def to_map(response) do
    {status, result} = response

    case status do
      :ok ->
        result
        |> rename_all_keys()
        |> Soap.Response.Parser.parse(:whatever)
        |> Map.fetch!(:rgWsPublicAfmMethodResponse)
        |> Map.delete(:pCallSeqId_out)
        |> Map.delete(:pErrorRec_out)

      :error_wrong_afm ->
        result
        |> rename_all_keys()
        |> Soap.Response.Parser.parse(:whatever)
        |> Map.fetch!(:rgWsPublicAfmMethodResponse)
        |> Map.fetch!(:pErrorRec_out)

      :error_other ->
        %{}
    end
  end

  @doc """
  Handle any errors based on the HTTP response content.
  """
  def from_request(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        if String.contains?(body, "RG_WS_PUBLIC_WRONG_AFM") do
          {:error_wrong_afm, body}
        else
          {:ok, body}
        end

      {:ok, %HTTPoison.Response{body: body}} ->
        {:error_other, body}

      _ ->
        response
    end
  end

  defp rename_all_keys(response) do
    response
    |> String.replace("<m:", "<")
    |> String.replace("</m:", "</")
  end
end

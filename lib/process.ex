defmodule VatchexGreece.Process do
  # SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
  # SPDX-License-Identifier: Apache-2.0

  @moduledoc """
  Process the response and convert it to a map within a response tuple.
  """
  @moduledoc since: "0.3.0"

  @doc """
  Convert the response to {:ok, map} if valid, otherwise return {:error, %{}}.
  """
  def to_map(response) do
    {status, result} = response

    case status do
      :ok ->
        {:ok,
         result
         |> rename_all_keys()
         |> Soap.Response.Parser.parse(:whatever)
         |> Map.fetch!(:rgWsPublicAfmMethodResponse)
         |> Map.delete(:pCallSeqId_out)
         |> Map.delete(:pErrorRec_out)}

      :error_wrong_afm ->
        {:error,
         result
         |> rename_all_keys()
         |> Soap.Response.Parser.parse(:whatever)
         |> Map.fetch!(:rgWsPublicAfmMethodResponse)
         |> Map.fetch!(:pErrorRec_out)}

      :error_not_authenticated ->
        {:error, "Error: not authenticated."}

      error ->
        {error, %{}}
    end
  end

  @doc """
  Handle any errors based on the HTTP response content.
  """
  def from_request(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        cond do
          String.contains?(body, "RG_WS_PUBLIC_WRONG_AFM") ->
            {:error_wrong_afm, body}

          String.contains?(body, "NOT_AUTHENTICATED") ->
            {:error_not_authenticated, body}

          true ->
            {:ok, body}
        end

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {String.to_atom("error_" <> Integer.to_string(code)), body}

      _ ->
        {:error_other, response}
    end
  end

  defp rename_all_keys(response) do
    response
    |> String.replace("<m:", "<")
    |> String.replace("</m:", "</")
  end
end

# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Request do
  @moduledoc false
  require EEx
  require Logger
  alias VatchexGreece.Results

  @gsis_endpoint_url "https://www1.gsis.gr/wsaade/RgWsPublic2/RgWsPublic2"

  @doc """
  Build the SOAP envelope for a lookup (used by both the current and the
  deprecated pipeline).
  """
  @doc since: "0.5.0"
  # statically compile the XML request template and create a function to customize it
  EEx.function_from_file(
    :def,
    :to_xml,
    "lib/vatchex_greece/request.xml.eex",
    [:afm_called_for, :username, :password, :afm_called_by, :as_on_date]
  )

  def prepare({:ok, %Results{auth: auth, data: data} = input}) do
    as_on_date = Date.utc_today() |> Date.to_iso8601()

    xml =
      to_xml(
        data.afm,
        auth.username,
        auth.password,
        auth.afm_called_by,
        as_on_date
      )

    {:ok, %Results{input | request: xml}}
  end

  def prepare({:error, input}) do
    {:error, input}
  end

  @doc """
  POST the XML request with proper headers to the SOAP web service.
  """
  @doc since: "0.5.0"
  def post({:ok, %Results{request: xml, errors: errors} = input}) do
    params = [
      url: @gsis_endpoint_url,
      method: :post,
      body: xml
    ]

    req =
      params
      |> Req.new()
      |> Req.Request.put_header("Content-Type", "application/soap+xml")
      |> Req.Request.put_header("User-Agent", user_agent())

    Logger.debug("Dispatching request to RgWsPublic2 SOAP API")
    {_, %Req.Response{status: status} = response} = Req.Request.run_request(req)

    if status == 200 do
      handle_status_200(input, response)
    else
      message = "HTTP status code #{status} (not OK)"

      errors =
        Map.put(errors, :http_not_ok, message)

      Logger.error("RgWsPublic2 SOAP API: #{message}")

      {:error, %Results{input | response: response, errors: errors}}
    end
  end

  def post({:error, input}) do
    {:error, input}
  end

  defp user_agent, do: Enum.join([client(), version()], "/")

  defp client do
    __MODULE__
    |> Module.split()
    |> hd()
  end

  defp version do
    client()
    |> Macro.underscore()
    |> String.to_atom()
    |> Application.spec(:vsn)
  end

  # refactored function to avoid 3-levels-deep case handling in post/1
  defp handle_status_200(
         %Results{} = input,
         %Req.Response{} = http_response
       ) do
    Logger.debug("RgWsPublic2 SOAP API: HTTP status code 200")
    {:ok, %Results{input | response: http_response}}
  end
end

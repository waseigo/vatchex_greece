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
  def post({:ok, %Results{request: xml} = input}) do
    req =
      [url: endpoint_url(), method: :post, body: xml]
      |> Req.new()
      |> Req.Request.put_header("Content-Type", "application/soap+xml")
      |> Req.Request.put_header("User-Agent", user_agent())

    execute_request(input, req)
  end

  def post({:error, input}) do
    {:error, input}
  end

  @doc false
  def endpoint_url do
    Application.get_env(:vatchex_greece, :gsis_endpoint_url, @gsis_endpoint_url)
  end

  @doc false
  def stub_endpoint(url) do
    Application.put_env(:vatchex_greece, :gsis_endpoint_url, url)
  end

  @doc false
  def restore_endpoint(url) do
    Application.put_env(:vatchex_greece, :gsis_endpoint_url, url)
  end

  def do_post_with_request({:ok, %Results{} = input}, req) do
    execute_request(input, req)
  end

  def do_post_with_request({:error, input}, _req), do: {:error, input}

  defp execute_request(%Results{} = input, req) do
    Logger.debug("Dispatching request to RgWsPublic2 SOAP API")

    case Req.Request.run_request(req) do
      {_req, %Req.Response{status: 200} = response} ->
        handle_status_200(input, response)

      {_req, %Req.Response{status: status} = response} ->
        descr = "HTTP status code #{status} (not OK)"
        errors = %{code: :http_not_ok, descr: descr}

        Logger.error("RgWsPublic2 SOAP API: #{descr}")

        {:error, %Results{input | response: response, errors: errors}}

      {_req, reason} ->
        descr = "Transport error: #{inspect(reason)}"
        errors = %{code: :transport_error, descr: descr}

        Logger.error("RgWsPublic2 SOAP API: #{descr}")

        {:error, %Results{input | errors: errors}}
    end
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

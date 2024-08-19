# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Request do
  require EEx

  @moduledoc """
  Prepare and post a request to the SOAP web service.
  """
  @moduledoc since: "0.2.0"

  @gsis_wsdl_url "https://www1.gsis.gr/wsaade/RgWsPublic2/RgWsPublic2?wsdl"

  @doc """
  Prepare the request's XML template based on the VAT ID you call for),
  and authentication settings (username, password, VAT ID you call from).
  """
  @doc since: "0.5.0"
  # statically compile the XML request template and create a function to customize it
  EEx.function_from_file(
    :def,
    :to_xml,
    "lib/request.xml.eex",
    [:afm_called_for, :username, :password, :afm_called_by]
  )

  def prepare({:ok, %Results{auth: auth, data: data} = input}) do
    xml =
      to_xml(
        data.afm,
        auth.username,
        auth.password,
        auth.afm_called_by
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
      url: @gsis_wsdl_url,
      method: :post,
      body: xml
    ]

    req =
      params
      |> Req.new()
      |> Req.Request.put_header("Content-Type", "application/soap+xml")
      |> Req.Request.put_header("User-Agent", user_agent())

    {_, %Req.Response{status: status} = response} = Req.Request.run_request(req)

    if status == 200 do
      handle_status_200(input, response)
    else
      errors =
        Map.put(errors, :http_not_OK, "HTTP status code #{status} (not OK).")

      {:error, %Results{input | response: response, errors: errors}}
    end
  end

  def post({:error, input}) do
    {:error, input}
  end

  defp user_agent do
    client =
      __MODULE__
      |> Module.split()
      |> hd()

    version =
      client
      |> Macro.underscore()
      |> String.to_atom()
      |> Application.spec(:vsn)

    List.to_string([client, "/", version])
  end

  # refactored function to avoid 3-levels-deep case handling in post/1
  defp handle_status_200(
         %Results{errors: errors} = input,
         %Req.Response{body: body} = http_response
       ) do
    if String.contains?(
         body,
         "RG_WS_PUBLIC_TOKEN_USERNAME_NOT_AUTHENTICATED"
       ) do
      errors = Map.put(errors, :authentication_error, "Authentication error.")
      {:error, %Results{input | response: http_response, errors: errors}}
    else
      {:ok, %Results{input | response: http_response, errors: nil}}
    end
  end
end

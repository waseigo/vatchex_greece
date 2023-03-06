defmodule VatchexGreece.Request do
  # SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
  # SPDX-License-Identifier: Apache-2.0

  require EEx

  @moduledoc """
  Prepare and post a request to the SOAP web service.
  """
  @moduledoc since: "0.2.0"

  @settings Application.compile_env(:vatchex_greece, :globals) |> Map.new()
  @xml_template File.read!(@settings.xml_template)

  @doc """
  Prepare the request's XML template based on the settings (username, password,
  VAT ID you call from) and the input (VAT ID you call for).
  """
  def prepare(afmCalledFor) do
    EEx.eval_string(@xml_template,
      username: @settings.username,
      password: @settings.password,
      afmCalledBy: @settings.afmCalledBy,
      afmCalledFor: afmCalledFor
    )
  end

  @doc """
  POST the XML request with proper headers to the SOAP web service.
  """
  def post(xml) do
    wsdl_url = @settings.gsis_wsdl_url
    headers = %{"Content-Type" => "application/soap+xml"}
    HTTPoison.post(wsdl_url, xml, headers)
  end
end

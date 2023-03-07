defmodule VatchexGreece.Request do
  # SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
  # SPDX-License-Identifier: Apache-2.0

  require EEx

  @moduledoc """
  Prepare and post a request to the SOAP web service.
  """
  @moduledoc since: "0.2.0"

  @gsis_wsdl_url "https://www1.gsis.gr/webtax2/wsgsis/RgWsPublic/RgWsPublicPort?wsdl"

  @doc """
  Prepare the request's XML template based on the VAT ID you call for),
  and authentication settings (username, password, VAT ID you call from).
  """
  # statically compile the XML request template and create a function to customize it
  EEx.function_from_file(
    :def,
    :prepare,
    "lib/request.xml.eex",
    [:afm_called_for, :username, :password, :afm_called_by]
  )

  @doc """
  POST the XML request with proper headers to the SOAP web service.
  """
  def post(xml) do
    HTTPoison.post(
      @gsis_wsdl_url,
      xml,
      %{"Content-Type" => "application/soap+xml"}
    )
  end
end

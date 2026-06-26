# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.TransportErrorTest do
  use ExUnit.Case

  alias VatchexGreece
  alias VatchexGreece.{APIauth, GSISdata, Request, Results}

  test "Request.do_post_with_request/2 handles transport failure without crashing" do
    results = %Results{
      auth: %APIauth{username: "user", password: "pass", afm_called_by: "998144460"},
      data: %GSISdata{afm: "998144460"},
      request: "<xml>test</xml>",
      errors: %{}
    }

    req =
      [url: "http://127.0.0.1:1/test", method: :post, body: "<xml>test</xml>"]
      |> Req.new()
      |> Req.Request.put_header("Content-Type", "application/soap+xml")
      |> Req.Request.put_header("User-Agent", "VatchexGreece/1.1.0")

    assert {:error, %Results{errors: errors}} = Request.do_post_with_request({:ok, results}, req)
    assert errors[:code] == :transport_error
    assert errors[:descr] =~ ~r/Transport error/
  end
end

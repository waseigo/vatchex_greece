# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreeceTest do
  use ExUnit.Case
  doctest VatchexGreece
end

defmodule VatchexGreece.ValidateTest do
  use ExUnit.Case

  alias VatchexGreece.Validate

  describe "minimize/1" do
    test "strips EL prefix" do
      assert Validate.minimize("EL123456789") == "123456789"
    end

    test "strips GR prefix" do
      assert Validate.minimize("GR123456789") == "123456789"
    end

    test "pads 8-digit VAT IDs with leading zero" do
      assert Validate.minimize("12345678") == "012345678"
    end

    test "removes internal whitespace" do
      assert Validate.minimize("1 2 3 4 5 6 7 8 9") == "123456789"
    end

    test "removes leading and trailing whitespace" do
      assert Validate.minimize("  123456789  ") == "123456789"
    end

    test "handles integer input" do
      assert Validate.minimize(123_456_789) == "123456789"
    end

    test "pads 8-digit integer input" do
      assert Validate.minimize(12_345_678) == "012345678"
    end

    test "returns 9-digit string unchanged" do
      assert Validate.minimize("123456789") == "123456789"
    end

    test "strips non-digit characters and pads" do
      assert Validate.minimize("abc") == "000000000"
    end
  end

  describe "valid?/1" do
    test "returns true for a valid 9-digit VAT ID with correct checksum" do
      assert Validate.valid?("998144460") == true
    end

    test "returns true for 000000000 (checksum 0)" do
      assert Validate.valid?("000000000") == true
    end

    test "returns false for a VAT ID with incorrect checksum" do
      assert Validate.valid?("123456789") == false
    end

    test "returns false for a VAT ID with wrong length after minimize" do
      assert Validate.valid?("12345678") == false
    end

    test "returns false for non-numeric input that normalizes to bad checksum" do
      assert Validate.valid?("12345678a") == false
    end

    test "returns true for 110000000 (valid checksum)" do
      assert Validate.valid?("110000000") == true
    end
  end

  describe "check_only_digits/1" do
    test "returns ok for digit-only input" do
      assert {:ok, "123456789"} = Validate.check_only_digits("123456789")
    end

    test "returns error for input starting with non-digit" do
      assert {:error, _} = Validate.check_only_digits("a12345678")
    end

    test "Integer.parse behavior: accepts trailing non-digits" do
      assert {:ok, "12345678a"} = Validate.check_only_digits("12345678a")
    end
  end

  describe "check_proper_length/1" do
    test "returns ok for 9-digit input" do
      assert {:ok, "123456789"} = Validate.check_proper_length("123456789")
    end

    test "returns error for shorter input" do
      assert {:error, _} = Validate.check_proper_length("12345678")
    end

    test "returns error for longer input" do
      assert {:error, _} = Validate.check_proper_length("1234567890")
    end
  end

  describe "check_correct_checksum/1" do
    test "returns ok for valid checksum" do
      assert {:ok, "998144460"} = Validate.check_correct_checksum("998144460")
    end

    test "returns error for invalid checksum" do
      assert {:error, _} = Validate.check_correct_checksum("998144461")
    end
  end
end

defmodule VatchexGreece.ProcessingTest do
  use ExUnit.Case

  alias VatchexGreece.Processing

  @sample_response ~s"""
  <?xml version="1.0" encoding="UTF-8"?>
  <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
    <env:Body>
      <rgWsPublic2AfmMethodResponse>
        <result>
          <onomasia>ΟΝΟΜΑΣΙΑ ΕΤΑΙΡΕΙΑΣ</onomasia>
          <commer_title>ΕΜΠΟΡΙΚΟΣ ΤΙΤΛΟΣ</commer_title>
          <legal_status_descr>ΑΕ</legal_status_descr>
          <postal_address>ΟΔΟΣ</postal_address>
          <postal_address_no>10</postal_address_no>
          <postal_zip_code>12345</postal_zip_code>
          <postal_area_description>ΠΕΡΙΟΧΗ</postal_area_description>
          <regist_date>2020-01-01</regist_date>
          <stop_date></stop_date>
          <doy>123</doy>
          <doy_descr>ΔΟΥ ΠΕΡΙΟΧΗΣ</doy_descr>
          <i_ni_flag_descr>ΕΝΕΡΓΗ</i_ni_flag_descr>
          <deactivation_flag>0</deactivation_flag>
          <deactivation_flag_descr></deactivation_flag_descr>
          <firm_flag_descr>ΠΡΟΪΣΤΑΜΕΝΗ</firm_flag_descr>
          <normal_vat_system_flag>N</normal_vat_system_flag>
          <as_on_date>2026-06-25</as_on_date>
          <item>
            <firm_act_code>47110001</firm_act_code>
            <firm_act_descr>47110001 - Λιανική εμπορία τροφίμων</firm_act_descr>
            <firm_act_kind>1</firm_act_kind>
            <firm_act_kind_descr>ΚΥΡΙΑ</firm_act_kind_descr>
          </item>
          <item>
            <firm_act_code>47120002</firm_act_code>
            <firm_act_descr>47120002 - Λιανική εμπορία ποτών</firm_act_descr>
            <firm_act_kind>2</firm_act_kind>
            <firm_act_kind_descr>ΔΕΥΤΕΡΕΥΟΥΣΑ</firm_act_kind_descr>
          </item>
        </result>
      </rgWsPublic2AfmMethodResponse>
    </env:Body>
  </env:Envelope>
  """

  @error_response ~s"""
  <?xml version="1.0" encoding="UTF-8"?>
  <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
    <env:Body>
      <rgWsPublic2AfmMethodResponse>
        <result>
          <error_code>1001</error_code>
          <error_descr>Λάθος στοιχεία πρόσβασης</error_descr>
        </result>
      </rgWsPublic2AfmMethodResponse>
    </env:Body>
  </env:Envelope>
  """

  @empty_fields_response ~s"""
  <?xml version="1.0" encoding="UTF-8"?>
  <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
    <env:Body>
      <rgWsPublic2AfmMethodResponse>
        <result>
          <onomasia></onomasia>
          <commer_title></commer_title>
          <regist_date></regist_date>
        </result>
      </rgWsPublic2AfmMethodResponse>
    </env:Body>
  </env:Envelope>
  """

  @kad_swap_response ~s"""
  <?xml version="1.0" encoding="UTF-8"?>
  <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
    <env:Body>
      <rgWsPublic2AfmMethodResponse>
        <result>
          <onomasia>ΟΝΟΜΑΣΙΑ</onomasia>
          <item>
            <firm_act_code>99999999</firm_act_code>
            <firm_act_descr>47110001 Λιανική εμπορία τροφίμων</firm_act_descr>
            <firm_act_kind>1</firm_act_kind>
            <firm_act_kind_descr>ΚΥΡΙΑ</firm_act_kind_descr>
          </item>
        </result>
      </rgWsPublic2AfmMethodResponse>
    </env:Body>
  </env:Envelope>
  """

  describe "extract_string/2" do
    test "extracts a string field from XML" do
      assert Processing.extract_string(@sample_response, "onomasia") ==
               "ΟΝΟΜΑΣΙΑ ΕΤΑΙΡΕΙΑΣ"
    end

    test "collapses multiple spaces" do
      xml = ~s"<root><field>hello    world</field></root>"
      assert Processing.extract_string(xml, "field") == "hello world"
    end

    test "strips surrounding whitespace" do
      xml = ~s"<root><field>  hello  </field></root>"
      assert Processing.extract_string(xml, "field") == "hello"
    end

    test "returns nil for empty elements" do
      assert Processing.extract_string(@empty_fields_response, "onomasia") == nil
    end

    test "returns nil for missing elements" do
      assert Processing.extract_string(@sample_response, "nonexistent_field") == nil
    end
  end

  describe "extract_error/1" do
    test "returns nil when no error in response" do
      assert Processing.extract_error(@sample_response) == nil
    end

    test "returns error map when error_rec is present" do
      error = Processing.extract_error(@error_response)
      assert error != nil
      assert error.code == "1001"
      assert error.descr == "Λάθος στοιχεία πρόσβασης"
    end
  end

  describe "extract_activities/1" do
    test "extracts activities from response" do
      activities = Processing.extract_activities(@sample_response)
      assert length(activities) == 2

      primary = Enum.find(activities, &(&1.prio == 1))
      assert primary.code == "47110001"
      assert primary.descr == "- Λιανική εμπορία τροφίμων"
      assert primary.prio_text == "ΚΥΡΙΑ"

      secondary = Enum.find(activities, &(&1.prio == 2))
      assert secondary.code == "47120002"
      assert secondary.prio_text == "ΔΕΥΤΕΡΕΥΟΥΣΑ"
    end

    test "returns empty list when no activities" do
      assert Processing.extract_activities(@error_response) == []
    end

    test "fixes KAD code when it appears in description field" do
      activities = Processing.extract_activities(@kad_swap_response)
      assert length(activities) == 1

      activity = hd(activities)
      assert activity.code == "47110001"
      assert activity.descr == "Λιανική εμπορία τροφίμων"
      assert activity.prio == 1
      assert activity.prio_text == "ΚΥΡΙΑ"
    end
  end

  describe "parse_kad/1" do
    test "parses 8-digit KAD followed by description" do
      assert {:ok, %{kad: "47110001", descr: "Λιανική εμπορία"}} =
               Processing.parse_kad("47110001 Λιανική εμπορία")
    end

    test "returns error for input without 8-digit prefix" do
      assert {:error, :invalid_format} = Processing.parse_kad("not a kad")
    end

    test "returns error for input with only digits" do
      assert {:error, :invalid_format} = Processing.parse_kad("47110001")
    end

    test "trims leading/trailing whitespace" do
      assert {:ok, %{kad: "47110001", descr: "Test"}} =
               Processing.parse_kad("  47110001 Test  ")
    end

    test "handles multiple spaces between KAD and description" do
      assert {:ok, %{kad: "47110001", descr: "Test activity"}} =
               Processing.parse_kad("47110001   Test activity")
    end
  end
end

defmodule VatchexGreece.RequestTest do
  use ExUnit.Case

  alias VatchexGreece.Request

  describe "to_xml/5" do
    test "generates valid SOAP envelope XML" do
      xml = Request.to_xml("123456789", "testuser", "testpass", "987654321", "2026-06-25")

      assert xml =~ ~s|<env:Envelope|
      assert xml =~ ~s|<ns1:Username>testuser</ns1:Username>|
      assert xml =~ ~s|<ns1:Password>testpass</ns1:Password>|
      assert xml =~ ~s|<ns3:afm_called_by>987654321</ns3:afm_called_by>|
      assert xml =~ ~s|<ns3:afm_called_for>123456789</ns3:afm_called_for>|
      assert xml =~ ~s|<ns3:as_on_date>2026-06-25</ns3:as_on_date>|
    end

    test "XML starts with xml declaration" do
      xml = Request.to_xml("123456789", "u", "p", "987654321", "2026-06-25")
      assert String.starts_with?(xml, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    end

    test "contains proper SOAP namespaces" do
      xml = Request.to_xml("123456789", "u", "p", "987654321", "2026-06-25")
      assert xml =~ ~s|http://www.w3.org/2003/05/soap-envelope|
      assert xml =~ ~s|http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd|
      assert xml =~ ~s|http://rgwspublic2/RgWsPublic2Service|
      assert xml =~ ~s|http://rgwspublic2/RgWsPublic2|
    end

    test "includes credentials verbatim in the envelope" do
      xml = Request.to_xml("123456789", "myuser", "mypass", "987654321", "2026-06-25")
      assert xml =~ ~s|<ns1:Username>myuser</ns1:Username>|
      assert xml =~ ~s|<ns1:Password>mypass</ns1:Password>|
    end
  end
end

defmodule VatchexGreece.PipelineTest do
  use ExUnit.Case

  alias VatchexGreece

  @sample_response ~s"""
  <?xml version="1.0" encoding="UTF-8"?>
  <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
    <env:Body>
      <rgWsPublic2AfmMethodResponse>
        <result>
          <onomasia>ΟΝΟΜΑΣΙΑ ΕΤΑΙΡΕΙΑΣ</onomasia>
          <commer_title>ΕΜΠΟΡΙΚΟΣ ΤΙΤΛΟΣ</commer_title>
          <legal_status_descr>ΑΕ</legal_status_descr>
          <postal_address>ΟΔΟΣ</postal_address>
          <postal_address_no>10</postal_address_no>
          <postal_zip_code>12345</postal_zip_code>
          <postal_area_description>ΠΕΡΙΟΧΗ</postal_area_description>
          <regist_date>2020-01-01</regist_date>
          <stop_date></stop_date>
          <doy>123</doy>
          <doy_descr>ΔΟΥ ΠΕΡΙΟΧΗΣ</doy_descr>
          <i_ni_flag_descr>ΕΝΕΡΓΗ</i_ni_flag_descr>
          <deactivation_flag>0</deactivation_flag>
          <deactivation_flag_descr></deactivation_flag_descr>
          <firm_flag_descr>ΠΡΟΪΣΤΑΜΕΝΗ</firm_flag_descr>
          <normal_vat_system_flag>N</normal_vat_system_flag>
          <as_on_date>2026-06-25</as_on_date>
          <item>
            <firm_act_code>47110001</firm_act_code>
            <firm_act_descr>47110001 - Λιανική εμπορία τροφίμων</firm_act_descr>
            <firm_act_kind>1</firm_act_kind>
            <firm_act_kind_descr>ΚΥΡΙΑ</firm_act_kind_descr>
          </item>
          <item>
            <firm_act_code>47120002</firm_act_code>
            <firm_act_descr>47120002 - Λιανική εμπορία ποτών</firm_act_descr>
            <firm_act_kind>2</firm_act_kind>
            <firm_act_kind_descr>ΔΕΥΤΕΡΕΥΟΥΣΑ</firm_act_kind_descr>
          </item>
        </result>
      </rgWsPublic2AfmMethodResponse>
    </env:Body>
  </env:Envelope>
  """

  @error_response ~s"""
  <?xml version="1.0" encoding="UTF-8"?>
  <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
    <env:Body>
      <rgWsPublic2AfmMethodResponse>
        <result>
          <error_code>1001</error_code>
          <error_descr>Λάθος στοιχεία πρόσβασης</error_descr>
        </result>
      </rgWsPublic2AfmMethodResponse>
    </env:Body>
  </env:Envelope>
  """

  @gsis_path "/wsaade/RgWsPublic2/RgWsPublic2"
  @vies_path "/taxation_customs/vies/rest-api/check-vat-number"

  setup do
    # Ensure TestCache agent is started for cache tests
    {:ok, _pid} = start_supervised(VatchexGreece.TestCache)
    :ok
  end

  describe "fetch/1" do
    test "returns company data for valid VAT" do
      Req.Test.stub(:gsis, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/soap+xml")
        |> Plug.Conn.resp(200, @sample_response)
      end)

      assert {:ok, result} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 test_adapter: {Req.Test, :gsis}
               )

      assert result[:onomasia] == "ΟΝΟΜΑΣΙΑ ΕΤΑΙΡΕΙΑΣ"
      assert result[:activities] |> length() == 2
      assert result[:address_collapsed] == "ΟΔΟΣ 10 12345 ΠΕΡΙΟΧΗ"
    end

    test "returns error when target VAT has invalid checksum" do
      assert {:error, errors} =
               VatchexGreece.fetch(
                 afm_called_for: "123456789",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460"
               )

      assert errors[:code] == :invalid_vat
      assert errors[:descr] =~ ~r/Invalid target VAT/i
    end

    test "returns error when source VAT has invalid checksum" do
      assert {:error, errors} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "123456789"
               )

      assert errors[:code] == :invalid_vat
      assert errors[:descr] =~ ~r/Invalid source VAT/i
    end

    test "returns error when both VAT IDs have invalid checksum" do
      assert {:error, errors} =
               VatchexGreece.fetch(
                 afm_called_for: "123456789",
                 username: "user",
                 password: "pass",
                 afm_called_by: "987654321"
               )

      assert errors[:code] == :invalid_vat
      assert errors[:descr] =~ ~r/Invalid VAT/i
    end

    test "returns error on transport failure" do
      Req.Test.stub(:gsis, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %{code: :transport_error, descr: descr}} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 test_adapter: {Req.Test, :gsis}
               )

      assert descr =~ ~r/Transport error/i
    end

    test "returns error on HTTP 500" do
      Req.Test.stub(:gsis, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(500, "Server Error")
      end)

      assert {:error, %{code: :http_not_ok, descr: descr}} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 test_adapter: {Req.Test, :gsis}
               )

      assert descr =~ ~r/HTTP status code 500/
    end

    test "returns nil address_collapsed when no postal fields in response" do
      minimal_response = ~s"""
      <?xml version="1.0" encoding="UTF-8"?>
      <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
        <env:Body>
          <rgWsPublic2AfmMethodResponse>
            <result>
              <onomasia>ONLY NAME</onomasia>
            </result>
          </rgWsPublic2AfmMethodResponse>
        </env:Body>
      </env:Envelope>
      """

      Req.Test.stub(:gsis, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/soap+xml")
        |> Plug.Conn.resp(200, minimal_response)
      end)

      assert {:ok, result} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 test_adapter: {Req.Test, :gsis}
               )

      assert result[:onomasia] == "ONLY NAME"
      assert result[:address_collapsed] == nil
    end

    test "returns service error from GSIS error_rec" do
      Req.Test.stub(:gsis, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/soap+xml")
        |> Plug.Conn.resp(200, @error_response)
      end)

      assert {:error, %{code: "1001", descr: "Λάθος στοιχεία πρόσβασης"}} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "wrong",
                 password: "wrong",
                 afm_called_by: "998144460",
                 test_adapter: {Req.Test, :gsis}
               )
    end
  end

  describe "fetch!/1" do
    test "raises FetchError on invalid VAT input" do
      assert_raise VatchexGreece.FetchError, ~r/Errors during fetch/, fn ->
        VatchexGreece.fetch!(
          afm_called_for: "123456789",
          username: "user",
          password: "pass",
          afm_called_by: "998144460"
        )
      end
    end

    test "FetchError contains the errors map" do
      try do
        VatchexGreece.fetch!(
          afm_called_for: "123456789",
          username: "user",
          password: "pass",
          afm_called_by: "998144460"
        )
      rescue
        e in VatchexGreece.FetchError ->
          assert is_map(e.errors)
          assert e.message =~ ~r/Errors during fetch/
      end
    end

    test "does not make HTTP request when validation fails" do
      assert_raise VatchexGreece.FetchError, fn ->
        VatchexGreece.fetch!(
          afm_called_for: "123456789",
          username: "user",
          password: "pass",
          afm_called_by: "123456789"
        )
      end
    end
  end

  describe "VIES fallback" do
    @vies_success_response %{
      countryCode: "EL",
      vatNumber: "998144460",
      valid: true,
      name: "VIES FALLBACK CO",
      tradingName: nil,
      address: "VIA 1, ATHENS"
    }

    test "returns VIES data when GSIS fails and VIES succeeds" do
      http_stub = fn conn ->
        case conn.request_path do
          @gsis_path ->
            Plug.Conn.resp(conn, 500, "GSIS Error")

          @vies_path ->
            conn
            |> Plug.Conn.put_resp_header("content-type", "application/json")
            |> Plug.Conn.resp(200, Jason.encode!(@vies_success_response))
        end
      end

      Req.Test.stub(:http, http_stub)

      assert {:ok, result} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 fetch_vies_fallback: true,
                 test_adapter: {Req.Test, :http}
               )

      assert result[:source] == :vies
      assert result[:onomasia] == "VIES FALLBACK CO"
      assert result[:afm] == "998144460"
    end

    test "returns GSIS error when VIES fallback fails" do
      http_stub = fn conn ->
        case conn.request_path do
          @gsis_path ->
            Plug.Conn.resp(conn, 500, "GSIS Error")

          @vies_path ->
            conn
            |> Plug.Conn.put_resp_header("content-type", "application/json")
            |> Plug.Conn.resp(200, Jason.encode!(%{valid: false}))
        end
      end

      Req.Test.stub(:http, http_stub)

      assert {:error, %{code: :http_not_ok}} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 fetch_vies_fallback: true,
                 test_adapter: {Req.Test, :http}
               )
    end

    test "returns GSIS error directly when fallback not enabled" do
      Req.Test.stub(:gsis, fn conn ->
        Plug.Conn.resp(conn, 500, "GSIS Error")
      end)

      assert {:error, %{code: :http_not_ok}} =
               VatchexGreece.fetch(
                 afm_called_for: "998144460",
                 username: "user",
                 password: "pass",
                 afm_called_by: "998144460",
                 test_adapter: {Req.Test, :gsis}
               )
    end
  end

  describe "caching" do
    test "caches successful results via TestCache" do
      Req.Test.stub(:gsis, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/soap+xml")
        |> Plug.Conn.resp(200, @sample_response)
      end)

      opts = [
        afm_called_for: "998144460",
        username: "user",
        password: "pass",
        afm_called_by: "998144460",
        cache: VatchexGreece.TestCache,
        test_adapter: {Req.Test, :gsis}
      ]

      assert {:ok, result} = VatchexGreece.fetch(opts)
      assert {:ok, ^result} = VatchexGreece.fetch(opts)
    end

    test "does not cache errors" do
      Req.Test.stub(:gsis, fn conn ->
        Plug.Conn.resp(conn, 500, "Server Error")
      end)

      opts = [
        afm_called_for: "998144460",
        username: "user",
        password: "pass",
        afm_called_by: "998144460",
        cache: VatchexGreece.TestCache,
        test_adapter: {Req.Test, :gsis}
      ]

      assert {:error, _} = VatchexGreece.fetch(opts)

      # After the error, cache should be empty — second call hits API again
      Req.Test.stub(:gsis, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/soap+xml")
        |> Plug.Conn.resp(200, @sample_response)
      end)

      assert {:ok, _} = VatchexGreece.fetch(opts)
    end
  end
end

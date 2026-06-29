# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.PrettifyTest do
  use ExUnit.Case

  alias VatchexGreece.Prettify

  @sample_gsis_data %{
    afm: "801712899",
    as_on_date: "2026-06-25",
    doy: "1190",
    doy_descr: "KENTRIKH",
    i_ni_flag_descr: "MH FPA",
    deactivation_flag: "1",
    deactivation_flag_descr: "ENERGOS AFM",
    firm_flag_descr: "EPITHDEYMATIAS",
    onomasia: "COMPANY AE",
    commer_title: "COMPANY",
    legal_status_descr: "AE",
    postal_address: "PEIREOS",
    postal_address_no: "3",
    postal_zip_code: "15125",
    postal_area_description: "MAROUSSI",
    regist_date: "2021-12-15",
    stop_date: nil,
    normal_vat_system_flag: "Y",
    activities: [
      %{code: "68200000", descr: "MAIN ACT", prio: 1, prio_text: "PRIMARY"},
      %{code: "62101000", descr: "SECOND ACT", prio: 2, prio_text: "SECONDARY"}
    ]
  }

  describe "pretty/1 passthrough" do
    test "passes through {:error, reason} unchanged" do
      assert Prettify.pretty({:error, :something}) == {:error, :something}
    end
  end

  describe "pretty/1 core transforms" do
    test "adds afm_full" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      assert result[:afm_full] == "EL801712899"
    end

    test "combines postal address into street_address submap" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})

      assert result[:postal_address][:street_address] ==
               "PEIREOS 3, 15125 MAROUSSI"
    end

    test "keeps raw postal fields under raw submap" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      raw = result[:postal_address][:raw]
      assert raw.postal_address == "PEIREOS"
      assert raw.postal_address_no == "3"
      assert raw.postal_zip_code == "15125"
      assert raw.postal_area_description == "MAROUSSI"
    end

    test "removes flattened postal fields from top-level" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      refute Map.has_key?(result, :postal_address_no)
      refute Map.has_key?(result, :postal_zip_code)
      refute Map.has_key?(result, :postal_area_description)
    end

    test "adds is_active: true when stop_date is nil" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      assert result[:is_active] == true
    end

    test "adds is_active: false when stop_date is a string" do
      data = %{@sample_gsis_data | stop_date: "2024-01-01"}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:is_active] == false
    end
  end

  describe "activities reshaping" do
    test "separates primary and secondary" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      activities = result[:activities]

      assert activities.primary == %{
               code: "68200000",
               descr: "MAIN ACT"
             }

      assert length(activities.secondary) == 1
      assert hd(activities.secondary).code == "62101000"
    end

    test "strips prio and prio_text from secondary" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      act = hd(result[:activities].secondary)
      refute Map.has_key?(act, :prio)
      refute Map.has_key?(act, :prio_text)
    end

    test "returns nil primary when no prio==1 activity" do
      data = %{
        @sample_gsis_data
        | activities: [
            %{
              code: "62101000",
              descr: "SECOND ACT",
              prio: 2,
              prio_text: "SECONDARY"
            }
          ]
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:activities].primary == nil
      assert length(result[:activities].secondary) == 1
    end

    test "handles empty activities list" do
      data = %{@sample_gsis_data | activities: []}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:activities].primary == nil
      assert result[:activities].secondary == []
    end
  end

  describe "year_founded" do
    test "adds year_founded from a valid ISO8601 regist_date" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      assert result[:year_founded] == 2021
    end

    test "year_founded is nil when regist_date is nil" do
      data = %{@sample_gsis_data | regist_date: nil}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert Map.has_key?(result, :year_founded)
      assert result[:year_founded] == nil
    end

    test "year_founded is nil when regist_date is garbage" do
      data = %{@sample_gsis_data | regist_date: "not-a-date"}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert Map.has_key?(result, :year_founded)
      assert result[:year_founded] == nil
    end

    test "year_founded is nil when regist_date is empty" do
      data = %{@sample_gsis_data | regist_date: ""}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert Map.has_key?(result, :year_founded)
      assert result[:year_founded] == nil
    end

    test "year_founded is nil when regist_date key is absent" do
      data = Map.delete(@sample_gsis_data, :regist_date)
      {:ok, result} = Prettify.pretty({:ok, data})
      assert Map.has_key?(result, :year_founded)
      assert result[:year_founded] == nil
    end

    test "parses year from various ISO8601 formats" do
      data = %{@sample_gsis_data | regist_date: "1999-06-30"}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:year_founded] == 1999
    end
  end

  describe "edge cases" do
    test "handles all blank postal fields" do
      data = %{
        afm: "123456789",
        postal_address: nil,
        postal_address_no: nil,
        postal_zip_code: nil,
        postal_area_description: nil,
        stop_date: nil,
        activities: []
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:postal_address][:street_address] == nil
    end

    test "handles partial postal data (only street name)" do
      data = %{
        afm: "123456789",
        postal_address: "ODOS",
        postal_address_no: nil,
        postal_zip_code: nil,
        postal_area_description: nil,
        stop_date: nil,
        activities: []
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:postal_address][:street_address] == "ODOS"
    end

    test "handles partial postal data (zip + area only)" do
      data = %{
        afm: "123456789",
        postal_address: nil,
        postal_address_no: nil,
        postal_zip_code: "12345",
        postal_area_description: "ATHINA",
        stop_date: nil,
        activities: []
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:postal_address][:street_address] == "12345 ATHINA"
    end

    test "handles partial postal data (number + zip + area)" do
      data = %{
        afm: "123456789",
        postal_address: nil,
        postal_address_no: "5",
        postal_zip_code: "12345",
        postal_area_description: "ATHINA",
        stop_date: nil,
        activities: []
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:postal_address][:street_address] == "5, 12345 ATHINA"
    end

    test "handles whitespace-only postal fields" do
      data = %{
        afm: "123456789",
        postal_address: "  ",
        postal_address_no: "  ",
        postal_zip_code: "",
        postal_area_description: "",
        stop_date: nil,
        activities: []
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:postal_address][:street_address] == nil
    end

    test "handles string prio values like \"1\" in activities" do
      data = %{
        afm: "123456789",
        postal_address: nil,
        postal_address_no: nil,
        postal_zip_code: nil,
        postal_area_description: nil,
        stop_date: nil,
        activities: [
          %{
            "code" => "11111111",
            "descr" => "TEST",
            "prio" => "1",
            "prio_text" => "PRIMARY"
          }
        ]
      }

      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:activities].primary.code == "11111111"
      assert result[:activities].secondary == []
    end

    test "adds afm_full for non-empty binary afm" do
      data = %{afm: "", stop_date: nil, activities: []}
      {:ok, result} = Prettify.pretty({:ok, data})
      assert result[:afm_full] == "EL"
    end

    test "skips afm_full when afm is nil" do
      data = %{afm: nil, stop_date: nil, activities: []}
      {:ok, result} = Prettify.pretty({:ok, data})
      refute Map.has_key?(result, :afm_full)
    end

    test "preserves all other fields as-is" do
      {:ok, result} = Prettify.pretty({:ok, @sample_gsis_data})
      assert result[:onomasia] == "COMPANY AE"
      assert result[:commer_title] == "COMPANY"
      assert result[:regist_date] == "2021-12-15"
      assert result[:normal_vat_system_flag] == "Y"
      assert result[:as_on_date] == "2026-06-25"
    end
  end
end

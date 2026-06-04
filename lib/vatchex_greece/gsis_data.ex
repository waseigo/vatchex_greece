# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.GSISdata do
  @moduledoc false
  @enforce_keys [:afm]
  defstruct [
    :afm,
    :as_on_date,
    :doy,
    :doy_descr,
    :i_ni_flag_descr,
    :deactivation_flag,
    :deactivation_flag_descr,
    :firm_flag_descr,
    :onomasia,
    :commer_title,
    :legal_status_descr,
    :postal_address,
    :postal_address_no,
    :postal_zip_code,
    :postal_area_description,
    :regist_date,
    :stop_date,
    :normal_vat_system_flag,
    activities: []
  ]
end

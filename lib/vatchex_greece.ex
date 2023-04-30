# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule APIauth do
  @moduledoc """
  Defines the `%APIauth{}` struct used to store authentication data for SOAP API calls.
  """
  @moduledoc since: "0.7.0"
  @enforce_keys [:username, :password, :afm_called_by]
  defstruct @enforce_keys
end

defmodule NACEactivity do
  @moduledoc """
  Defines the `%NACEactivity{}` struct to store parsed information about company activities.
  """
  @enforce_keys [:code]
  defstruct code: nil,
            # secondary activity, if not specified otherwise with "1" for primary activity
            prio: 2,
            # description of the activity; cosmetic
            descr: nil,
            # "ΚΥΡΙΑ" for primary, "ΔΕΥΤΕΡΕΥΟΥΣΑ" for secondary; cosmetic
            prio_text: nil
end

defmodule GSISdata do
  @moduledoc """
  Defines the `%GSISdata{}` struct used by the functions of the `Process` module to process and store the response of the GSIS SOAP API in a usable format.
  """
  @moduledoc since: "0.7.0"
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

defmodule Results do
  @moduledoc """
  Defines the `%Results{}` struct that gets progressively enriched with information from the API.
  """
  @enforce_keys [:auth]
  defstruct [
    :auth,
    :data,
    :request,
    :response,
    errors: %{}
  ]
end

defmodule VatchexGreece do
  require EEx

  @moduledoc """
  Main module of `VatchexGreece` that contains high-level functions that the
  user typically will interact with.
  """
  @moduledoc since: "0.1.0"

  alias VatchexGreece.{Request, Process, Validate}

  @doc """
  Define a new struct that will be manipulated from containing only the minimal information required to query the SOAP API, to containing the complete request, the SOAP API response, and the parsed information thereof into the corresponding structs.

  You need to pass authentication parameters `username`, `password` and the
  source VAT ID `afm_called_by` as parameters.

  ## Examples

  Typically, you will pass a valid 9-digit VAT ID, with or without the "EL" prefix:
  ```
  new("123456783", ...) # valid (dummy) 9-digit VAT ID
  new("EL123456783", ...) # ditto, with "EL" prefix that will get stripped
  ```

  Older VAT IDs only have 8 digits, and will get leading-zero-padded to 9 digits:
  ```
  new("11111067", ...) # valid (dummy) 8-digit VAT ID
  ```
  """
  @doc since: "0.7.0"

  def new(afm_called_for, username, password, afm_called_by) do
    auth = %APIauth{
      username: username,
      password: password,
      afm_called_by: afm_called_by
    }

    data = %GSISdata{afm: afm_called_for}

    %Results{auth: auth, data: data}
  end

  @doc """
  Pull information from the web service for the target VAT ID `afm_called_for` defined in the `Results` struct that has first been created with `new/4`.

  Note: the function minimizes and checks the source and target VAT IDs, and only
  sends the request to the API if both minimized VAT IDs are valid.
  """

  @doc since: "0.7.0"
  def get(%Results{} = input) do
    input
    |> Validate.all_valid()
    |> Request.prepare()
    |> Request.post()
    |> Process.parse()
  end
end

#

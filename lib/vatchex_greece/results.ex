# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Results do
  @moduledoc false
  @enforce_keys [:auth]
  defstruct [
    :auth,
    :data,
    :request,
    :response,
    :test_adapter,
    errors: %{}
  ]
end

# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.APIauth do
  @moduledoc false
  @enforce_keys [:username, :password, :afm_called_by]
  defstruct @enforce_keys
end

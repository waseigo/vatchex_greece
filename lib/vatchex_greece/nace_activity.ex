# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.NACEactivity do
  @moduledoc false
  @enforce_keys [:code]
  defstruct code: nil,
            # secondary activity (1 = primary / "ΚΥΡΙΑ")
            prio: 2,
            descr: nil,
            prio_text: nil
end

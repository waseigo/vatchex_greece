# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.TestCache do
  @moduledoc false

  use Agent

  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def get(__MODULE__, key) do
    case Agent.get(__MODULE__, & &1[key]) do
      nil -> :miss
      value -> {:ok, value}
    end
  end

  def put(__MODULE__, key, value, _ttl) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
    :ok
  end
end



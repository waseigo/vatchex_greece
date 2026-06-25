# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
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

defimpl VatchexGreece.Cache, for: Atom do
  def get(cache, key) do
    apply(cache, :get, [cache, key])
  end

  def put(cache, key, value, ttl) do
    apply(cache, :put, [cache, key, value, ttl])
  end
end

# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

if Code.ensure_loaded?(Cachex) do
  defmodule VatchexGreece.CachexCache do
    @moduledoc """
    Cachex adapter for `VatchexGreece.Cache` protocol.

    Uses a Cachex instance (defaults to a cache named `:vatchex_greece`).
    Configure the cache name in your application config:

        config :vatchex_greece, :cache_name, :my_custom_cache

    The Cachex instance must be started in your supervision tree:

        children = [
          {Cachex, name: :vatchex_greece, limit: 10_000},
          ...
        ]
    """

    def get(cache, key) do
      case Cachex.get(cache, key) do
        {:ok, nil} -> :miss
        {:ok, value} -> {:ok, value}
        _ -> :miss
      end
    end

    def put(cache, key, value, ttl \\ cache_ttl()) do
      Cachex.put(cache, key, value, expiration: ttl)
    end

    defp cache_ttl, do: Application.get_env(:vatchex_greece, :cache_ttl, 3_600_000)
  end
end

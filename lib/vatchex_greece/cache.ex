# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defprotocol VatchexGreece.Cache do
  @moduledoc """
  Protocol for cache adapters used by `VatchexGreece.fetch/2`.
  """

  @doc """
  Looks up a cached value by key. Returns `{:ok, value}` or `:miss`.
  """
  def get(cache, key)

  @doc """
  Stores a value in the cache with a TTL in milliseconds.
  """
  def put(cache, key, value, ttl)
end

defimpl VatchexGreece.Cache, for: Atom do
  def get(VatchexGreece.CachexCache, key) do
    if Code.ensure_loaded?(VatchexGreece.CachexCache) do
      apply(VatchexGreece.CachexCache, :get, [VatchexGreece.CachexCache, key])
    else
      :miss
    end
  end

  def get(_, _), do: :miss

  def put(VatchexGreece.CachexCache, key, value, ttl) do
    if Code.ensure_loaded?(VatchexGreece.CachexCache) do
      apply(VatchexGreece.CachexCache, :put, [VatchexGreece.CachexCache, key, value, ttl])
    else
      :ok
    end
  end

  def put(_, _, _, _), do: :ok
end

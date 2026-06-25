# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
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

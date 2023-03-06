defmodule VatchexGreece.Validate do
  # SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@waseigo.com>
  # SPDX-License-Identifier: Apache-2.0

  @moduledoc """
  Module with functions used to validate Greek VAT IDs.
  """
  @moduledoc since: "0.5.0"

  @valid_chars Enum.map(0..9, fn x -> Kernel.to_string(x) end)

  @doc """
  Remove the "EL" or "GR" prefixes if present, remove any whitespace (leading,
  trailing, or internal), and return the VAT ID's minimal valid representation,
  including adding a leading "0" in case the provided ID had 8 digits (old format).
  """
  def minimize(vat_id) do
    vat_id
    |> String.graphemes()
    |> Enum.map(fn x -> if x in @valid_chars, do: x end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join()
    |> String.pad_leading(9, "0")
  end

  defp checksum(_, acc \\ 0)

  defp checksum([head | tail], acc) do
    acc = acc * 2 + head
    checksum(tail, acc)
  end

  defp checksum([], acc), do: acc

  defp calculate_check_digit(number) do
    String.graphemes(number)
    |> Enum.map(&String.to_integer/1)
    |> checksum()
    |> Kernel.*(2)
    |> Integer.mod(11)
    |> Integer.mod(10)
  end

  defp only_digits?(vat_id) do
    vat_id
    |> Integer.parse()
    |> Kernel.!=(:error)
  end

  defp proper_length?(vat_id) do
    vat_id
    |> String.length()
    |> Kernel.==(9)
  end

  defp checksum_ok?(vat_id) do
    last_digit = String.slice(vat_id, -1..-1)

    vat_id
    |> minimize()
    |> String.slice(0, 9 - 1)
    |> calculate_check_digit()
    |> to_string()
    |> Kernel.==(last_digit)
  end

  @doc """
  Check whether the VAT ID passed (as string) is valid, i.e. it has the correct
  length (9 total, and only digits), where the last digit is equal to the checksum
  calculate from the first 8 digits.
  """
  def is_valid?(vat_id) do
    checks = [
      &only_digits?/1,
      &proper_length?/1,
      &checksum_ok?/1
    ]

    false not in Enum.map(checks, fn func -> func.(vat_id) end)
  end
end

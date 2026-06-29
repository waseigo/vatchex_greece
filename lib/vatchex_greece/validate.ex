# SPDX-FileCopyrightText: 2026 Isaak Tsalicoglou <isaak@waseigo.com>
# SPDX-License-Identifier: Apache-2.0

defmodule VatchexGreece.Validate do
  @moduledoc false

  require Logger
  alias VatchexGreece.{APIauth, GSISdata, Results}

  @valid_chars Enum.map(0..9, fn x -> Kernel.to_string(x) end)

  @doc """
  Remove the "EL" or "GR" prefixes if present, remove any whitespace (leading,
  trailing, or internal), and return the VAT ID's minimal valid representation,
  including adding a leading "0" in case the provided ID had 8 digits (old format).
  """
  @doc since: "0.5.0"
  def minimize(vat_id) when is_binary(vat_id) do
    vat_id
    |> String.graphemes()
    |> Enum.map(fn x -> if x in @valid_chars, do: x end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join()
    |> String.pad_leading(9, "0")
  end

  def minimize(vat_id) when is_integer(vat_id) do
    vat_id
    |> Integer.to_string()
    |> minimize()
  end

  defp checksum(_, acc \\ 0)

  defp checksum([head | tail], acc) do
    acc = acc * 2 + head
    checksum(tail, acc)
  end

  defp checksum([], acc), do: acc

  defp calculate_check_digit(number) when is_binary(number) do
    String.graphemes(number)
    |> Enum.map(&String.to_integer/1)
    |> checksum()
    |> Kernel.*(2)
    |> Integer.mod(11)
    |> Integer.mod(10)
  end

  @doc """
  Check that the passed VAT ID only contains digits.
  """
  @doc since: "0.5.0"
  def check_only_digits(vat_id) when is_binary(vat_id) do
    c =
      vat_id
      |> Integer.parse()
      |> Kernel.!=(:error)

    if c do
      {:ok, vat_id}
    else
      message = "Error: VAT ID #{vat_id} does not contain only digits."
      Logger.error(message)
      {:error, message}
    end
  end

  def check_only_digits(vat_id) when is_integer(vat_id) do
    vat_id
    |> Integer.to_string()
    |> check_only_digits()
  end

  @doc """
  Unsafe check that the passed VAT ID only contains digits.
  """
  @doc since: "0.5.0"
  def check_only_digits!(vat_id) do
    case check_only_digits(vat_id) do
      {:ok, vat_id} -> vat_id
      {:error, message} -> raise RuntimeError, message: message
    end
  end

  @doc """
  Boolean check that the passed VAT ID only contains digits.
  """
  @doc since: "0.5.0"
  def only_digits?(vat_id) do
    case check_only_digits(vat_id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Check that the passed VAT ID has the proper length.
  """
  @doc since: "0.5.0"
  def check_proper_length(vat_id) do
    c =
      vat_id
      |> String.length()
      |> Kernel.==(9)

    if c do
      {:ok, vat_id}
    else
      message =
        "Error: VAT ID #{vat_id} has an incorrect length (not 9 digits)."

      Logger.error(message)
      {:error, message}
    end
  end

  @doc """
  Unsafe check that the passed VAT ID has the proper length.
  """
  @doc since: "0.5.0"
  def check_proper_length!(vat_id) do
    case check_proper_length(vat_id) do
      {:ok, vat_id} -> vat_id
      {:error, message} -> raise RuntimeError, message: message
    end
  end

  @doc """
  Boolean check that the passed VAT ID has the proper length.
  """
  @doc since: "0.5.0"
  def proper_length?(vat_id) do
    case check_proper_length(vat_id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Check that the passed VAT ID contains the correct checksum digit.
  """
  @doc since: "0.5.0"
  def check_correct_checksum(vat_id) do
    last_digit = String.slice(vat_id, -1..-1)

    c =
      vat_id
      |> minimize()
      |> String.slice(0, 9 - 1)
      |> calculate_check_digit()
      |> to_string()
      |> Kernel.==(last_digit)

    if c do
      {:ok, vat_id}
    else
      message = "Error: VAT ID #{vat_id} checksum mismatch."
      Logger.error(message)
      {:error, message}
    end
  end

  @doc """
  Unsafe check that the passed VAT ID contains the correct checksum digit.
  """
  @doc since: "0.5.0"
  def check_correct_checksum!(vat_id) do
    case check_correct_checksum(vat_id) do
      {:ok, vat_id} -> vat_id
      {:error, message} -> raise RuntimeError, message: message
    end
  end

  @doc """
  Boolean check that the passed VAT ID contains the correct checksum digit.
  """
  @doc since: "0.5.0"
  def correct_checksum?(vat_id) do
    case check_correct_checksum(vat_id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Check whether the VAT ID passed (as string) is valid, i.e. it has the correct
  length (9 total, and only digits), where the last digit is equal to the checksum
  calculate from the first 8 digits.
  """
  @doc since: "0.5.0"
  def valid?(vat_id) do
    checks = [
      &only_digits?/1,
      &proper_length?/1,
      &correct_checksum?/1
    ]

    false not in Enum.map(checks, fn func -> func.(vat_id) end)
  end

  @doc false
  def validate(
        %Results{
          auth: %APIauth{afm_called_by: afm_called_by},
          data: %GSISdata{afm: afm_called_for},
          errors: errors
        } = input
      ) do
    vat_validity =
      [afm_called_by, afm_called_for]
      |> Enum.map(&minimize(&1))
      |> Enum.map(&valid?(&1))

    case vat_validity do
      [false, false] ->
        errors =
          errors
          |> Map.put(:code, :invalid_vat)
          |> Map.put(:descr, "Invalid VAT IDs: source=#{afm_called_by}, target=#{afm_called_for}")

        {:error, %Results{input | errors: errors}}

      [false, true] ->
        errors =
          Map.put(%{}, :code, :invalid_vat)
          |> Map.put(:descr, "Invalid source VAT ID: #{afm_called_by}")

        {:error, %Results{input | errors: errors}}

      [true, false] ->
        errors =
          Map.put(%{}, :code, :invalid_vat)
          |> Map.put(:descr, "Invalid target VAT ID: #{afm_called_for}")

        {:error, %Results{input | errors: errors}}

      _ ->
        {:ok, input}
    end
  end
end

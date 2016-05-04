defmodule Dtgcaa do
  @moduledoc """
    Does this GIF contain an animation?

    See the GIF89a specification here:
    https://www.w3.org/Graphics/GIF/spec-gif89a.txthttps://www.w3.org/Graphics/GIF/spec-gif89a.txt
  """

  use Bitwise

  defmacrop image_block_label, do: 0x2C
  defmacrop extension_block_label, do: 0x21
  defmacrop trailer_block_label, do: 0x3B

  defp gif_signature_match?(<<"GIF87a",_::binary>>), do: true
  defp gif_signature_match?(<<"GIF89a",_::binary>>), do: true
  defp gif_signature_match?(_), do: false

  defp read_blocks(data, offset) when byte_size(data) - offset < 1 do
    :stream_next_chunk
  end

  defp read_blocks(data, offset) do
    case data do
      <<_::binary-size(offset),0,_::binary>> ->
        {:ok, offset + 1}
      <<_::binary-size(offset),size,_::binary>> ->
        case byte_size(data) - (offset + 1) < size do
          true -> :stream_next_chunk
          false -> read_blocks(data, offset + 1 + size)
        end
    end
  end

  defp parse(%{image_count: 2}) do
    {:halt, true}
  end

  defp parse(%{offset: 0, buffer: buffer} = state) do
    case byte_size(buffer) < 6 do
      true ->
        {:cont, state}
      false ->
        case gif_signature_match?(buffer) do
          false ->
            {:halt, {:error, :no_gif}}
          true ->
            parse(%{state | offset: 6})
        end
    end
  end

  defp parse(%{offset: 6 = offset, buffer: buffer} = state) when byte_size(buffer) - offset < 7 do
    {:cont, state}
  end

  defp parse(%{offset: 6 = offset, buffer: buffer} = state) do
    # logical screen descriptor
    <<_::binary-size(offset),_width::little-integer-size(16),
      _height::little-integer-size(16),color_table_flag::1,_color_resolution::3,
      _sort_flag::1,color_table_size::3,_background_color_index::8,
      _aspect_ratio::8,_::binary>> = buffer

    global_color_table_size = case color_table_flag do
      0 -> 0
      1 -> 3 * bsl(1, (color_table_size + 1))
    end

    parse(%{state | offset: offset + 7 + global_color_table_size})
  end

  defp parse(%{offset: offset, buffer: buffer, image_count: image_count} = state) do
    case buffer do
      <<_::binary-size(offset),image_block_label(),_::binary>> when byte_size(buffer) - offset < 10 ->
        {:cont, state}
      <<_::binary-size(offset),image_block_label(),_::binary>> ->
        # image descriptor
        <<_::binary-size(offset),image_block_label(),
          _left_position::little-integer-size(16),
          _top_position::little-integer-size(16),
          _width::little-integer-size(16),_height::little-integer-size(16),
          color_table_flag::1,_interlace_flag::1,_sort_flag::1,_reserved::2,
          color_table_size::3,_::binary>> = buffer

        local_color_table_size = case color_table_flag do
          0 -> 0
          1 -> 3 * bsl(1, color_table_size + 1)
        end

        next_offset = offset + 10 + local_color_table_size + 1

        case read_blocks(buffer, next_offset) do
          :stream_next_chunk ->
            {:cont, state}
          {:ok, new_offset} ->
            new_state = %{state | offset: new_offset, image_count: image_count + 1}
            parse(new_state)
        end
      <<_::binary-size(offset),extension_block_label(),_::binary>> ->
        case read_blocks(buffer, offset + 1 + 1) do
          :stream_next_chunk ->
            {:cont, %{state | buffer: buffer}}
          {:ok, new_offset} ->
            parse(%{state | offset: new_offset})
        end
      <<_::binary-size(offset),trailer_block_label(),_::binary>> ->
        {:halt, false}
      _ when byte_size(buffer) - offset < 1 ->
        {:cont, state}
      _ ->
        {:halt, {:error, :no_gif}}
    end
  end

  defp initial_parse_reducer_state do
    {:cont, %{image_count: 0, offset: 0, buffer: <<>>}}
  end

  @spec animated?(gif_data_stream :: Enumerable.t) :: boolean() | {:error, :no_gif | :incomplete_gif}
  def animated?(gif_data_stream) do
  end
end

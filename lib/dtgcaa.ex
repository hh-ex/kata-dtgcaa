defmodule Dtgcaa do
  @moduledoc """
    Does this GIF contain an animation?

    See the GIF89a specification here:
    https://www.w3.org/Graphics/GIF/spec-gif89a.txt
  """

  use Bitwise

  defmacrop image_block_label, do: 0x2C
  defmacrop extension_block_label, do: 0x21
  defmacrop trailer_block_label, do: 0x3B
  defmacrop block_terminator, do: 0x0

  defmacrop header_size, do: 6
  defmacrop logical_screen_descriptor_size, do: 7
  defmacrop image_descriptor_size, do: 10

  defp valid_header?(<<"GIF87a",_::binary>>), do: true
  defp valid_header?(<<"GIF89a",_::binary>>), do: true
  defp valid_header?(_), do: false

  # Reads data sub-blocks until a block terminator is reached.
  defp read_sub_blocks(data, offset) do
    case data do
      <<_::binary-size(offset),block_terminator(),_::binary>> ->
        {:ok, offset + 1}
      <<_::binary-size(offset),block_size,_::binary>> ->
        read_sub_blocks(data, offset + 1 + block_size)
      _ when byte_size(data) - offset < 1 ->
        :stream_next_chunk
    end
  end

  # When we've counted two images that means that the GIF is animated
  # and we can stop parsing it.
  defp parse(%{image_count: 2}) do
    {:halt, true}
  end

  defp parse(%{offset: 0, buffer: buffer} = state) when byte_size(buffer) < header_size do
    {:cont, state}
  end

  # Checks if the GIF data stream starts with a valid header.
  defp parse(%{offset: 0, buffer: buffer} = state) do
    case valid_header?(buffer) do
      false ->
        {:halt, {:error, :no_gif}}
      true ->
        parse(%{state | offset: header_size})
    end
  end

  defp parse(%{offset: header_size(), buffer: buffer} = state) when byte_size(buffer) - header_size < logical_screen_descriptor_size do
    {:cont, state}
  end

  # Parses the logical screen descriptor.
  defp parse(%{offset: header_size(), buffer: buffer} = state) do
    <<_::binary-size(header_size),_width::little-integer-size(16),
      _height::little-integer-size(16),color_table_flag::1,_color_resolution::3,
      _sort_flag::1,color_table_size::3,_background_color_index::8,
      _aspect_ratio::8,_::binary>> = buffer

    global_color_table_size = case color_table_flag do
      0 -> 0
      1 -> 3 * bsl(1, (color_table_size + 1))
    end

    new_offset = header_size + logical_screen_descriptor_size + global_color_table_size

    parse(%{state | offset: new_offset})
  end

  defp parse(%{offset: offset, buffer: buffer, image_count: image_count} = state) do
    case buffer do
      <<_::binary-size(offset),image_block_label(),_::binary>> when byte_size(buffer) - offset < image_descriptor_size ->
        {:cont, state}
      <<_::binary-size(offset),image_block_label(),_::binary>> ->
        # parse image descriptor

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

        next_offset = offset + image_descriptor_size + local_color_table_size + 1

        case read_sub_blocks(buffer, next_offset) do
          :stream_next_chunk ->
            {:cont, state}
          {:ok, new_offset} ->
            new_state = %{state | offset: new_offset, image_count: image_count + 1}
            parse(new_state)
        end
      <<_::binary-size(offset),extension_block_label(),_::binary>> ->
        # parse extension block
        case read_sub_blocks(buffer, offset + 1 + 1) do
          :stream_next_chunk ->
            {:cont, %{state | buffer: buffer}}
          {:ok, new_offset} ->
            parse(%{state | offset: new_offset})
        end
      <<_::binary-size(offset),trailer_block_label(),_::binary>> ->
        # end of the GIF data stream
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

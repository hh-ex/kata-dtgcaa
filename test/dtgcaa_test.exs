defmodule DtgcaaTest do
  use ExUnit.Case
  doctest Dtgcaa

  defp no_gif_stream do
    File.stream!("test/fixtures/no_gif.jpeg", [:read], 1)
  end

  defp animated_gif_stream do
    File.stream!("test/fixtures/animated.gif", [:read], 1)
  end

  defp unanimated_gif_stream do
    File.stream!("test/fixtures/unanimated.gif", [:read], 1)
  end

  defp incomplete_gif_stream do
    Stream.map([<<"GIF89a">>], &(&1))
  end

  test "no gif" do
    assert {:error, :no_gif} == Dtgcaa.animated?(no_gif_stream)
  end

  test "animated gif" do
    assert true == Dtgcaa.animated?(animated_gif_stream)
  end

  test "unanimated gif" do
    assert false == Dtgcaa.animated?(unanimated_gif_stream)
  end

  test "incomplete gif" do
    assert {:error, :incomplete_gif} == Dtgcaa.animated?(incomplete_gif_stream)
  end
end

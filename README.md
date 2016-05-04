# Kata: Does this GIF contain an animation?

The `Dtgcaa` module implements a GIF parser that takes a GIF data stream. The parser counts the images included in the stream until it either finds a second image (which means that the GIF is animated), or it reaches the end of the stream (which means that the GIF is not animated). It is implemented in a way that makes sure that it only takes as much data from the stream as is necessary for deciding whether the GIF is animated.

## Task

Make sure that `Dtgcaa.animated/1` passes the tests and fulfills the following type specification:

```elixir
    animated?(gif_data_stream :: Enumerable.t) :: boolean() | {:error, :no_gif | :incomplete_gif}
```

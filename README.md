# Kata: Does this GIF contain an animation?

[![Build Status](https://travis-ci.org/hh-ex/kata-dtgcaa.svg?branch=main)](https://travis-ci.org/hh-ex/kata-dtgcaa)

The `Dtgcaa` module implements a GIF parser that takes a GIF data stream. The parser counts the images included in the stream until it either finds a second image (which means that the GIF is animated), or it reaches the end of the stream (which means that the GIF is not animated). It is implemented in a way that makes sure that it only takes as much data from the stream as is necessary for deciding whether the GIF is animated.

## Challenge

Make sure that `Dtgcaa.animated/1` passes the existing tests and fulfills the following type specification:

```elixir
    animated?(gif_data_stream :: Enumerable.t) :: boolean() | {:error, :no_gif | :incomplete_gif}
```

## Hints

The actual GIF parser is already complete for that purpose, and there should be no need to modify any of the existing private functions. Basically, what needs to be done is finding a correct way of feeding the GIF data stream into the existing parser. 

## Helpful Resources

If you haven't done so yet, you probably want to check out the documentation of the [`Stream`](http://elixir-lang.org/docs/stable/elixir/Stream.html) module as well as the [`Enumerable`](http://elixir-lang.org/docs/stable/elixir/Enumerable.html) protocol.

In case you'd like to get some more background with regard to the `Enumerable` protocol, there's a great [blog post introducing Elixir's continuable enumerators](http://elixir-lang.org/blog/2013/12/11/elixir-s-new-continuable-enumerators/).

# Stytch demo

The two folders are separate Gleam projects that work together as
described in the [Lustre full stack
guide](https://hexdocs.pm/lustre/guide/06-full-stack-applications.html).

There is no shared package in this example as the only shared types come from
[stytch_codecs](../stytch_codecs/).

The [server](./server) package contains most of the interesting code that
interacts with [stytch_client](../stytch_client/).

The [client](./client/) package contains a lustre frontend that gets
distributed to the server's `priv` directory. It illustrates how to call the
apis defined in the server and one way to structure authentication in your app.

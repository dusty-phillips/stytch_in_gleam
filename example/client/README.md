# Example auth frontend with stytch

This package illustrates how to set up a frontend that calls your own backend
that wraps Stytch APIs for authentication. Most of this package is agnostic of
what your backend calls, though it does import some shared types for
expediency.

Based on the [Lustre full stack
guide](https://hexdocs.pm/lustre/guide/06-full-stack-applications.html)

## Build

```shell
gleam run -m lustre/dev build --outdir=../server/priv/static
```

This will install the client into the [server](../server) directory.
Run the server and it will load this client js.

## Structure

The [auth_views.gleam](./src/auth_views.gleam) file contains views
rendered by the stytch_ui_model package.

The main entry point is [client.gleam](./src/client.gleam) shows one way to
wrap the auth models in a model and integrate them with the init, update, and
view functions.

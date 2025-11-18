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

Most of the interesting work is in the [auth.gleam](./src/auth.gleam) module.
It includes a variety of Lustre model fields, update functions,
views, and effects to call the API for actions such as:

- check if user is logged in
- send a magic link to sign the user in
- sign the user out

It uses generics to only allow the model to contain data that requires
authentication if the user is logged in.

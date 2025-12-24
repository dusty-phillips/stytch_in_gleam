# Example auth frontend with stytch and modem

A client that can authenticate certain routes using pattern matching.

## Build

```shell
gleam run -m lustre/dev build --outdir=../server/priv/static
```

This will install the client into the [server](../server) directory.
Run the server and it will load this client js.

Note: works with the same server as the simple client.

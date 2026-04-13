# stytch_client

[![Package Version](https://img.shields.io/hexpm/v/stytch_codecs)](https://hex.pm/packages/stytch_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/stytch_client/)

This package wraps the [Stytch](https://stytch.com) authentication service in type-safe
Gleam code. It is meant to be used in your backend to authenticate users.

At the moment, only magic link and passcode auth are supported.

There are [examples](../example) showing a complete full stack lustre
application working with this package on Wisp backend and several alternative client setups..

You'll need the [stytch_codecs](../stytch_codecs) package from the monorepo to use this package.
It contains shared types and encoders that you will likely want to use in your UI.


## Steps to set up authentication (magic link)

1. Sign up for [Stytch](https://stytch.com)
2. Create a backend for your gleam repository (e.g.
   [wisp](https://hexdocs.pm/wisp/)) Follow [Lustre Full Stack
   Guide](https://hexdocs.pm/lustre/guide/06-full-stack-applications.html) if you
   need assistance.
3. Add a `.env` file with three keys:
   - SECRET_KEY_BASE: random 64 character string (e.g. from `wisp.random_string`)
   - STYTCH_PROJECT_ID: from Stytch dashboard
   - STYTCH_SECRET: from Stytch dashboard
4. Add routes for `send_sign_in_link`, `authenticate`, `me`, and `sign_out`
   using session token authentication. JWT might work; I haven't tested yet.
   Submit a PR updating this bullet if you do!
5. For each route (See [example routes](./example/server/src/router.gleam)):
   1. Decode json payload
   2. Construct a Stytch client
   3. Call the appropriate function in [stytch_client](./stytch_client/src/stytch_client.gleam)
   4. Process the response, handling errors appropriately
   5. Return appropriate response to frontend.
6. Create a frontend for your gleam repository, probably using Lustre.
7. Hook up auth model and views as shown in examples.
8. Do something with those unstyled auth views.
9. Run `gleam run -m lustre/dev build --outdir=../server/priv/static` in
   client package.
10. Run `gleam run` in server package.

Passcode auth is similar, but you'll need slightly different routes.

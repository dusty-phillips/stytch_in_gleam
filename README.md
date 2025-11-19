# Stytch Authentication from Gleam

This repo contains two gleam projects to aid in accessing the
[Stytch](https://stytch.com) authentication service. Stytch is a developer
friendly service providing headless (and nearly-headless) authentication APIs.

So far I've only implemented magic link auth. I intend to add passkeys, and am
open to PRs for other Stytch APIs.

There are two separate gleam packages:

- [stytch_codecs](./stytch_codecs/) contains types sent to or returned from
  Stytch, along with json encoders and gleam decoders. I made it a separate
  package so the types can be used in JavaScript frontends that call your API.
- [stytch_client](./stytch_client/) contains strongly typed Gleam functions
  that call the stytch API.
- [stytch_ui_model](./stytch_ui_model/) contains lustre model types and update functions
  for managing your authenticated app in the frontend.

In addition, there is an [example](./example/) folder that contains a fully
working magic link demo.

## Steps to set up authentication

1. Sign up for [Stytch](https://stytch.com)
2. Create a backend for your gleam repository (e.g.
   [wisp](https://hexdocs.pm/wisp/)) Follow [Lustre Full Stack
   Guide](https://hexdocs.pm/lustre/guide/06-full-stack-applications.html) if you
   need assistance.
3. Add a `.env` file with three keys:
   - SECRET_KEY_BASE: random 64 character string (from `wisp.random_string`)
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
   5. Return something to frontend.
6. Create a frontend for your gleam repository, probably using Lustre.
7. For now, copy the [auth.gleam](./example/client/src/auth.gleam) into your
   package. This will probably become a third package in this monorepo.
8. Hook up the auth model, update, and views to your application.
9. Do something with those unstyled auth views.
10. Run `gleam run -m lustre/dev build --outdir=../server/priv/static` in
    client package.
11. Run `gleam run` in server package.

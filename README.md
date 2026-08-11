# Stytch Authentication from Gleam

This repo contains two gleam projects to aid in accessing the
[Stytch](https://stytch.com) authentication service. Stytch is a developer
friendly service providing headless (and nearly-headless) authentication APIs.

Magic link, one time passcode, and passkey (WebAuthn) auth are supported.
I am open to PRs for other Stytch APIs.

There are three separate gleam packages:

- [stytch_codecs](./stytch_codecs/) contains types sent to or returned from
  Stytch, along with json encoders and gleam decoders. I made it a separate
  package so the types can be used in JavaScript frontends that call your API.
  See [![Hex
  Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/stytch_codecs/)
  for documentation.
- [stytch_client](./stytch_client/) contains strongly typed Gleam functions
  that call the stytch API. It is intended to be called from your backend.
  API is documented on [![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/stytch_client/)
- [stytch_ui_model](./stytch_ui_model/) contains lustre model types and update functions
  for managing your authenticated app in the frontend. It calls specific
  urls your backend must implement to manage state.
  _This package has not been released to Hex yet as I am uncomfortable with the devex._

In addition, there is an [example](./example/) folder that contains fully
working demos of magic link and passcode auth, as well as an example of how
auth and modem routes can live together.

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
   - STYTCH_DOMAIN (optional): the WebAuthn relying-party domain for passkeys.
     Defaults to `localhost`. Set it to your app's domain in production.
4. Add routes for `send_sign_in_link`, `authenticate`, `me`, and `sign_out`
   using session token authentication. JWT might work; I haven't tested yet.
   Submit a PR updating this bullet if you do!
   For passkey support, additionally add `start_register_passkey`,
   `finish_register_passkey`, `start_passkey_login`, `passkey_login`, and
   `delete_passkey` routes.
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

# Stytch Authentication from Gleam

This repo contains two gleam projects to aid in accessing the
[Stytch](https://stytch.com) authentication service. Stytch is a developer
friendly service providing headless (and nearly-headless) authentication APIs.

So far I've only implemented magic link auth. I intend to add passkeys, and am
open to PRs for other Stytch APIs.

There are two separate gleam packages:

- [stytch_codecs](./stytch_codecs/) contains types sent to or returned from
  Stytch, along with json encoders and gleam decoders. I made it a separate
  package so the types can be used in Javascript frontends that call your API.
- [stytch_client](./stytch_client/) contains strongly typed Gleam functions
  that call the stytch API.

In addition, there is an [example](./example/) folder that contains a fully
working magic link demo.

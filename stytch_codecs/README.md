# stytch_codecs

[![Package Version](https://img.shields.io/hexpm/v/stytch_codecs)](https://hex.pm/packages/stytch_codecs)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/stytch_codecs/)


Shared types used to construct requests to or responses from the
[Stytch](https://stytch.com) authentication service.

Currently contains all types needed to support magic link and one time passcode
authentication requests.

This package isn't very useful on its own; it is meant to share types between
JS frontend and JS or Erlang backend code. Use it in conjunction with the
[stytch_client](https://hexdocs.pm/stytch_client/index.html) package in your
backend and/or the (not yet published to hex)
[stytch_ui_model](https://github.com/dusty-phillips/stytch_in_gleam/tree/main/stytch_ui_model)
in your frontend

See [examples](https://github.com/dusty-phillips/stytch_in_gleam/tree/main/example) in the [stytch_in_gleam](https://github.com/dusty-phillips/stytch_in_gleam/) monorepo.

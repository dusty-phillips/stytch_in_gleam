# stytch_codecs

Shared types used to construct requests to or responses from the
[Stytch](https://stytch.com) authentication service.

Currently contains all types needed to support magic link and one time passcode
authentication requests.

These will mostly be used by your API that calls into Stytch client, but this
package exists for those cases where you want to reuse a Stytch response in
your Gleam frontend.

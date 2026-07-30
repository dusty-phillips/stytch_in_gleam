# stytch_ui_model

Lustre model and update function for authenticating part of your state using
Stytch magic links, one time passcodes, and passkeys.

This package targets JavaScript only: passkey support uses FFI to call the
browser WebAuthn APIs (`navigator.credentials.create/get`).

Assumes your backend has a specific url structure:

- You provide a prefix such as `https://mydomain.com/api`
- You implement routes for:
  - /send_sign_in_link (magic link auth)
  - /send_passcode and /verify_passcode (passcode auth)
  - /start_register_passkey and /finish_register_passkey (adding passkeys)
  - /start_passkey_login and /passkey_login (passkey auth)
  - /me
  - /sign_out
  - /authenticate (called by Stytch, not this package)

You'll also need to hook up some view components to call the update method in
this package.

See example lustre [views](../example/client_with_passkeys/src/auth_views.gleam)
and [client](../example/client_with_passkeys/src/client.gleam) to get started.

This package is not yet released to Hex because I'm not comfortable with the
developer experience. Something feels off and maybe somebody can tell me what
it is (or better yet, send a non-AI-coded PR).

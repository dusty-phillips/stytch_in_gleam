# stytch_ui_model

Lustre model and update function for authenticating part of your state using
Stytch magic links, one time passcodes, and passkeys.

This package targets JavaScript only.

Assumes your backend has a specific url structure (this may be configurable in a future major version):

- You provide a prefix such as `https://mydomain.com/api`
- You implement routes on your server for (depending which methods you want to support):
  - /send_sign_in_link (magic link auth)
  - /send_passcode and /verify_passcode (passcode auth)
  - /start_register_passkey and /finish_register_passkey (adding passkeys)
  - /delete_passkey/{webauthn_registration_id} (removing passkeys)
  - /start_passkey_login and /passkey_login (passkey auth)
  - /me
  - /sign_out
  - /authenticate (called by Stytch, not this package)

You'll also need to hook up some view components to call the update methods in
this package.

See [example clients](../example/) to get started.

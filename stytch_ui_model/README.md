# stytch_ui_model

Lustre model and update function for authenticating part of your state using
Stytch magic links.

Assumes your backend has a specific url structure:

- You provide a prefix such as `https://mydomain.com/api`
- You implement routes for:
  - /send_sign_in_link
  - /me
  - /sign_out
  - /authenticate (called by stytch, not this package)

You'll also need to hook up some view components to call the update method in
this package.

See example lustre [views](../example/client/src/auth_views.gleam) and
[client](../example/client/src/client.gleam) to get started.

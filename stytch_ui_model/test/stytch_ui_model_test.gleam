import gleam/http/response
import gleeunit
import lustre/effect
import rsvp
import stytch_codecs
import stytch_ui_model.{
  ApiAuthenticatedUser, ApiConfirmsUnauthenticated, ApiDeletedPasskey,
  ApiSentMagicLink, ApiStartedPasskeyRegister, AuthModel, Authenticated,
  Authenticating, DeletePasskeyFailed, DeletingPasskey, MagicLink, PasskeyIdle,
  PasskeyLoginInProgress, PasskeyRegisterFailed, StartingPasskeyRegister,
  Unauthenticated, UserClickedAddPasskey, UserClickedDeletePasskey,
  UserClickedPasskeySignIn, UserClickedSend, UserClickedSignOut,
  UserUpdatedEmail, WaitingForMagicLink,
}

pub fn main() {
  gleeunit.main()
}

fn test_user(email: String, verified: Bool) -> stytch_codecs.StytchUser {
  stytch_codecs.StytchUser(
    user_id: "user-123",
    name: stytch_codecs.Name(
      first_name: "Simon",
      middle_name: "Flo",
      last_name: "Gormon",
    ),
    emails: [
      stytch_codecs.Email(
        email_id: "some_email",
        email: email,
        verified: verified,
      ),
    ],
    webauthn_registrations: [],
  )
}

pub fn new_creates_authenticating_model_test() {
  let model = stytch_ui_model.new("http://api.test", MagicLink)

  assert model
    == stytch_ui_model.AuthModel(
      "http://api.test",
      stytch_ui_model.Authenticating,
      MagicLink,
    )
}

pub fn authenticating_to_unauthenticated_test() {
  let model = stytch_ui_model.new("http://api.test", MagicLink)
  let #(updated, eff) =
    stytch_ui_model.update(model, ApiConfirmsUnauthenticated)

  assert updated.state == Unauthenticated("")
  assert eff == effect.none()
}

pub fn authenticating_to_authenticated_test() {
  let model = stytch_ui_model.new("http://api.test", MagicLink)
  let user = test_user("test@example.com", True)
  let #(updated, eff) =
    stytch_ui_model.update(model, ApiAuthenticatedUser(user))

  assert updated.state == Authenticated(user, PasskeyIdle)
  assert eff == effect.none()
}

pub fn authenticated_multiple_emails_test() {
  let model = stytch_ui_model.new("http://api.test", MagicLink)
  let user =
    stytch_codecs.StytchUser(
      user_id: "user-123",
      name: stytch_codecs.Name(
        first_name: "Simon",
        middle_name: "Flo",
        last_name: "Gormon",
      ),
      emails: [
        stytch_codecs.Email(
          email_id: "email-1",
          email: "unverified@example.com",
          verified: False,
        ),
        stytch_codecs.Email(
          email_id: "email-2",
          email: "first@example.com",
          verified: True,
        ),
        stytch_codecs.Email(
          email_id: "email-3",
          email: "second@example.com",
          verified: True,
        ),
      ],
      webauthn_registrations: [],
    )
  let #(updated, _) = stytch_ui_model.update(model, ApiAuthenticatedUser(user))

  assert updated.state == Authenticated(user, PasskeyIdle)
}

pub fn user_updated_email_test() {
  let model = AuthModel("http://api.test", Unauthenticated(""), MagicLink)
  let #(updated, eff) =
    stytch_ui_model.update(model, UserUpdatedEmail("new@example.com"))

  assert updated.state == Unauthenticated("new@example.com")
  assert eff == effect.none()
}

pub fn send_magic_link_test() {
  let model =
    AuthModel("http://api.test", Unauthenticated("test@example.com"), MagicLink)
  let #(updated, eff) = stytch_ui_model.update(model, UserClickedSend)

  assert updated.state == WaitingForMagicLink("test@example.com")
  assert eff != effect.none()
}

pub fn api_sent_magic_link_test() {
  let model =
    AuthModel(
      "http://api.test",
      WaitingForMagicLink("test@example.com"),
      MagicLink,
    )
  let response =
    stytch_codecs.LoginOrCreateResponse(
      status_code: 200,
      request_id: "ml-100",
      user_id: "user-123",
      email_id: "some-email-42",
    )
  let #(updated, eff) =
    stytch_ui_model.update(model, ApiSentMagicLink(Ok(response)))

  assert updated.state == WaitingForMagicLink("test@example.com")
  assert eff == effect.none()
}

pub fn sign_out_test() {
  let model =
    AuthModel(
      "http://api.test",
      Authenticated(test_user("test@example.com", True), PasskeyIdle),
      MagicLink,
    )
  let #(updated, eff) = stytch_ui_model.update(model, UserClickedSignOut)

  assert updated.state == Unauthenticated("")
  assert eff != effect.none()
}

pub fn api_url_preserved_test() {
  let model = stytch_ui_model.new("http://custom.api", MagicLink)
  let #(updated, _) = stytch_ui_model.update(model, ApiConfirmsUnauthenticated)

  assert updated.api_url == "http://custom.api"
}

pub fn user_clicked_passkey_sign_in_test() {
  let model = AuthModel("http://api.test", Unauthenticated(""), MagicLink)
  let #(updated, eff) = stytch_ui_model.update(model, UserClickedPasskeySignIn)

  assert updated.state == PasskeyLoginInProgress
  assert eff != effect.none()
}

pub fn user_clicked_add_passkey_test() {
  let user = test_user("test@example.com", True)
  let model =
    AuthModel("http://api.test", Authenticated(user, PasskeyIdle), MagicLink)
  let #(updated, eff) = stytch_ui_model.update(model, UserClickedAddPasskey)

  assert updated.state == Authenticated(user, StartingPasskeyRegister)
  assert eff != effect.none()
}

pub fn api_started_passkey_register_error_test() {
  let user = test_user("test@example.com", True)
  let model =
    AuthModel(
      "http://api.test",
      Authenticated(user, StartingPasskeyRegister),
      MagicLink,
    )
  let #(updated, eff) =
    stytch_ui_model.update(
      model,
      ApiStartedPasskeyRegister(Error(rsvp.HttpError(response.new(500)))),
    )

  assert updated.state
    == Authenticated(user, PasskeyRegisterFailed("could not reach server"))
  assert eff == effect.none()
}

pub fn user_clicked_delete_passkey_test() {
  let user = test_user("test@example.com", True)
  let model =
    AuthModel("http://api.test", Authenticated(user, PasskeyIdle), MagicLink)
  let #(updated, eff) =
    stytch_ui_model.update(model, UserClickedDeletePasskey("registration-123"))

  assert updated.state == Authenticated(user, DeletingPasskey)
  assert eff != effect.none()
}

pub fn api_deleted_passkey_ok_test() {
  let user = test_user("test@example.com", True)
  let model =
    AuthModel(
      "http://api.test",
      Authenticated(user, DeletingPasskey),
      MagicLink,
    )
  let #(updated, eff) =
    stytch_ui_model.update(model, ApiDeletedPasskey(Ok(response.new(200))))

  assert updated.state == Authenticating
  assert eff != effect.none()
}

pub fn api_deleted_passkey_error_test() {
  let user = test_user("test@example.com", True)
  let model =
    AuthModel(
      "http://api.test",
      Authenticated(user, DeletingPasskey),
      MagicLink,
    )
  let #(updated, eff) =
    stytch_ui_model.update(
      model,
      ApiDeletedPasskey(Error(rsvp.HttpError(response.new(500)))),
    )

  assert updated.state
    == Authenticated(user, DeletePasskeyFailed("could not reach server"))
  assert eff == effect.none()
}

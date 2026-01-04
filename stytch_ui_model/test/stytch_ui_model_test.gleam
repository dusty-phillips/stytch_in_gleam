import gleeunit
import lustre/effect
import stytch_codecs
import stytch_ui_model.{
  ApiAuthenticatedUser, ApiConfirmsUnauthenticated, ApiSentMagicLink, AuthModel,
  Authenticated, MagicLink, Unauthenticated, UserClickedSend,
  UserClickedSignOut, UserUpdatedEmail, WaitingForMagicLink,
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
  let #(updated, eff) = stytch_ui_model.update(model, ApiConfirmsUnauthenticated)

  assert updated.state == Unauthenticated("")
  assert eff == effect.none()
}

pub fn authenticating_to_authenticated_test() {
  let model = stytch_ui_model.new("http://api.test", MagicLink)
  let user = test_user("test@example.com", True)
  let #(updated, eff) = stytch_ui_model.update(model, ApiAuthenticatedUser(user))

  assert updated.state == Authenticated(user)
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
    )
  let #(updated, _) = stytch_ui_model.update(model, ApiAuthenticatedUser(user))

  assert updated.state == Authenticated(user)
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
    AuthModel("http://api.test", WaitingForMagicLink("test@example.com"), MagicLink)
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
      Authenticated(test_user("test@example.com", True)),
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

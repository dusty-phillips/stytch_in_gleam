import gleeunit
import lustre/effect
import stytch_codecs
import stytch_ui_model.{
  ApiAuthenticatedUser, ApiConfirmsUnauthenticated, ApiSentMagicLink, AuthModel,
  Authenticated, Authenticating, Unauthenticated, UserClickedSendMagicLink,
  UserClickedSignOut, UserUpdatedEmail, WaitingForMagicLink,
}

pub fn main() {
  gleeunit.main()
}

fn init_test_model() -> String {
  "test_model_data"
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
  let model = stytch_ui_model.new("http://api.test")

  assert model
    == stytch_ui_model.AuthModel(
      "http://api.test",
      stytch_ui_model.Authenticating,
    )
}

pub fn authenticating_to_unauthenticated_test() {
  let model = stytch_ui_model.new("http://api.test")
  let #(updated, eff) =
    stytch_ui_model.update_auth(
      model,
      ApiConfirmsUnauthenticated,
      init_test_model,
    )

  assert updated.state == Unauthenticated("")
  assert eff == effect.none()
}

pub fn authenticating_to_authenticated_test() {
  let model = stytch_ui_model.new("http://api.test")
  let user = test_user("test@example.com", True)
  let #(updated, eff) =
    stytch_ui_model.update_auth(
      model,
      ApiAuthenticatedUser(user),
      init_test_model,
    )

  assert updated.state == Authenticated("test@example.com", "test_model_data")
  assert eff == effect.none()
}

pub fn authenticated_multiple_emails_test() {
  let model = stytch_ui_model.new("http://api.test")
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
  let #(updated, _) =
    stytch_ui_model.update_auth(
      model,
      ApiAuthenticatedUser(user),
      init_test_model,
    )

  assert updated.state == Authenticated("first@example.com", init_test_model())
}

pub fn user_updated_email_test() {
  let model = AuthModel("http://api.test", Unauthenticated(""))
  let #(updated, eff) =
    stytch_ui_model.update_auth(
      model,
      UserUpdatedEmail("new@example.com"),
      init_test_model,
    )

  assert updated.state == Unauthenticated("new@example.com")
  assert eff == effect.none()
}

pub fn send_magic_link_test() {
  let model = AuthModel("http://api.test", Unauthenticated("test@example.com"))
  let #(updated, eff) =
    stytch_ui_model.update_auth(
      model,
      UserClickedSendMagicLink,
      init_test_model,
    )

  assert updated.state == WaitingForMagicLink("test@example.com")
  assert eff != effect.none()
}

pub fn api_sent_magic_link_test() {
  let model =
    AuthModel("http://api.test", WaitingForMagicLink("test@example.com"))
  let response =
    stytch_codecs.MagicLinkLoginOrCreateResponse(
      status_code: 200,
      request_id: "ml-100",
      user_id: "user-123",
      email_id: "some-email-42",
    )
  let #(updated, eff) =
    stytch_ui_model.update_auth(
      model,
      ApiSentMagicLink(Ok(response)),
      init_test_model,
    )

  assert updated.state == WaitingForMagicLink("test@example.com")
  assert eff == effect.none()
}

pub fn sign_out_test() {
  let model =
    AuthModel(
      "http://api.test",
      Authenticated("test@example.com", "test_model_data"),
    )
  let #(updated, eff) =
    stytch_ui_model.update_auth(model, UserClickedSignOut, init_test_model)

  assert updated.state == Unauthenticated("")
  assert eff != effect.none()
}

pub fn api_url_preserved_test() {
  let model = stytch_ui_model.new("http://custom.api")
  let #(updated, _) =
    stytch_ui_model.update_auth(
      model,
      ApiConfirmsUnauthenticated,
      init_test_model,
    )

  assert updated.api_url == "http://custom.api"
}

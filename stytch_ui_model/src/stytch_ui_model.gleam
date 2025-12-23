import gleam/json
import gleam/list
import gleam/result
import lustre/effect
import rsvp
import stytch_codecs

pub type AuthModel {
  AuthModel(api_url: String, state: AuthState)
}

pub type AuthState {
  Authenticating
  Unauthenticated(email: String)
  WaitingForMagicLink(email: String)
  Authenticated(email: String)
}

pub type AuthMsg {
  ApiConfirmsUnauthenticated
  ApiAuthenticatedUser(user: stytch_codecs.StytchUser)
  UserUpdatedEmail(String)
  UserPressedKeyOnEmail(String)
  UserClickedSendMagicLink
  ApiSentMagicLink(
    Result(stytch_codecs.MagicLinkLoginOrCreateResponse, rsvp.Error),
  )
  UserClickedSignOut
}

pub fn new(api_url: String) {
  AuthModel(api_url, Authenticating)
}

pub fn update_auth(
  model: AuthModel,
  message: AuthMsg,
) -> #(AuthModel, effect.Effect(AuthMsg)) {
  let #(next_state, effect) = case model.state, message {
    Authenticating, ApiConfirmsUnauthenticated -> #(
      Unauthenticated(""),
      effect.none(),
    )

    Authenticating, ApiAuthenticatedUser(user) -> #(
      Authenticated(
        email: user.emails
        |> list.filter(fn(email) { email.verified })
        |> list.first
        |> result.map(fn(email) { email.email })
        |> result.unwrap(or: "Unknown Email"),
      ),
      effect.none(),
    )

    Unauthenticated(_), UserUpdatedEmail(email) -> #(
      Unauthenticated(email),
      effect.none(),
    )

    Unauthenticated(email), UserPressedKeyOnEmail(key) -> {
      case key {
        "Enter" -> #(
          WaitingForMagicLink(email),
          send_sign_in_link(model.api_url, email),
        )
        _ -> #(Unauthenticated(email), effect.none())
      }
    }

    Unauthenticated(email), UserClickedSendMagicLink -> #(
      WaitingForMagicLink(email:),
      send_sign_in_link(model.api_url, email),
    )

    WaitingForMagicLink(email), ApiSentMagicLink(Ok(_)) -> #(
      WaitingForMagicLink(email),
      effect.none(),
    )

    Authenticated(..), UserClickedSignOut -> #(
      Unauthenticated(""),
      sign_out(model.api_url),
    )

    Authenticating, _ -> #(model.state, effect.none())
    Unauthenticated(_), _ -> #(model.state, effect.none())
    Authenticated(..), _ -> #(model.state, effect.none())
    WaitingForMagicLink(_), _ -> #(model.state, effect.none())
  }

  #(AuthModel(..model, state: next_state), effect)
}

// API calls

fn send_sign_in_link(api_url: String, email: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/send_sign_in_link"

  let json =
    stytch_codecs.MagicLinkLoginOrCreateRequest(email:)
    |> stytch_codecs.magic_link_login_or_create_request_to_json

  let handler =
    rsvp.expect_json(
      stytch_codecs.magic_link_login_or_create_response_decoder(),
      ApiSentMagicLink,
    )

  rsvp.post(url, json, handler)
}

pub fn get_me(api_url: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/me"

  let handler =
    rsvp.expect_any_response(fn(result) {
      case result {
        Error(_) -> ApiConfirmsUnauthenticated
        Ok(response) if response.status >= 200 && response.status < 300 -> {
          case
            response.body
            |> json.parse(stytch_codecs.stytch_user_decoder())
          {
            Error(_) -> ApiConfirmsUnauthenticated
            Ok(user) -> ApiAuthenticatedUser(user)
          }
        }
        Ok(_) -> ApiConfirmsUnauthenticated
      }
    })

  rsvp.get(url, handler)
}

fn sign_out(api_url: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/sign_out"

  let handler = rsvp.expect_ok_response(fn(_) { ApiConfirmsUnauthenticated })

  rsvp.get(url, handler)
}

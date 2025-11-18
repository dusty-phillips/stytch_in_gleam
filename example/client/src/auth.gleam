import gleam/json
import gleam/list
import gleam/result
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import stytch_codecs

pub type AuthModel(model) {
  Authenticating
  Unauthenticated(email: String)
  WaitingForMagicLink(email: String)
  Authenticated(email: String, model: model)
}

pub type AuthMsg {
  ApiConfirmsUnauthenticated
  ApiAuthenticatedUser(user: stytch_codecs.StytchUser)
  UserUpdatedEmail(String)
  UserClickedSendMagicLink
  ApiSentMagicLink(
    Result(stytch_codecs.MagicLinkLoginOrCreateResponse, rsvp.Error),
  )
  UserClickedSignOut
}

pub fn update_auth(
  model: AuthModel(model),
  message: AuthMsg,
  init_authenticated: fn() -> model,
) -> #(AuthModel(model), effect.Effect(AuthMsg)) {
  case model, message {
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
        model: init_authenticated(),
      ),
      effect.none(),
    )

    Unauthenticated(_), UserUpdatedEmail(email) -> #(
      Unauthenticated(email),
      effect.none(),
    )

    Unauthenticated(email), UserClickedSendMagicLink -> #(
      WaitingForMagicLink(email:),
      send_sign_in_link(email),
    )

    WaitingForMagicLink(email), ApiSentMagicLink(Ok(_)) -> #(
      WaitingForMagicLink(email),
      effect.none(),
    )

    Authenticated(..), UserClickedSignOut -> #(Unauthenticated(""), sign_out())

    Authenticating, _ -> #(model, effect.none())
    Unauthenticated(_), _ -> #(model, effect.none())
    Authenticated(..), _ -> #(model, effect.none())
    WaitingForMagicLink(_), _ -> #(model, effect.none())
  }
}

// API calls

fn send_sign_in_link(email: String) -> effect.Effect(AuthMsg) {
  let url = "http://localhost:3000/api/send_sign_in_link"

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

pub fn get_me() -> effect.Effect(AuthMsg) {
  let url = "http://localhost:3000/api/me"

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

fn sign_out() -> effect.Effect(AuthMsg) {
  let url = "http://localhost:3000/api/sign_out"

  let handler = rsvp.expect_ok_response(fn(_) { ApiConfirmsUnauthenticated })

  rsvp.get(url, handler)
}

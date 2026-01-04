import gleam/http/response
import gleam/json
import lustre/effect
import rsvp
import stytch_codecs

pub type AuthModel {
  AuthModel(api_url: String, state: AuthState, method: AuthenticationMethod)
}

pub type AuthenticationMethod {
  MagicLink
  Passcode
}

pub type AuthState {
  Authenticating

  Unauthenticated(email: String)

  WaitingForMagicLink(email: String)
  SendingPasscodeEmail(email: String)
  WaitingForPasscode(email: String, email_id: String, passcode: String)
  VerifyingPasscode(email: String)

  Authenticated(user: stytch_codecs.StytchUser)
}

pub type AuthMsg {
  ApiConfirmsUnauthenticated
  ApiAuthenticatedUser(user: stytch_codecs.StytchUser)
  UserUpdatedEmail(String)
  UserPressedKeyOnEmail(String)
  UserClickedSend
  ApiSentMagicLink(Result(stytch_codecs.LoginOrCreateResponse, rsvp.Error))
  ApiSentPasscode(Result(stytch_codecs.LoginOrCreateResponse, rsvp.Error))
  UserUpdatedPasscode(String)
  UserClickedPasscodeSend
  ApiVerifiedPasscode(Result(response.Response(String), rsvp.Error))
  UserClickedSignOut
}

pub fn new(api_url: String, method: AuthenticationMethod) {
  AuthModel(api_url, Authenticating, method)
}

pub fn update(
  model: AuthModel,
  message: AuthMsg,
) -> #(AuthModel, effect.Effect(AuthMsg)) {
  let #(next_state, effect) = case model.state {
    Authenticating -> update_authenticating(message)
    Unauthenticated(email) -> update_unauthenticated(model, email, message)
    WaitingForMagicLink(email) -> update_magic_link(email, message)
    SendingPasscodeEmail(email) -> update_sending_passcode_email(email, message)
    WaitingForPasscode(email, email_id, passcode) ->
      update_waiting_for_passcode(
        model.api_url,
        email,
        email_id,
        passcode,
        message,
      )
    VerifyingPasscode(email) ->
      update_verifying_passcode(model.api_url, email, message)
    Authenticated(user) -> update_authenticated(model.api_url, user, message)
  }

  #(AuthModel(..model, state: next_state), effect)
}

pub fn is_authenticated(model: AuthModel) -> Bool {
  case model {
    AuthModel(state: Authenticated(_), ..) -> True
    _ -> False
  }
}

fn update_authenticating(msg: AuthMsg) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiConfirmsUnauthenticated -> #(Unauthenticated(""), effect.none())
    ApiAuthenticatedUser(user) -> #(Authenticated(user), effect.none())

    UserUpdatedEmail(_)
    | UserPressedKeyOnEmail(_)
    | UserClickedSend
    | ApiSentMagicLink(_)
    | ApiSentPasscode(_)
    | UserUpdatedPasscode(_)
    | UserClickedPasscodeSend
    | ApiVerifiedPasscode(_)
    | UserClickedSignOut -> #(Authenticating, effect.none())
  }
}

fn update_unauthenticated(
  model: AuthModel,
  email: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    UserUpdatedEmail(email) -> #(Unauthenticated(email), effect.none())

    UserPressedKeyOnEmail(key) -> {
      case key {
        "Enter" -> user_confirmed_email(model, email)
        _ -> #(Unauthenticated(email), effect.none())
      }
    }

    UserClickedSend -> user_confirmed_email(model, email)

    ApiConfirmsUnauthenticated
    | ApiAuthenticatedUser(_)
    | ApiSentMagicLink(_)
    | ApiSentPasscode(_)
    | UserUpdatedPasscode(_)
    | UserClickedPasscodeSend
    | ApiVerifiedPasscode(_)
    | UserClickedSignOut -> #(Unauthenticated(email), effect.none())
  }
}

fn update_magic_link(
  email: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiSentMagicLink(Ok(_)) -> #(WaitingForMagicLink(email), effect.none())

    ApiSentMagicLink(Error(_)) -> todo

    ApiConfirmsUnauthenticated
    | ApiAuthenticatedUser(_)
    | UserUpdatedEmail(_)
    | UserPressedKeyOnEmail(_)
    | UserClickedSend
    | ApiSentPasscode(_)
    | UserUpdatedPasscode(_)
    | UserClickedPasscodeSend
    | ApiVerifiedPasscode(_)
    | UserClickedSignOut -> #(WaitingForMagicLink(email), effect.none())
  }
}

fn update_sending_passcode_email(
  email: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiSentPasscode(Ok(response)) -> #(
      WaitingForPasscode(email, response.email_id, ""),
      effect.none(),
    )

    ApiSentPasscode(Error(_)) -> todo as "error from passcode endpoint"

    ApiConfirmsUnauthenticated
    | ApiAuthenticatedUser(_)
    | UserUpdatedEmail(_)
    | UserPressedKeyOnEmail(_)
    | UserClickedSend
    | ApiSentMagicLink(_)
    | UserUpdatedPasscode(_)
    | UserClickedPasscodeSend
    | ApiVerifiedPasscode(_)
    | UserClickedSignOut -> #(SendingPasscodeEmail(email), effect.none())
  }
}

fn update_waiting_for_passcode(
  api_url: String,
  email: String,
  email_id: String,
  passcode: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    UserUpdatedPasscode(new_passcode) -> #(
      WaitingForPasscode(email, email_id, new_passcode),
      effect.none(),
    )

    UserClickedPasscodeSend -> #(
      VerifyingPasscode(email),
      verify_passcode(api_url, email_id, passcode),
    )

    ApiConfirmsUnauthenticated
    | ApiAuthenticatedUser(_)
    | UserUpdatedEmail(_)
    | UserPressedKeyOnEmail(_)
    | UserClickedSend
    | ApiSentMagicLink(_)
    | ApiSentPasscode(_)
    | ApiVerifiedPasscode(_)
    | UserClickedSignOut -> #(
      WaitingForPasscode(email, email_id, passcode),
      effect.none(),
    )
  }
}

fn update_verifying_passcode(
  api_url: String,
  email: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiVerifiedPasscode(Ok(_)) -> #(Authenticating, get_me(api_url))

    ApiVerifiedPasscode(Error(_)) -> todo

    ApiConfirmsUnauthenticated
    | ApiAuthenticatedUser(_)
    | UserUpdatedEmail(_)
    | UserPressedKeyOnEmail(_)
    | UserClickedSend
    | ApiSentMagicLink(_)
    | ApiSentPasscode(_)
    | UserUpdatedPasscode(_)
    | UserClickedPasscodeSend
    | UserClickedSignOut -> #(VerifyingPasscode(email), effect.none())
  }
}

fn update_authenticated(
  api_url: String,
  user: stytch_codecs.StytchUser,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    UserClickedSignOut -> #(Unauthenticated(""), sign_out(api_url))
    ApiAuthenticatedUser(updated_user) -> #(
      Authenticated(updated_user),
      effect.none(),
    )
    ApiConfirmsUnauthenticated -> #(Unauthenticated(""), effect.none())

    UserUpdatedEmail(_)
    | UserPressedKeyOnEmail(_)
    | UserClickedSend
    | ApiSentMagicLink(_)
    | ApiSentPasscode(_)
    | UserUpdatedPasscode(_)
    | UserClickedPasscodeSend
    | ApiVerifiedPasscode(_) -> #(Authenticated(user), effect.none())
  }
}

fn user_confirmed_email(
  model: AuthModel,
  email: String,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case model.method {
    MagicLink -> #(
      WaitingForMagicLink(email),
      send_sign_in_link(model.api_url, email),
    )
    Passcode -> #(
      SendingPasscodeEmail(email),
      send_passcode(model.api_url, email),
    )
  }
}

// API calls

fn send_sign_in_link(api_url: String, email: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/send_sign_in_link"

  let json =
    stytch_codecs.MagicLinkLoginOrCreateRequest(email:)
    |> stytch_codecs.magic_link_login_or_create_request_to_json

  let handler =
    rsvp.expect_json(
      stytch_codecs.login_or_create_response_decoder(),
      ApiSentMagicLink,
    )

  rsvp.post(url, json, handler)
}

fn send_passcode(api_url: String, email: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/send_passcode"

  let json =
    stytch_codecs.PasscodeLoginOrCreateRequest(email:)
    |> stytch_codecs.passcode_login_or_create_request_to_json

  let handler =
    rsvp.expect_json(
      stytch_codecs.login_or_create_response_decoder(),
      ApiSentPasscode,
    )

  rsvp.post(url, json, handler)
}

fn verify_passcode(
  api_url: String,
  email_id: String,
  passcode: String,
) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/verify_passcode"

  let json =
    stytch_codecs.PasscodeAuthenticateRequest(
      method_id: email_id,
      code: passcode,
      session_duration_minutes: 7200,
    )
    |> stytch_codecs.passcode_authenticate_request_to_json

  let handler = rsvp.expect_ok_response(ApiVerifiedPasscode)

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

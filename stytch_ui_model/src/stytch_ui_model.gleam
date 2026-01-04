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
  PasscodeState(PasscodeState)

  Authenticated(user: stytch_codecs.StytchUser)
}

pub type AuthMsg {
  AuthenticatingMsg(AuthenticatingMsg)
  UnauthenticatedMsg(UnauthenticatedMsg)
  MagicLinkMsg(MagicLinkMsg)
  PasscodeMsg(PasscodeMsg)
  AuthenticatedMsg(AuthenticatedMsg)
}

pub type AuthenticatingMsg {
  ApiConfirmsUnauthenticated
  ApiAuthenticatedUser(user: stytch_codecs.StytchUser)
}

pub type UnauthenticatedMsg {
  UserUpdatedEmail(String)
  UserPressedKeyOnEmail(String)
  UserClickedSend
}

pub type AuthenticatedMsg {
  UserClickedSignOut
}

pub type MagicLinkMsg {
  ApiSentMagicLink(Result(stytch_codecs.LoginOrCreateResponse, rsvp.Error))
}

pub type PasscodeState {
  SendingPasscodeEmail(email: String)
  WaitingForPasscode(email: String, email_id: String, passcode: String)
  VerifyingPasscode(email: String)
}

pub type PasscodeMsg {
  SendingPasscodeEmailMsg(SendingPasscodeEmailMsg)
  WaitingForPasscodeMsg(WaitingForPasscodeMsg)
  VerifyingPasscodeMsg(VerifyingPasscodeMsg)
}

pub type SendingPasscodeEmailMsg {
  ApiSentPasscode(Result(stytch_codecs.LoginOrCreateResponse, rsvp.Error))
}

pub type WaitingForPasscodeMsg {
  UserUpdatedPasscode(String)
  UserClickedPasscodeSend
}

pub type VerifyingPasscodeMsg {
  ApiVerifiedPasscode(Result(response.Response(String), rsvp.Error))
}

pub fn new(api_url: String, method: AuthenticationMethod) {
  AuthModel(api_url, Authenticating, method)
}

pub fn update(
  model: AuthModel,
  message: AuthMsg,
) -> #(AuthModel, effect.Effect(AuthMsg)) {
  let #(next_state, effect) = case model.state, message {
    Authenticating, AuthenticatingMsg(msg) -> update_authenticating(msg)
    Authenticating, _ -> #(model.state, effect.none())

    Unauthenticated(email), UnauthenticatedMsg(msg) ->
      update_unauthenticated(model, email, msg)
    Unauthenticated(_), _ -> #(model.state, effect.none())

    WaitingForMagicLink(email), MagicLinkMsg(msg) ->
      update_magic_link(email, msg)
    WaitingForMagicLink(_), _ -> #(model.state, effect.none())

    PasscodeState(state), PasscodeMsg(msg) ->
      update_passcode(model.api_url, state, msg)
    PasscodeState(_), _ -> #(model.state, effect.none())

    Authenticated(_), AuthenticatedMsg(msg) ->
      update_authenticated(model.api_url, msg)
    Authenticated(_), _ -> #(model.state, effect.none())
  }

  #(AuthModel(..model, state: next_state), effect)
}

pub fn is_authenticated(model: AuthModel) -> Bool {
  case model {
    AuthModel(state: Authenticated(_), ..) -> True
    _ -> False
  }
}

fn update_authenticating(
  msg: AuthenticatingMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiConfirmsUnauthenticated -> #(Unauthenticated(""), effect.none())
    ApiAuthenticatedUser(user) -> #(Authenticated(user), effect.none())
  }
}

fn update_unauthenticated(
  model: AuthModel,
  email: String,
  msg: UnauthenticatedMsg,
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
  }
}

fn update_magic_link(
  email: String,
  msg: MagicLinkMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiSentMagicLink(Ok(_)) -> #(WaitingForMagicLink(email), effect.none())
    ApiSentMagicLink(Error(_)) -> todo
  }
}

fn update_passcode(
  api_url: String,
  passcode_state: PasscodeState,
  msg: PasscodeMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  echo msg
  case passcode_state, msg {
    SendingPasscodeEmail(email), SendingPasscodeEmailMsg(msg) ->
      update_sending_passcode_email(email, msg)
    SendingPasscodeEmail(_), _ -> #(
      PasscodeState(passcode_state),
      effect.none(),
    )

    WaitingForPasscode(email, email_id, passcode), WaitingForPasscodeMsg(msg) ->
      update_waiting_for_passcode(api_url, email, email_id, passcode, msg)

    WaitingForPasscode(..), _ -> #(PasscodeState(passcode_state), effect.none())

    VerifyingPasscode(_), VerifyingPasscodeMsg(msg) ->
      update_verifying_passcode(api_url, msg)
    VerifyingPasscode(_), _ -> #(PasscodeState(passcode_state), effect.none())
  }
}

fn update_sending_passcode_email(
  email: String,
  msg: SendingPasscodeEmailMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  echo msg
  case msg {
    ApiSentPasscode(Ok(response)) -> #(
      PasscodeState(WaitingForPasscode(email, response.email_id, "")),
      effect.none(),
    )
    ApiSentPasscode(Error(_)) -> todo as "error from passcode endpoint"
  }
}

fn update_waiting_for_passcode(
  api_url: String,
  email: String,
  email_id: String,
  passcode: String,
  msg: WaitingForPasscodeMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    UserUpdatedPasscode(new_passcode) -> #(
      PasscodeState(WaitingForPasscode(email, email_id, new_passcode)),
      effect.none(),
    )

    UserClickedPasscodeSend -> #(
      PasscodeState(VerifyingPasscode(email)),
      verify_passcode(api_url, email_id, passcode),
    )
  }
}

fn update_verifying_passcode(
  api_url: String,
  msg: VerifyingPasscodeMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiVerifiedPasscode(Ok(_)) -> #(Authenticating, get_me(api_url))
    ApiVerifiedPasscode(Error(_)) -> todo
  }
}

fn update_authenticated(
  api_url: String,
  msg: AuthenticatedMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    UserClickedSignOut -> #(Unauthenticated(""), sign_out(api_url))
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
      PasscodeState(SendingPasscodeEmail(email)),
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

  rsvp.post(url, json, handler) |> effect.map(MagicLinkMsg)
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
  |> effect.map(fn(message) { PasscodeMsg(SendingPasscodeEmailMsg(message)) })
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
  |> effect.map(fn(message) { PasscodeMsg(VerifyingPasscodeMsg(message)) })
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

  rsvp.get(url, handler) |> effect.map(AuthenticatingMsg)
}

fn sign_out(api_url: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/sign_out"

  let handler = rsvp.expect_ok_response(fn(_) { ApiConfirmsUnauthenticated })

  rsvp.get(url, handler) |> effect.map(AuthenticatingMsg)
}

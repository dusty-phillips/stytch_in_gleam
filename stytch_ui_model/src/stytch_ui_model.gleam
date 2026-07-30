import gleam/http/response
import gleam/javascript/promise
import gleam/json
import gleam/result
import lustre/effect
import plinth/browser/credentials
import plinth/browser/credentials/public_key
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

  PasskeyLoginInProgress

  Authenticated(user: stytch_codecs.StytchUser, passkey_state: PasskeyState)
}

/// Status of an in-flight passkey registration for an authenticated user.
/// The list of already-registered passkeys is available on the user as
/// `user.webauthn_registrations`.
pub type PasskeyState {
  PasskeyIdle
  StartingPasskeyRegister
  CreatingPasskeyCredential
  FinishingPasskeyRegister
  PasskeyRegisterFailed(reason: String)
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

  UserClickedPasskeySignIn
  ApiStartedPasskeyLogin(
    Result(stytch_codecs.PasskeyAuthenticateStartResponse, rsvp.Error),
  )
  BrowserGotPasskeyCredential(Result(String, String))
  ApiFinishedPasskeyLogin(
    Result(stytch_codecs.PasskeySessionResponse, rsvp.Error),
  )

  UserClickedAddPasskey
  ApiStartedPasskeyRegister(
    Result(stytch_codecs.PasskeyRegisterStartResponse, rsvp.Error),
  )
  BrowserCreatedPasskeyCredential(Result(String, String))
  ApiFinishedPasskeyRegister(
    Result(stytch_codecs.PasskeySessionResponse, rsvp.Error),
  )

  UserClickedSignOut
}

pub fn new(api_url: String, method: AuthenticationMethod) -> AuthModel {
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
    PasskeyLoginInProgress ->
      update_passkey_login_in_progress(model.api_url, message)
    Authenticated(user, passkey_state) ->
      update_authenticated(model.api_url, user, passkey_state, message)
  }

  #(AuthModel(..model, state: next_state), effect)
}

pub fn is_authenticated(model: AuthModel) -> Bool {
  case model {
    AuthModel(state: Authenticated(..), ..) -> True
    _ -> False
  }
}

fn update_authenticating(msg: AuthMsg) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiConfirmsUnauthenticated -> #(Unauthenticated(""), effect.none())
    ApiAuthenticatedUser(user) -> #(
      Authenticated(user, PasskeyIdle),
      effect.none(),
    )

    _ -> #(Authenticating, effect.none())
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

    UserClickedPasskeySignIn -> #(
      PasskeyLoginInProgress,
      start_passkey_login(model.api_url),
    )

    _ -> #(Unauthenticated(email), effect.none())
  }
}

fn update_magic_link(
  email: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiSentMagicLink(Ok(_)) -> #(WaitingForMagicLink(email), effect.none())

    ApiSentMagicLink(Error(_)) -> #(Unauthenticated(email), effect.none())

    _ -> #(WaitingForMagicLink(email), effect.none())
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

    ApiSentPasscode(Error(_)) -> #(Unauthenticated(email), effect.none())

    _ -> #(SendingPasscodeEmail(email), effect.none())
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

    _ -> #(WaitingForPasscode(email, email_id, passcode), effect.none())
  }
}

fn update_verifying_passcode(
  api_url: String,
  email: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiVerifiedPasscode(Ok(_)) -> #(Authenticating, get_me(api_url))

    ApiVerifiedPasscode(Error(_)) -> #(Unauthenticated(email), effect.none())

    _ -> #(VerifyingPasscode(email), effect.none())
  }
}

fn update_passkey_login_in_progress(
  api_url: String,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    ApiStartedPasskeyLogin(Ok(response)) -> #(
      PasskeyLoginInProgress,
      get_passkey_credential(response.public_key_credential_request_options),
    )
    ApiStartedPasskeyLogin(Error(_)) -> #(Unauthenticated(""), effect.none())

    BrowserGotPasskeyCredential(Ok(credential_json)) -> #(
      PasskeyLoginInProgress,
      finish_passkey_login(api_url, credential_json),
    )
    BrowserGotPasskeyCredential(Error(_)) -> #(
      Unauthenticated(""),
      effect.none(),
    )

    ApiFinishedPasskeyLogin(Ok(response)) -> #(
      Authenticated(response.user, PasskeyIdle),
      effect.none(),
    )
    ApiFinishedPasskeyLogin(Error(_)) -> #(Unauthenticated(""), effect.none())

    _ -> #(PasskeyLoginInProgress, effect.none())
  }
}

fn update_authenticated(
  api_url: String,
  user: stytch_codecs.StytchUser,
  passkey_state: PasskeyState,
  msg: AuthMsg,
) -> #(AuthState, effect.Effect(AuthMsg)) {
  case msg {
    UserClickedSignOut -> #(Unauthenticated(""), sign_out(api_url))
    ApiAuthenticatedUser(updated_user) -> #(
      Authenticated(updated_user, passkey_state),
      effect.none(),
    )
    ApiConfirmsUnauthenticated -> #(Unauthenticated(""), effect.none())

    UserClickedAddPasskey -> #(
      Authenticated(user, StartingPasskeyRegister),
      start_register_passkey(api_url),
    )

    ApiStartedPasskeyRegister(Ok(response)) -> #(
      Authenticated(user, CreatingPasskeyCredential),
      create_passkey_credential(response.public_key_credential_creation_options),
    )
    ApiStartedPasskeyRegister(Error(_)) -> #(
      Authenticated(user, PasskeyRegisterFailed("could not reach server")),
      effect.none(),
    )

    BrowserCreatedPasskeyCredential(Ok(credential_json)) -> #(
      Authenticated(user, FinishingPasskeyRegister),
      finish_register_passkey(api_url, credential_json),
    )
    BrowserCreatedPasskeyCredential(Error(reason)) -> #(
      Authenticated(user, PasskeyRegisterFailed(reason)),
      effect.none(),
    )

    ApiFinishedPasskeyRegister(Ok(response)) -> #(
      Authenticated(response.user, PasskeyIdle),
      effect.none(),
    )
    ApiFinishedPasskeyRegister(Error(_)) -> #(
      Authenticated(user, PasskeyRegisterFailed("could not reach server")),
      effect.none(),
    )

    _ -> #(Authenticated(user, passkey_state), effect.none())
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

// Note: passkey requests deliberately carry no user_id, domain, or session
// duration. The server derives identity from the session cookie and owns
// domain and session policy; the browser only transports the WebAuthn
// credential between Stytch and the authenticator.

fn start_register_passkey(api_url: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/start_register_passkey"

  let handler =
    rsvp.expect_json(
      stytch_codecs.passkey_register_start_response_decoder(),
      ApiStartedPasskeyRegister,
    )

  rsvp.post(url, json.object([]), handler)
}

fn finish_register_passkey(
  api_url: String,
  credential_json: String,
) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/finish_register_passkey"

  let json =
    stytch_codecs.PasskeyCredentialPayload(public_key_credential: credential_json)
    |> stytch_codecs.passkey_credential_payload_to_json

  let handler =
    rsvp.expect_json(
      stytch_codecs.passkey_session_response_decoder(),
      ApiFinishedPasskeyRegister,
    )

  rsvp.post(url, json, handler)
}

fn start_passkey_login(api_url: String) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/start_passkey_login"

  let handler =
    rsvp.expect_json(
      stytch_codecs.passkey_authenticate_start_response_decoder(),
      ApiStartedPasskeyLogin,
    )

  rsvp.post(url, json.object([]), handler)
}

fn finish_passkey_login(
  api_url: String,
  credential_json: String,
) -> effect.Effect(AuthMsg) {
  let url = api_url <> "/passkey_login"

  let json =
    stytch_codecs.PasskeyCredentialPayload(public_key_credential: credential_json)
    |> stytch_codecs.passkey_credential_payload_to_json

  let handler =
    rsvp.expect_json(
      stytch_codecs.passkey_session_response_decoder(),
      ApiFinishedPasskeyLogin,
    )

  rsvp.post(url, json, handler)
}

fn create_passkey_credential(
  creation_options_json: String,
) -> effect.Effect(AuthMsg) {
  browser_passkey_credential(
    creation_options_json,
    parse_creation_options,
    public_key.do_create,
    BrowserCreatedPasskeyCredential,
  )
}

fn get_passkey_credential(
  request_options_json: String,
) -> effect.Effect(AuthMsg) {
  browser_passkey_credential(
    request_options_json,
    parse_request_options,
    public_key.do_get,
    BrowserGotPasskeyCredential,
  )
}

/// Run a WebAuthn browser ceremony (credential creation or request): parse the
/// options Stytch returned, invoke the browser API via plinth, and hand the
/// serialized credential (or an error message) to `to_msg`.
fn browser_passkey_credential(
  options_json: String,
  parse: fn(String) -> Result(options, String),
  ceremony: fn(credentials.CredentialsContainer, options) ->
    promise.Promise(Result(public_key.Credential(c), String)),
  to_msg: fn(Result(String, String)) -> AuthMsg,
) -> effect.Effect(AuthMsg) {
  effect.from(fn(dispatch) {
    case parse(options_json) {
      Error(reason) -> dispatch(to_msg(Error(reason)))
      Ok(options) ->
        case credentials.from_navigator() {
          Error(Nil) ->
            dispatch(to_msg(Error("WebAuthn is not available in this browser")))
          Ok(container) -> {
            let _promise =
              ceremony(container, options)
              |> promise.map(fn(result) {
                result
                |> result.map(fn(credential) {
                  credential |> public_key.to_json |> json.to_string
                })
                |> to_msg
                |> dispatch
              })
            Nil
          }
        }
    }
  })
}

fn parse_creation_options(
  options_json: String,
) -> Result(public_key.NativeCreationOptions, String) {
  use parsed <- result.try(parse_json_string(options_json))
  public_key.parse_creation_options_from_json(parsed)
}

fn parse_request_options(
  options_json: String,
) -> Result(public_key.NativeRequestOptions, String) {
  use parsed <- result.try(parse_json_string(options_json))
  public_key.parse_request_options_from_json(parsed)
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

// Browser FFI (glue only; the WebAuthn ceremony lives in plinth)

@external(javascript, "./stytch_ui_model_ffi.mjs", "parseJson")
fn parse_json_string(json_string: String) -> Result(json.Json, String)

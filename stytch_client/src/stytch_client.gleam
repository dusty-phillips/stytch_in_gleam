import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/result
import stytch_codecs

// Types
/// Configured stytch client to connect to the stytch service.
///
/// The client secret should likely come from an environment variable; it needs
/// to be protected.
pub opaque type StytchClient {
  StytchClient(
    project_id: String,
    secret: String,
    environment: StytchEnvironment,
  )
}

/// Various error types that may occur while processing Stytch responses
pub type StytchError {
  HttpcError(httpc.HttpError)
  DecodeError(decode.DecodeError)
  JsonError(json.DecodeError)
  ClientError(stytch_codecs.StytchClientError)
}

/// Stytch has two possible environments.
/// This type enumerates them.
type StytchEnvironment {
  Test
  Live
}

/// Consturct a new StytchClient given a projcet_id and sercet.
/// Stytch encodes the environment in the project_id so we can connect
/// to the correct service when it is called
pub fn new(project_id: String, secret: String) -> StytchClient {
  case project_id {
    "project-test-" <> _ ->
      StytchClient(project_id:, secret:, environment: Test)
    _ -> StytchClient(project_id:, secret:, environment: Live)
  }
}

/// Send a magic link to the (typically user-provided) e-mail address.
///
/// This works whether or not the user has previously logged in.
pub fn magic_link_login_or_create(
  client: StytchClient,
  email: String,
) -> Result(stytch_codecs.LoginOrCreateResponse, StytchError) {
  let data =
    [#("email", json.string(email))]
    |> json.object()

  let request =
    make_stytch_request(
      client,
      http.Post,
      "/v1/magic_links/email/login_or_create",
      data,
    )

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )

  parse_stytch_response(
    response,
    stytch_codecs.login_or_create_response_decoder(),
  )
}

/// Authenticate a token returned from Stytch during a magic link redirect flow.
pub fn magic_link_authenticate(
  client: StytchClient,
  token: String,
  session_duration_minutes: Int,
) -> Result(stytch_codecs.AuthenticateResponse, StytchError) {
  let data =
    stytch_codecs.TokenAuthenticateRequest(token, session_duration_minutes)
    |> stytch_codecs.token_authenticate_request_to_json()

  let request =
    make_stytch_request(client, http.Post, "/v1/magic_links/authenticate", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )

  parse_stytch_response(response, stytch_codecs.authenticate_response_decoder())
}

/// Create or log in a user using passcode authentication.
///
/// Arguably more secure than magic link auth as it avoids sending an
/// un-verified e-mail to the user.
pub fn passcode_login_or_create(
  client: StytchClient,
  email: String,
) -> Result(stytch_codecs.LoginOrCreateResponse, StytchError) {
  let data =
    [#("email", json.string(email))]
    |> json.object()

  let request =
    make_stytch_request(
      client,
      http.Post,
      "/v1/otps/email/login_or_create",
      data,
    )

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )

  parse_stytch_response(
    response,
    stytch_codecs.login_or_create_response_decoder(),
  )
}

/// Authenticate the passcode the user entered and pass it to stytch client.
pub fn passcode_authenticate(
  client: StytchClient,
  code: String,
  method_id: String,
  session_duration_minutes: Int,
) -> Result(stytch_codecs.AuthenticateResponse, StytchError) {
  let data =
    stytch_codecs.PasscodeAuthenticateRequest(
      code,
      method_id,
      session_duration_minutes,
    )
    |> stytch_codecs.passcode_authenticate_request_to_json()

  let request =
    make_stytch_request(client, http.Post, "/v1/otps/authenticate", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )

  parse_stytch_response(response, stytch_codecs.authenticate_response_decoder())
}

/// Start registration of a webauthn passkey for an identified user.
///
/// The user_id must be authenticated already using one of the e-mail verified
/// options.
pub fn passkey_registration_start(
  client: StytchClient,
  request_data: stytch_codecs.PasskeyRegisterStartRequest,
) -> Result(stytch_codecs.PasskeyRegisterStartResponse, StytchError) {
  let data =
    request_data |> stytch_codecs.passkey_register_start_request_to_json

  let request =
    make_stytch_request(client, http.Post, "/v1/webauthn/register/start", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )
  parse_stytch_response(
    response,
    stytch_codecs.passkey_register_start_response_decoder(),
  )
}

/// Complete registration of a webauthn passkey, passing the credential the
/// browser created with `navigator.credentials.create()` as a JSON string.
pub fn passkey_registration_finish(
  client: StytchClient,
  request_data: stytch_codecs.PasskeyRegisterFinishRequest,
) -> Result(stytch_codecs.PasskeySessionResponse, StytchError) {
  let data =
    request_data |> stytch_codecs.passkey_register_finish_request_to_json

  let request =
    make_stytch_request(client, http.Post, "/v1/webauthn/register", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )
  parse_stytch_response(
    response,
    stytch_codecs.passkey_session_response_decoder(),
  )
}

/// Start passkey authentication for an unknown user. The browser's passkey
/// picker identifies the user via discoverable credentials, so no user_id
/// is required.
pub fn passkey_authenticate_start(
  client: StytchClient,
  request_data: stytch_codecs.PasskeyAuthenticateStartRequest,
) -> Result(stytch_codecs.PasskeyAuthenticateStartResponse, StytchError) {
  let data =
    request_data |> stytch_codecs.passkey_authenticate_start_request_to_json

  let request =
    make_stytch_request(
      client,
      http.Post,
      "/v1/webauthn/authenticate/start",
      data,
    )

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )
  parse_stytch_response(
    response,
    stytch_codecs.passkey_authenticate_start_response_decoder(),
  )
}

/// Complete passkey authentication, passing the credential the browser
/// returned from `navigator.credentials.get()` as a JSON string.
pub fn passkey_authenticate(
  client: StytchClient,
  request_data: stytch_codecs.PasskeyAuthenticateRequest,
) -> Result(stytch_codecs.PasskeySessionResponse, StytchError) {
  let data = request_data |> stytch_codecs.passkey_authenticate_request_to_json

  let request =
    make_stytch_request(client, http.Post, "/v1/webauthn/authenticate", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )
  parse_stytch_response(
    response,
    stytch_codecs.passkey_session_response_decoder(),
  )
}

/// Delete a passkey (WebAuthn registration) for a user.
///
/// The user should already be authenticated; the caller is responsible for
/// confirming the registration belongs to the current user.
pub fn passkey_delete(
  client: StytchClient,
  webauthn_registration_id: String,
) -> Result(stytch_codecs.DeleteWebAuthnResponse, StytchError) {
  let request =
    make_stytch_request(
      client,
      http.Delete,
      "/v1/webauthn/" <> webauthn_registration_id,
      json.object([]),
    )

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )
  parse_stytch_response(
    response,
    stytch_codecs.delete_webauthn_response_decoder(),
  )
}

/// Authenticate a session token previously returned from a passcode or magic
/// link authentication flow.
pub fn session_authenticate(
  client: StytchClient,
  token: String,
  session_duration_minutes: Int,
) -> Result(stytch_codecs.SessionAuthenticateResponse, StytchError) {
  let data =
    stytch_codecs.SessionTokenAuthenticateRequest(
      token,
      session_duration_minutes,
    )
    |> stytch_codecs.session_token_authenticate_request_to_json()

  let request =
    make_stytch_request(client, http.Post, "/v1/sessions/authenticate", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )

  parse_stytch_response(
    response,
    stytch_codecs.session_authenticate_response_decoder(),
  )
}

/// Revoke a session token so it can't be used to sign in again.
///
/// Used for signing a user out.
pub fn session_revoke(
  client: StytchClient,
  token: String,
) -> Result(stytch_codecs.SessionRevokeResponse, StytchError) {
  let data =
    stytch_codecs.SessionRevokeRequest(token)
    |> stytch_codecs.session_revoke_request_to_json()

  let request =
    make_stytch_request(client, http.Post, "/v1/sessions/revoke", data)

  use response <- result.try(
    httpc.send(request) |> result.map_error(HttpcError),
  )

  parse_stytch_response(
    response,
    stytch_codecs.session_revoke_response_decoder(),
  )
}

// Internal Helpers
fn make_stytch_request(
  client: StytchClient,
  method: http.Method,
  path: String,
  data: json.Json,
) -> request.Request(String) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(client_to_host(client))
  |> request.set_path(path)
  |> request.set_method(method)
  |> add_basic_auth(client)
  |> request.set_header("Content-Type", "application/json")
  |> request.set_body(json.to_string(data))
}

fn client_to_host(stytch_client: StytchClient) -> String {
  case stytch_client.environment {
    Test -> "test.stytch.com"
    Live -> "api.stytch.com"
  }
}

@internal
pub fn add_basic_auth(
  req: request.Request(body),
  stytch_client: StytchClient,
) -> request.Request(body) {
  let credentials = stytch_client.project_id <> ":" <> stytch_client.secret
  let encoded = bit_array.base64_encode(<<credentials:utf8>>, True)

  request.set_header(req, "authorization", "Basic " <> encoded)
}

@internal
pub fn parse_stytch_response(
  response: response.Response(String),
  success_decoder: decode.Decoder(data),
) -> Result(data, StytchError) {
  case response.status {
    200 -> parse_stytch_success(response, success_decoder)
    _ ->
      // Todo: 100 and 300 error codes will be unhappy but what would one do with them?
      parse_stytch_error(response)
  }
}

fn parse_stytch_success(
  response: response.Response(String),
  decoder: decode.Decoder(data),
) -> Result(data, StytchError) {
  response.body
  |> json.parse(using: decoder)
  |> result.map_error(JsonError)
}

fn parse_stytch_error(
  response: response.Response(String),
) -> Result(a, StytchError) {
  response.body
  |> json.parse(using: stytch_codecs.stytch_client_error_decoder())
  |> result.map_error(JsonError)
  |> result.try(fn(parse_ok) { Error(ClientError(parse_ok)) })
}

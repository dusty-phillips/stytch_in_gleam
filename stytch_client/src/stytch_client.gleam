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
pub opaque type StytchClient {
  StytchClient(
    project_id: String,
    secret: String,
    environment: StytchEnvironment,
  )
}

pub type StytchError {
  HttpcError(httpc.HttpError)
  DecodeError(decode.DecodeError)
  JsonError(json.DecodeError)
  ClientError(stytch_codecs.StytchClientError)
}

type StytchEnvironment {
  Test
  Live
}

// Constructors
pub fn new(project_id: String, secret: String) -> StytchClient {
  case project_id {
    "project-test-" <> _ ->
      StytchClient(project_id:, secret:, environment: Test)
    _ -> StytchClient(project_id:, secret:, environment: Live)
  }
}

// Public interfaces
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

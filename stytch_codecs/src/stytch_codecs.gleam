import gleam/dynamic/decode
import gleam/json

pub type StytchClientError {
  StytchClientError(
    status_code: Int,
    request_id: String,
    error_type: String,
    error_message: String,
    error_url: String,
  )
}

pub fn stytch_client_error_to_json(
  stytch_client_error: StytchClientError,
) -> json.Json {
  let StytchClientError(
    status_code:,
    request_id:,
    error_type:,
    error_message:,
    error_url:,
  ) = stytch_client_error
  json.object([
    #("status_code", json.int(status_code)),
    #("request_id", json.string(request_id)),
    #("error_type", json.string(error_type)),
    #("error_message", json.string(error_message)),
    #("error_url", json.string(error_url)),
  ])
}

pub fn stytch_client_error_decoder() -> decode.Decoder(StytchClientError) {
  use status_code <- decode.field("status_code", decode.int)
  use request_id <- decode.field("request_id", decode.string)
  use error_type <- decode.field("error_type", decode.string)
  use error_message <- decode.field("error_message", decode.string)
  use error_url <- decode.field("error_url", decode.string)
  decode.success(StytchClientError(
    status_code:,
    request_id:,
    error_type:,
    error_message:,
    error_url:,
  ))
}

// ===== =====
pub type MagicLinkLoginOrCreateRequest {
  MagicLinkLoginOrCreateRequest(email: String)
}

pub fn magic_link_login_or_create_request_to_json(
  magic_link_login_or_create_request: MagicLinkLoginOrCreateRequest,
) -> json.Json {
  let MagicLinkLoginOrCreateRequest(email:) = magic_link_login_or_create_request
  json.object([
    #("email", json.string(email)),
  ])
}

pub fn magic_link_login_or_create_request_decoder() -> decode.Decoder(
  MagicLinkLoginOrCreateRequest,
) {
  use email <- decode.field("email", decode.string)
  decode.success(MagicLinkLoginOrCreateRequest(email:))
}

// ===== =====
pub type MagicLinkLoginOrCreateResponse {
  MagicLinkLoginOrCreateResponse(
    status_code: Int,
    request_id: String,
    user_id: String,
    email_id: String,
  )
}

pub fn magic_link_login_or_create_response_decoder() -> decode.Decoder(
  MagicLinkLoginOrCreateResponse,
) {
  use status_code <- decode.field("status_code", decode.int)
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use email_id <- decode.field("email_id", decode.string)
  decode.success(MagicLinkLoginOrCreateResponse(
    status_code:,
    request_id:,
    user_id:,
    email_id:,
  ))
}

// ===== =====
pub type TokenAuthenticateRequest {
  TokenAuthenticateRequest(token: String, session_duration_minutes: Int)
}

pub fn token_authenticate_request_to_json(
  token_authenticate_request: TokenAuthenticateRequest,
) -> json.Json {
  let TokenAuthenticateRequest(token:, session_duration_minutes:) =
    token_authenticate_request
  json.object([
    #("token", json.string(token)),
    #("session_duration_minutes", json.int(session_duration_minutes)),
  ])
}

pub fn token_authenticate_request_decoder() -> decode.Decoder(
  TokenAuthenticateRequest,
) {
  use token <- decode.field("token", decode.string)
  use session_duration_minutes <- decode.field(
    "session_duration_minutes",
    decode.int,
  )
  decode.success(TokenAuthenticateRequest(token:, session_duration_minutes:))
}

// ===== =====
pub type SessionTokenAuthenticateRequest {
  SessionTokenAuthenticateRequest(
    session_token: String,
    session_duration_minutes: Int,
  )
}

pub fn session_token_authenticate_request_to_json(
  session_token_authenticate_request: SessionTokenAuthenticateRequest,
) -> json.Json {
  let SessionTokenAuthenticateRequest(session_token:, session_duration_minutes:) =
    session_token_authenticate_request
  json.object([
    #("session_token", json.string(session_token)),
    #("session_duration_minutes", json.int(session_duration_minutes)),
  ])
}

pub fn session_token_authenticate_request_decoder() -> decode.Decoder(
  SessionTokenAuthenticateRequest,
) {
  use session_token <- decode.field("session_token", decode.string)
  use session_duration_minutes <- decode.field(
    "session_duration_minutes",
    decode.int,
  )
  decode.success(SessionTokenAuthenticateRequest(
    session_token:,
    session_duration_minutes:,
  ))
}

// ===== =====
pub type MagicLinkAuthenticateResponse {
  MagicLinkAuthenticateResponse(
    status_code: Int,
    request_id: String,
    user_id: String,
    // todo: add User type
    method_id: String,
    session_token: String,
    session_jwt: String,
  )
}

pub fn magic_link_authenticate_response_to_json(
  magic_link_authenticate_response: MagicLinkAuthenticateResponse,
) -> json.Json {
  let MagicLinkAuthenticateResponse(
    status_code:,
    request_id:,
    user_id:,
    method_id:,
    session_token:,
    session_jwt:,
  ) = magic_link_authenticate_response
  json.object([
    #("status_code", json.int(status_code)),
    #("request_id", json.string(request_id)),
    #("user_id", json.string(user_id)),
    #("method_id", json.string(method_id)),
    #("session_token", json.string(session_token)),
    #("session_jwt", json.string(session_jwt)),
  ])
}

pub fn magic_link_authenticate_response_decoder() -> decode.Decoder(
  MagicLinkAuthenticateResponse,
) {
  use status_code <- decode.field("status_code", decode.int)
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use method_id <- decode.field("method_id", decode.string)
  use session_token <- decode.field("session_token", decode.string)
  use session_jwt <- decode.field("session_jwt", decode.string)
  decode.success(MagicLinkAuthenticateResponse(
    status_code:,
    request_id:,
    user_id:,
    method_id:,
    session_token:,
    session_jwt:,
  ))
}

// ===== =====
pub type SessionAuthenticateResponse {
  SessionAuthenticateResponse(
    status_code: Int,
    request_id: String,
    user: StytchUser,
    session_token: String,
    session_jwt: String,
  )
}

pub fn session_authenticate_response_to_json(
  session_authenticate_response: SessionAuthenticateResponse,
) -> json.Json {
  let SessionAuthenticateResponse(
    status_code:,
    request_id:,
    user:,
    session_token:,
    session_jwt:,
  ) = session_authenticate_response
  json.object([
    #("status_code", json.int(status_code)),
    #("request_id", json.string(request_id)),
    #("user", stytch_user_to_json(user)),
    #("session_token", json.string(session_token)),
    #("session_jwt", json.string(session_jwt)),
  ])
}

pub fn session_authenticate_response_decoder() -> decode.Decoder(
  SessionAuthenticateResponse,
) {
  use status_code <- decode.field("status_code", decode.int)
  use request_id <- decode.field("request_id", decode.string)
  use user <- decode.field("user", stytch_user_decoder())
  use session_token <- decode.field("session_token", decode.string)
  use session_jwt <- decode.field("session_jwt", decode.string)
  decode.success(SessionAuthenticateResponse(
    status_code:,
    request_id:,
    user:,
    session_token:,
    session_jwt:,
  ))
}

// ===== =====
pub type SessionRevokeRequest {
  SessionRevokeRequest(session_token: String)
}

pub fn session_revoke_request_to_json(
  session_revoke_request: SessionRevokeRequest,
) -> json.Json {
  let SessionRevokeRequest(session_token:) = session_revoke_request
  json.object([
    #("session_token", json.string(session_token)),
  ])
}

pub fn session_revoke_request_decoder() -> decode.Decoder(SessionRevokeRequest) {
  use session_token <- decode.field("session_token", decode.string)
  decode.success(SessionRevokeRequest(session_token:))
}

// ===== =====
pub type SessionRevokeResponse {
  SessionRevokeResponse(request_id: String, status_code: Int)
}

pub fn session_revoke_response_to_json(
  session_revoke_response: SessionRevokeResponse,
) -> json.Json {
  let SessionRevokeResponse(request_id:, status_code:) = session_revoke_response
  json.object([
    #("request_id", json.string(request_id)),
    #("status_code", json.int(status_code)),
  ])
}

pub fn session_revoke_response_decoder() -> decode.Decoder(
  SessionRevokeResponse,
) {
  use request_id <- decode.field("request_id", decode.string)
  use status_code <- decode.field("status_code", decode.int)
  decode.success(SessionRevokeResponse(request_id:, status_code:))
}

// ===== =====
pub type StytchUser {
  StytchUser(user_id: String, name: Name, emails: List(Email))
}

pub fn stytch_user_to_json(stytch_user: StytchUser) -> json.Json {
  let StytchUser(user_id:, name:, emails:) = stytch_user
  json.object([
    #("user_id", json.string(user_id)),
    #("name", name_to_json(name)),
    #("emails", json.array(emails, email_to_json)),
  ])
}

pub fn stytch_user_decoder() -> decode.Decoder(StytchUser) {
  use user_id <- decode.field("user_id", decode.string)
  use name <- decode.field("name", name_decoder())
  use emails <- decode.field("emails", decode.list(email_decoder()))
  decode.success(StytchUser(user_id:, name:, emails:))
}

// ===== =====
pub type Name {
  Name(first_name: String, middle_name: String, last_name: String)
}

pub fn name_to_json(name: Name) -> json.Json {
  let Name(first_name:, middle_name:, last_name:) = name
  json.object([
    #("first_name", json.string(first_name)),
    #("middle_name", json.string(middle_name)),
    #("last_name", json.string(last_name)),
  ])
}

pub fn name_decoder() -> decode.Decoder(Name) {
  use first_name <- decode.field("first_name", decode.string)
  use middle_name <- decode.field("middle_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  decode.success(Name(first_name:, middle_name:, last_name:))
}

// ===== =====
pub type Email {
  Email(email_id: String, email: String, verified: Bool)
}

pub fn email_to_json(email: Email) -> json.Json {
  let Email(email_id:, email:, verified:) = email
  json.object([
    #("email_id", json.string(email_id)),
    #("email", json.string(email)),
    #("verified", json.bool(verified)),
  ])
}

pub fn email_decoder() -> decode.Decoder(Email) {
  use email_id <- decode.field("email_id", decode.string)
  use email <- decode.field("email", decode.string)
  use verified <- decode.field("verified", decode.bool)
  decode.success(Email(email_id:, email:, verified:))
}

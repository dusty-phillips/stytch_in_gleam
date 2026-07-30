import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

/// Error messages received from the stytch service
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

// ============================================================================
/// Request to create a magic link.
/// When stytch receives this request, it will send an e-mail, authenticate the user
/// in the clicked link, and redirect back to somewhere in your service.
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

// ============================================================================
/// Request to log in with a passcode.
/// When stytch receives this it will send a passcode to the user's e-mail address.
/// It is up to you to process the passcode and authenticate it with stytch.
pub type PasscodeLoginOrCreateRequest {
  PasscodeLoginOrCreateRequest(email: String)
}

pub fn passcode_login_or_create_request_to_json(
  passcode_login_or_create_request: PasscodeLoginOrCreateRequest,
) -> json.Json {
  let PasscodeLoginOrCreateRequest(email:) = passcode_login_or_create_request
  json.object([
    #("email", json.string(email)),
  ])
}

pub fn passcode_login_or_create_request_decoder() -> decode.Decoder(
  PasscodeLoginOrCreateRequest,
) {
  use email <- decode.field("email", decode.string)
  decode.success(PasscodeLoginOrCreateRequest(email:))
}

// ============================================================================
/// Response to a request to create or log into an account.
///
/// Used by both magic links and OTP login_or_create
pub type LoginOrCreateResponse {
  LoginOrCreateResponse(
    status_code: Int,
    request_id: String,
    user_id: String,
    email_id: String,
  )
}

pub fn login_or_create_response_to_json(
  magic_link_login_or_create_response: LoginOrCreateResponse,
) -> json.Json {
  let LoginOrCreateResponse(status_code:, request_id:, user_id:, email_id:) =
    magic_link_login_or_create_response
  json.object([
    #("status_code", json.int(status_code)),
    #("request_id", json.string(request_id)),
    #("user_id", json.string(user_id)),
    #("email_id", json.string(email_id)),
  ])
}

pub fn login_or_create_response_decoder() -> decode.Decoder(
  LoginOrCreateResponse,
) {
  use status_code <- decode.field("status_code", decode.int)
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use email_id <- decode.field("email_id", decode.string)
  decode.success(LoginOrCreateResponse(
    status_code:,
    request_id:,
    user_id:,
    email_id:,
  ))
}

// ============================================================================
/// Request to authenticate a stytch token returned from login.
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

// ============================================================================
pub type PasscodeAuthenticateRequest {
  PasscodeAuthenticateRequest(
    code: String,
    method_id: String,
    session_duration_minutes: Int,
  )
}

pub fn passcode_authenticate_request_to_json(
  passcode_authenticate_request: PasscodeAuthenticateRequest,
) -> json.Json {
  let PasscodeAuthenticateRequest(code:, method_id:, session_duration_minutes:) =
    passcode_authenticate_request
  json.object([
    #("code", json.string(code)),
    #("method_id", json.string(method_id)),
    #("session_duration_minutes", json.int(session_duration_minutes)),
  ])
}

pub fn passcode_authenticate_request_decoder() -> decode.Decoder(
  PasscodeAuthenticateRequest,
) {
  use code <- decode.field("code", decode.string)
  use method_id <- decode.field("method_id", decode.string)
  use session_duration_minutes <- decode.field(
    "session_duration_minutes",
    decode.int,
  )
  decode.success(PasscodeAuthenticateRequest(
    code:,
    method_id:,
    session_duration_minutes:,
  ))
}

// ============================================================================
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

// ============================================================================
/// Response from Stytch when attempting to autenticate with any method.
pub type AuthenticateResponse {
  AuthenticateResponse(
    status_code: Int,
    request_id: String,
    user_id: String,
    method_id: String,
    session_token: String,
    session_jwt: String,
  )
}

pub fn authenticate_response_to_json(
  magic_link_authenticate_response: AuthenticateResponse,
) -> json.Json {
  let AuthenticateResponse(
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

pub fn authenticate_response_decoder() -> decode.Decoder(AuthenticateResponse) {
  use status_code <- decode.field("status_code", decode.int)
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use method_id <- decode.field("method_id", decode.string)
  use session_token <- decode.field("session_token", decode.string)
  use session_jwt <- decode.field("session_jwt", decode.string)
  decode.success(AuthenticateResponse(
    status_code:,
    request_id:,
    user_id:,
    method_id:,
    session_token:,
    session_jwt:,
  ))
}

// ============================================================================
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

// ============================================================================
/// Payload sent by a browser after a WebAuthn ceremony. The server is
/// responsible for adding the authenticated user's id and session policy
/// before forwarding to Stytch — the browser must not assert identity.
pub type PasskeyCredentialPayload {
  PasskeyCredentialPayload(public_key_credential: String)
}

pub fn passkey_credential_payload_to_json(
  passkey_credential_payload: PasskeyCredentialPayload,
) -> json.Json {
  let PasskeyCredentialPayload(public_key_credential:) =
    passkey_credential_payload
  json.object([
    #("public_key_credential", json.string(public_key_credential)),
  ])
}

pub fn passkey_credential_payload_decoder() -> decode.Decoder(
  PasskeyCredentialPayload,
) {
  use public_key_credential <- decode.field(
    "public_key_credential",
    decode.string,
  )
  decode.success(PasskeyCredentialPayload(public_key_credential:))
}

// ============================================================================
/// Start registering a new passkey for a user with a known id.
pub type PasskeyRegisterStartRequest {
  PasskeyRegisterStartRequest(
    user_id: String,
    domain: String,
    use_base64_url_encoding: Bool,
    return_passkey_credential_options: Bool,
    user_agent: Option(String),
  )
}

pub fn passkey_register_start_request_to_json(
  passkey_register_start_request: PasskeyRegisterStartRequest,
) -> json.Json {
  let PasskeyRegisterStartRequest(
    user_id:,
    domain:,
    use_base64_url_encoding:,
    return_passkey_credential_options:,
    user_agent:,
  ) = passkey_register_start_request
  let user_agent_field = case user_agent {
    option.Some(user_agent) -> [#("user_agent", json.string(user_agent))]
    option.None -> []
  }
  json.object([
    #("user_id", json.string(user_id)),
    #("domain", json.string(domain)),
    #("use_base64_url_encoding", json.bool(use_base64_url_encoding)),
    #(
      "return_passkey_credential_options",
      json.bool(return_passkey_credential_options),
    ),
    ..user_agent_field
  ])
}

pub fn passkey_register_start_request_decoder() -> decode.Decoder(
  PasskeyRegisterStartRequest,
) {
  use user_id <- decode.field("user_id", decode.string)
  use domain <- decode.field("domain", decode.string)
  use use_base64_url_encoding <- decode.field(
    "use_base64_url_encoding",
    decode.bool,
  )
  use return_passkey_credential_options <- decode.field(
    "return_passkey_credential_options",
    decode.bool,
  )
  use user_agent <- decode.optional_field(
    "user_agent",
    option.None,
    decode.map(decode.string, option.Some),
  )
  decode.success(PasskeyRegisterStartRequest(
    user_id:,
    domain:,
    use_base64_url_encoding:,
    return_passkey_credential_options:,
    user_agent:,
  ))
}

// ============================================================================
/// Response to a request to register a new passkey for an authenticated user.
pub type PasskeyRegisterStartResponse {
  PasskeyRegisterStartResponse(
    request_id: String,
    user_id: String,
    public_key_credential_creation_options: String,
    status_code: Int,
  )
}

pub fn passkey_register_start_response_to_json(
  passkey_register_start_response: PasskeyRegisterStartResponse,
) -> json.Json {
  let PasskeyRegisterStartResponse(
    request_id:,
    user_id:,
    public_key_credential_creation_options:,
    status_code:,
  ) = passkey_register_start_response
  json.object([
    #("request_id", json.string(request_id)),
    #("user_id", json.string(user_id)),
    #(
      "public_key_credential_creation_options",
      json.string(public_key_credential_creation_options),
    ),
    #("status_code", json.int(status_code)),
  ])
}

pub fn passkey_register_start_response_decoder() -> decode.Decoder(
  PasskeyRegisterStartResponse,
) {
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use public_key_credential_creation_options <- decode.field(
    "public_key_credential_creation_options",
    decode.string,
  )
  use status_code <- decode.field("status_code", decode.int)
  decode.success(PasskeyRegisterStartResponse(
    request_id:,
    user_id:,
    public_key_credential_creation_options:,
    status_code:,
  ))
}

// ============================================================================
/// Complete registering a new passkey, passing the credential created by the
/// browser's `navigator.credentials.create()` call as a JSON string.
pub type PasskeyRegisterFinishRequest {
  PasskeyRegisterFinishRequest(
    user_id: String,
    public_key_credential: String,
    session_duration_minutes: Int,
  )
}

pub fn passkey_register_finish_request_to_json(
  passkey_register_finish_request: PasskeyRegisterFinishRequest,
) -> json.Json {
  let PasskeyRegisterFinishRequest(
    user_id:,
    public_key_credential:,
    session_duration_minutes:,
  ) = passkey_register_finish_request
  json.object([
    #("user_id", json.string(user_id)),
    #("public_key_credential", json.string(public_key_credential)),
    #("session_duration_minutes", json.int(session_duration_minutes)),
  ])
}

pub fn passkey_register_finish_request_decoder() -> decode.Decoder(
  PasskeyRegisterFinishRequest,
) {
  use user_id <- decode.field("user_id", decode.string)
  use public_key_credential <- decode.field(
    "public_key_credential",
    decode.string,
  )
  use session_duration_minutes <- decode.field(
    "session_duration_minutes",
    decode.int,
  )
  decode.success(PasskeyRegisterFinishRequest(
    user_id:,
    public_key_credential:,
    session_duration_minutes:,
  ))
}

// ============================================================================
/// Response to a completed passkey registration or authentication. Both Stytch
/// endpoints return the same shape: session credentials plus the full user.
pub type PasskeySessionResponse {
  PasskeySessionResponse(
    request_id: String,
    user_id: String,
    webauthn_registration_id: String,
    session_token: String,
    session_jwt: String,
    user: StytchUser,
    status_code: Int,
  )
}

pub fn passkey_session_response_to_json(
  passkey_session_response: PasskeySessionResponse,
) -> json.Json {
  let PasskeySessionResponse(
    request_id:,
    user_id:,
    webauthn_registration_id:,
    session_token:,
    session_jwt:,
    user:,
    status_code:,
  ) = passkey_session_response
  json.object([
    #("request_id", json.string(request_id)),
    #("user_id", json.string(user_id)),
    #("webauthn_registration_id", json.string(webauthn_registration_id)),
    #("session_token", json.string(session_token)),
    #("session_jwt", json.string(session_jwt)),
    #("user", stytch_user_to_json(user)),
    #("status_code", json.int(status_code)),
  ])
}

pub fn passkey_session_response_decoder() -> decode.Decoder(
  PasskeySessionResponse,
) {
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use webauthn_registration_id <- decode.field(
    "webauthn_registration_id",
    decode.string,
  )
  use session_token <- decode.field("session_token", decode.string)
  use session_jwt <- decode.field("session_jwt", decode.string)
  use user <- decode.field("user", stytch_user_decoder())
  use status_code <- decode.field("status_code", decode.int)
  decode.success(PasskeySessionResponse(
    request_id:,
    user_id:,
    webauthn_registration_id:,
    session_token:,
    session_jwt:,
    user:,
    status_code:,
  ))
}

// ============================================================================
/// Start authenticating with a passkey. No user_id is supplied; the browser's
/// passkey picker identifies the user via discoverable credentials.
pub type PasskeyAuthenticateStartRequest {
  PasskeyAuthenticateStartRequest(
    domain: String,
    use_base64_url_encoding: Bool,
    return_passkey_credential_options: Bool,
  )
}

pub fn passkey_authenticate_start_request_to_json(
  passkey_authenticate_start_request: PasskeyAuthenticateStartRequest,
) -> json.Json {
  let PasskeyAuthenticateStartRequest(
    domain:,
    use_base64_url_encoding:,
    return_passkey_credential_options:,
  ) = passkey_authenticate_start_request
  json.object([
    #("domain", json.string(domain)),
    #("use_base64_url_encoding", json.bool(use_base64_url_encoding)),
    #(
      "return_passkey_credential_options",
      json.bool(return_passkey_credential_options),
    ),
  ])
}

pub fn passkey_authenticate_start_request_decoder() -> decode.Decoder(
  PasskeyAuthenticateStartRequest,
) {
  use domain <- decode.field("domain", decode.string)
  use use_base64_url_encoding <- decode.field(
    "use_base64_url_encoding",
    decode.bool,
  )
  use return_passkey_credential_options <- decode.field(
    "return_passkey_credential_options",
    decode.bool,
  )
  decode.success(PasskeyAuthenticateStartRequest(
    domain:,
    use_base64_url_encoding:,
    return_passkey_credential_options:,
  ))
}

// ============================================================================
/// Response to a request to start passkey authentication.
pub type PasskeyAuthenticateStartResponse {
  PasskeyAuthenticateStartResponse(
    request_id: String,
    user_id: String,
    public_key_credential_request_options: String,
    status_code: Int,
  )
}

pub fn passkey_authenticate_start_response_to_json(
  passkey_authenticate_start_response: PasskeyAuthenticateStartResponse,
) -> json.Json {
  let PasskeyAuthenticateStartResponse(
    request_id:,
    user_id:,
    public_key_credential_request_options:,
    status_code:,
  ) = passkey_authenticate_start_response
  json.object([
    #("request_id", json.string(request_id)),
    #("user_id", json.string(user_id)),
    #(
      "public_key_credential_request_options",
      json.string(public_key_credential_request_options),
    ),
    #("status_code", json.int(status_code)),
  ])
}

pub fn passkey_authenticate_start_response_decoder() -> decode.Decoder(
  PasskeyAuthenticateStartResponse,
) {
  use request_id <- decode.field("request_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use public_key_credential_request_options <- decode.field(
    "public_key_credential_request_options",
    decode.string,
  )
  use status_code <- decode.field("status_code", decode.int)
  decode.success(PasskeyAuthenticateStartResponse(
    request_id:,
    user_id:,
    public_key_credential_request_options:,
    status_code:,
  ))
}

// ============================================================================
/// Complete passkey authentication, passing the credential returned by the
/// browser's `navigator.credentials.get()` call as a JSON string.
pub type PasskeyAuthenticateRequest {
  PasskeyAuthenticateRequest(
    public_key_credential: String,
    session_duration_minutes: Int,
  )
}

pub fn passkey_authenticate_request_to_json(
  passkey_authenticate_request: PasskeyAuthenticateRequest,
) -> json.Json {
  let PasskeyAuthenticateRequest(
    public_key_credential:,
    session_duration_minutes:,
  ) = passkey_authenticate_request
  json.object([
    #("public_key_credential", json.string(public_key_credential)),
    #("session_duration_minutes", json.int(session_duration_minutes)),
  ])
}

pub fn passkey_authenticate_request_decoder() -> decode.Decoder(
  PasskeyAuthenticateRequest,
) {
  use public_key_credential <- decode.field(
    "public_key_credential",
    decode.string,
  )
  use session_duration_minutes <- decode.field(
    "session_duration_minutes",
    decode.int,
  )
  decode.success(PasskeyAuthenticateRequest(
    public_key_credential:,
    session_duration_minutes:,
  ))
}

// ============================================================================
/// Request to revoke a session.
///
/// Use for signout.
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

// ============================================================================
/// Response from stytch to a request to revoke a given session token.
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

// ============================================================================
pub type StytchUser {
  StytchUser(
    user_id: String,
    name: Name,
    emails: List(Email),
    webauthn_registrations: List(WebAuthnRegistration),
  )
}

pub fn stytch_user_to_json(stytch_user: StytchUser) -> json.Json {
  let StytchUser(user_id:, name:, emails:, webauthn_registrations:) =
    stytch_user
  json.object([
    #("user_id", json.string(user_id)),
    #("name", name_to_json(name)),
    #("emails", json.array(emails, email_to_json)),
    #(
      "webauthn_registrations",
      json.array(webauthn_registrations, webauthn_registration_to_json),
    ),
  ])
}

pub fn stytch_user_decoder() -> decode.Decoder(StytchUser) {
  use user_id <- decode.field("user_id", decode.string)
  use name <- decode.field("name", name_decoder())
  use emails <- decode.field("emails", decode.list(email_decoder()))
  use webauthn_registrations <- decode.field(
    "webauthn_registrations",
    decode.list(webauthn_registration_decoder()),
  )
  decode.success(StytchUser(user_id:, name:, emails:, webauthn_registrations:))
}

// ============================================================================
/// A passkey or WebAuthn registration associated with a user.
pub type WebAuthnRegistration {
  WebAuthnRegistration(
    webauthn_registration_id: String,
    domain: String,
    user_agent: String,
    verified: Bool,
    authenticator_type: String,
    name: String,
  )
}

pub fn webauthn_registration_to_json(
  webauthn_registration: WebAuthnRegistration,
) -> json.Json {
  let WebAuthnRegistration(
    webauthn_registration_id:,
    domain:,
    user_agent:,
    verified:,
    authenticator_type:,
    name:,
  ) = webauthn_registration
  json.object([
    #("webauthn_registration_id", json.string(webauthn_registration_id)),
    #("domain", json.string(domain)),
    #("user_agent", json.string(user_agent)),
    #("verified", json.bool(verified)),
    #("authenticator_type", json.string(authenticator_type)),
    #("name", json.string(name)),
  ])
}

pub fn webauthn_registration_decoder() -> decode.Decoder(WebAuthnRegistration) {
  use webauthn_registration_id <- decode.field(
    "webauthn_registration_id",
    decode.string,
  )
  use domain <- decode.field("domain", decode.string)
  use user_agent <- decode.field("user_agent", decode.string)
  use verified <- decode.field("verified", decode.bool)
  use authenticator_type <- decode.field("authenticator_type", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(WebAuthnRegistration(
    webauthn_registration_id:,
    domain:,
    user_agent:,
    verified:,
    authenticator_type:,
    name:,
  ))
}

// ============================================================================
/// Name identifying a user.
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

// ============================================================================
/// Email identifying a user.
/// Stytch separates email_id (not PII) from email and indicates whether the user has verified
/// that they can access that address.
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

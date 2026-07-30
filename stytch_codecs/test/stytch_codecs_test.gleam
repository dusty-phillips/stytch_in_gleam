import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleeunit
import stytch_codecs

pub fn main() -> Nil {
  gleeunit.main()
}

fn round_trip(
  value: a,
  to_json: fn(a) -> json.Json,
  decoder: decode.Decoder(a),
) -> Result(a, json.DecodeError) {
  value
  |> to_json
  |> json.to_string
  |> json.parse(decoder)
}

pub fn stytch_client_error_test() {
  let value =
    stytch_codecs.StytchClientError(
      404,
      "abcy_request_id",
      "not_found",
      "Resource could noot be found",
      "http://some.docs.help/",
    )

  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.stytch_client_error_to_json,
      stytch_codecs.stytch_client_error_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn magic_link_login_or_create_request_test() {
  let value =
    stytch_codecs.MagicLinkLoginOrCreateRequest("somebody@somewhere.com")
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.magic_link_login_or_create_request_to_json,
      stytch_codecs.magic_link_login_or_create_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn magic_link_login_or_create_response_test() {
  let value =
    stytch_codecs.LoginOrCreateResponse(
      200,
      "abc_request_id",
      "some_user_id",
      "somebody@somewhere.com",
    )
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.login_or_create_response_to_json,
      stytch_codecs.login_or_create_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn token_authenticate_request_test() {
  let value = stytch_codecs.TokenAuthenticateRequest("some_weird_token", 60)
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.token_authenticate_request_to_json,
      stytch_codecs.token_authenticate_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn magic_link_authenticate_response_test() {
  let value =
    stytch_codecs.AuthenticateResponse(
      404,
      "abcy_request_id",
      "some_user_id",
      "some_method_id",
      "some_session_token",
      "well_it_would_be_a_jwt",
    )

  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.authenticate_response_to_json,
      stytch_codecs.authenticate_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn session_authenticate_response_test() {
  // note: also implicitly tests StytchUser, Name, Email, WebAuthnRegistration
  let value =
    stytch_codecs.SessionAuthenticateResponse(
      404,
      "abcy_request_id",
      stytch_codecs.StytchUser(
        "some_user_id",
        stytch_codecs.Name("Some", "body", "here"),
        [stytch_codecs.Email("some_email_id", "some@body.here", True)],
        [
          stytch_codecs.WebAuthnRegistration(
            "some_registration_id",
            "example.com",
            "some user agent",
            True,
            "platform",
            "My Passkey",
          ),
        ],
      ),
      "some_session_token",
      "well_it_would_be_a_jwt",
    )

  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.session_authenticate_response_to_json,
      stytch_codecs.session_authenticate_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn session_revoke_request_test() {
  let value = stytch_codecs.SessionRevokeRequest("some_weird_token")
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.session_revoke_request_to_json,
      stytch_codecs.session_revoke_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn session_revoke_response_test() {
  let value = stytch_codecs.SessionRevokeResponse("some_request_id", 200)
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.session_revoke_response_to_json,
      stytch_codecs.session_revoke_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_credential_payload_test() {
  let value =
    stytch_codecs.PasskeyCredentialPayload("{\"type\":\"public-key\"}")
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_credential_payload_to_json,
      stytch_codecs.passkey_credential_payload_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_register_start_request_test() {
  let value =
    stytch_codecs.PasskeyRegisterStartRequest(
      "some_user_id",
      "example.com",
      True,
      True,
      option.Some("Mozilla/5.0"),
    )
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_register_start_request_to_json,
      stytch_codecs.passkey_register_start_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_register_start_response_test() {
  let value =
    stytch_codecs.PasskeyRegisterStartResponse(
      "some_request_id",
      "some_user_id",
      "{\"challenge\":\"abc\"}",
      200,
    )
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_register_start_response_to_json,
      stytch_codecs.passkey_register_start_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_register_finish_request_test() {
  let value =
    stytch_codecs.PasskeyRegisterFinishRequest(
      "some_user_id",
      "{\"type\":\"public-key\"}",
      60,
    )
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_register_finish_request_to_json,
      stytch_codecs.passkey_register_finish_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_session_response_test() {
  let value =
    stytch_codecs.PasskeySessionResponse(
      "some_request_id",
      "some_user_id",
      "some_registration_id",
      "some_session_token",
      "well_it_would_be_a_jwt",
      stytch_codecs.StytchUser(
        "some_user_id",
        stytch_codecs.Name("Some", "body", "here"),
        [stytch_codecs.Email("some_email_id", "some@body.here", True)],
        [],
      ),
      200,
    )
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_session_response_to_json,
      stytch_codecs.passkey_session_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_authenticate_start_request_test() {
  let value =
    stytch_codecs.PasskeyAuthenticateStartRequest("example.com", True, True)
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_authenticate_start_request_to_json,
      stytch_codecs.passkey_authenticate_start_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_authenticate_start_response_test() {
  let value =
    stytch_codecs.PasskeyAuthenticateStartResponse(
      "some_request_id",
      "some_user_id",
      "{\"challenge\":\"abc\"}",
      200,
    )
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_authenticate_start_response_to_json,
      stytch_codecs.passkey_authenticate_start_response_decoder(),
    )

  assert round_trip_value == Ok(value)
}

pub fn passkey_authenticate_request_test() {
  let value =
    stytch_codecs.PasskeyAuthenticateRequest("{\"type\":\"public-key\"}", 60)
  let round_trip_value =
    round_trip(
      value,
      stytch_codecs.passkey_authenticate_request_to_json,
      stytch_codecs.passkey_authenticate_request_decoder(),
    )

  assert round_trip_value == Ok(value)
}


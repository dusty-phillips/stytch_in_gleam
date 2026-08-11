import environment
import gleam/http
import gleam/http/request as http_request
import gleam/json
import gleam/list
import gleam/option
import handler_utils
import lustre/attribute
import lustre/element
import lustre/element/html
import stytch_client
import stytch_codecs
import web
import wisp.{type Request, type Response}

pub fn handle_request(
  environment: environment.Environment,
  static_directory: String,
  request: Request,
) -> Response {
  use request <- web.middleware(request, static_directory)

  case request.method, wisp.path_segments(request) {
    http.Post, ["api", "send_sign_in_link"] ->
      handle_send_sign_in_link(environment, request)

    http.Post, ["api", "send_passcode"] ->
      handle_send_passcode(environment, request)

    http.Post, ["api", "verify_passcode"] ->
      handle_verify_passcode(environment, request)

    http.Post, ["api", "start_register_passkey"] ->
      handle_start_register_passkey(environment, request)

    http.Post, ["api", "finish_register_passkey"] ->
      handle_finish_register_passkey(environment, request)

    http.Post, ["api", "start_passkey_login"] ->
      handle_start_passkey_login(environment, request)

    http.Post, ["api", "passkey_login"] ->
      handle_passkey_login(environment, request)

    http.Delete, ["api", "delete_passkey", webauthn_registration_id] ->
      handle_delete_passkey(environment, request, webauthn_registration_id)

    http.Get, ["api", "sign_out"] -> handle_sign_out(environment, request)

    http.Get, ["api", "me"] -> handle_authenticate_session(environment, request)

    http.Get, ["authenticate"] ->
      serve_authenticate_magic_link(environment, request)

    http.Get, ["api", ..] -> wisp.not_found()
    http.Get, _ -> serve_spa()
    _, _ -> wisp.not_found()
  }
}

fn serve_spa() -> Response {
  let html =
    html.html([], [
      html.head([], [
        html.title([], "Stytch Demo"),
        html.script(
          [
            attribute.type_("module"),
            attribute.src("/static/client.js"),
          ],
          "",
        ),
      ]),
      html.body([], [html.div([attribute.id("app")], [])]),
    ])

  html
  |> element.to_document_string
  |> wisp.html_response(200)
}

fn serve_authenticate_magic_link(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use token <- handler_utils.require_query_param(request, "token")

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.magic_link_authenticate(token, 60)

  case stytch_response {
    Error(_) -> {
      wisp.response(403)
    }
    Ok(stytch_codecs.AuthenticateResponse(session_token:, ..)) -> {
      // note: Safari doesn't seem to set cookies on 300 response, so returning a 200 with meta-refresh
      html.html([], [
        html.head([], [
          html.meta([
            attribute.http_equiv("refresh"),
            attribute.content("0;url=http://localhost:3000"),
          ]),
        ]),
      ])
      |> element.to_document_string
      |> wisp.html_response(200)
      |> handler_utils.set_session_cookie(session_token)
    }
  }
}

fn handle_send_sign_in_link(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use data <- handler_utils.decode_or_422_response(
    request,
    stytch_codecs.magic_link_login_or_create_request_decoder(),
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.magic_link_login_or_create(data.email)

  case stytch_response {
    Ok(_) -> wisp.ok()
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_send_passcode(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use data <- handler_utils.decode_or_422_response(
    request,
    stytch_codecs.passcode_login_or_create_request_decoder(),
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.passcode_login_or_create(data.email)

  case stytch_response {
    Ok(login_response) ->
      login_response
      |> stytch_codecs.login_or_create_response_to_json
      |> json.to_string
      |> wisp.json_response(200)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_verify_passcode(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use data <- handler_utils.decode_or_422_response(
    request,
    stytch_codecs.passcode_authenticate_request_decoder(),
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.passcode_authenticate(
      data.code,
      data.method_id,
      data.session_duration_minutes,
    )

  case stytch_response {
    Ok(auth_response) ->
      wisp.ok()
      |> handler_utils.set_session_cookie(auth_response.session_token)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

// Session lifetime for newly created Stytch sessions. Session policy is
// decided by the server, never asserted by the browser.
const session_duration_minutes = 7200

fn handle_start_register_passkey(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use user <- session_user_or_error_response(environment, request)

  let user_agent =
    request
    |> http_request.get_header("user-agent")
    |> option.from_result

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.passkey_registration_start(
      stytch_codecs.PasskeyRegisterStartRequest(
        user_id: user.user_id,
        domain: environment.stytch_domain,
        use_base64_url_encoding: True,
        return_passkey_credential_options: True,
        user_agent:,
      ),
    )

  case stytch_response {
    Ok(response) ->
      response
      |> stytch_codecs.passkey_register_start_response_to_json
      |> json.to_string
      |> wisp.json_response(200)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_finish_register_passkey(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use user <- session_user_or_error_response(environment, request)
  use data <- handler_utils.decode_or_422_response(
    request,
    stytch_codecs.passkey_credential_payload_decoder(),
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.passkey_registration_finish(
      stytch_codecs.PasskeyRegisterFinishRequest(
        user_id: user.user_id,
        public_key_credential: data.public_key_credential,
        session_duration_minutes:,
      ),
    )

  case stytch_response {
    Ok(response) ->
      response
      |> stytch_codecs.passkey_session_response_to_json
      |> json.to_string
      |> wisp.json_response(200)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_start_passkey_login(
  environment: environment.Environment,
  _request: Request,
) -> Response {
  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.passkey_authenticate_start(
      stytch_codecs.PasskeyAuthenticateStartRequest(
        domain: environment.stytch_domain,
        use_base64_url_encoding: True,
        return_passkey_credential_options: True,
      ),
    )

  case stytch_response {
    Ok(response) ->
      response
      |> stytch_codecs.passkey_authenticate_start_response_to_json
      |> json.to_string
      |> wisp.json_response(200)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_passkey_login(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use data <- handler_utils.decode_or_422_response(
    request,
    stytch_codecs.passkey_credential_payload_decoder(),
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.passkey_authenticate(
      stytch_codecs.PasskeyAuthenticateRequest(
        public_key_credential: data.public_key_credential,
        session_duration_minutes:,
      ),
    )

  case stytch_response {
    Ok(auth_response) ->
      auth_response
      |> stytch_codecs.passkey_session_response_to_json
      |> json.to_string
      |> wisp.json_response(200)
      |> handler_utils.set_session_cookie(auth_response.session_token)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_delete_passkey(
  environment: environment.Environment,
  request: Request,
  webauthn_registration_id: String,
) -> Response {
  use user <- session_user_or_error_response(environment, request)

  case
    list.any(user.webauthn_registrations, fn(registration) {
      registration.webauthn_registration_id == webauthn_registration_id
    })
  {
    False -> wisp.not_found()
    True -> {
      let stytch_response =
        environment
        |> test_stytch_client()
        |> stytch_client.passkey_delete(webauthn_registration_id)

      case stytch_response {
        Ok(_) -> wisp.ok()
        Error(stytch_error) -> stytch_error_to_response(stytch_error)
      }
    }
  }
}

fn handle_authenticate_session(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use session_token <- handler_utils.session_token_or_forbidden_response(
    request,
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.session_authenticate(session_token, 60)

  case stytch_response {
    Ok(session_response) ->
      session_response.user
      |> stytch_codecs.stytch_user_to_json
      |> json.to_string
      |> wisp.json_response(200)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn handle_sign_out(
  environment: environment.Environment,
  request: Request,
) -> Response {
  use session_token <- handler_utils.session_token_or_forbidden_response(
    request,
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.session_revoke(session_token)

  case stytch_response {
    Ok(_) -> wisp.ok()
    Error(_) -> wisp.internal_server_error()
  }
}

// Helpers

/// Authenticate the request's session token against Stytch and pass the
/// verified user to the handler. Identity for passkey operations always
/// comes from the session, never from the request body.
fn session_user_or_error_response(
  environment: environment.Environment,
  request: Request,
  continue: fn(stytch_codecs.StytchUser) -> Response,
) -> Response {
  use session_token <- handler_utils.session_token_or_forbidden_response(
    request,
  )

  let stytch_response =
    environment
    |> test_stytch_client()
    |> stytch_client.session_authenticate(session_token, 60)

  case stytch_response {
    Ok(session_response) -> continue(session_response.user)
    Error(stytch_error) -> stytch_error_to_response(stytch_error)
  }
}

fn test_stytch_client(
  environment: environment.Environment,
) -> stytch_client.StytchClient {
  stytch_client.new(environment.stytch_project_id, environment.stytch_secret)
}

fn stytch_error_to_response(
  stytch_error: stytch_client.StytchError,
) -> wisp.Response {
  case stytch_error {
    stytch_client.ClientError(error) ->
      stytch_codecs.stytch_client_error_to_json(error)
      |> json.to_string()
      |> wisp.json_response(error.status_code)
    stytch_client.HttpcError(_) -> wisp.response(502)
    stytch_client.DecodeError(_) | stytch_client.JsonError(_) ->
      wisp.internal_server_error()
  }
}

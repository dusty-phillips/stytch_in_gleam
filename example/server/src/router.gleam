import environment
import gleam/http
import gleam/json
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
      wisp.redirect("http://localhost:3000")
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

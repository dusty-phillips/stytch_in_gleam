import gleam/dynamic/decode
import gleam/http/cookie
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option
import wisp

pub fn decode_or_422_response(
  request: wisp.Request,
  decoder: decode.Decoder(data),
  continue: fn(data) -> wisp.Response,
) -> response.Response(wisp.Body) {
  use json <- wisp.require_json(request)
  case decode.run(json, decoder) {
    Ok(data) -> continue(data)
    Error(_) -> wisp.unprocessable_content()
  }
}

pub fn require_query_param(
  request: wisp.Request,
  query_param: String,
  continue: fn(String) -> wisp.Response,
) -> wisp.Response {
  let token_param =
    request
    |> wisp.get_query
    |> list.key_find("token")

  case token_param {
    Ok(param) -> continue(param)
    Error(Nil) -> wisp.bad_request("Missing query param " <> query_param)
  }
}

pub fn session_token_or_forbidden_response(
  request: wisp.Request,
  continue: fn(String) -> wisp.Response,
) -> wisp.Response {
  let session_token =
    request
    |> request.get_cookies
    |> list.key_find("session_token")

  case session_token {
    Ok(token) -> continue(token)
    Error(Nil) -> wisp.response(403)
  }
}

pub fn set_session_cookie(
  response: wisp.Response,
  token: String,
) -> wisp.Response {
  let attributes =
    cookie.Attributes(
      max_age: option.Some(86_400),
      domain: option.None,
      path: option.Some("/"),
      secure: True,
      http_only: True,
      same_site: option.Some(cookie.Strict),
    )
  let cookie_value = cookie.set_header("session_token", token, attributes)

  response
  |> response.set_header("set-cookie", cookie_value)
}

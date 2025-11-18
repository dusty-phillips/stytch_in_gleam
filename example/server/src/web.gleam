import wisp.{type Request, type Response}

pub fn middleware(
  request: Request,
  static_directory: String,
  handle_request: fn(Request) -> Response,
) -> Response {
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes
  use request <- wisp.handle_head(request)
  use request <- wisp.csrf_known_header_protection(request)

  use <- wisp.serve_static(request, under: "/static", from: static_directory)

  // todo: serve static

  handle_request(request)
}

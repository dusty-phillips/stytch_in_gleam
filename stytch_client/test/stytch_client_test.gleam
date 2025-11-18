import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/result
import gleeunit
import stytch_client

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn add_basic_auth_test() {
  let client = stytch_client.new_test("test_id", "test_secret")
  let req = request.new()

  let result = stytch_client.add_basic_auth(req, client)

  let auth_header = request.get_header(result, "authorization")
  assert auth_header == Ok("Basic " <> "dGVzdF9pZDp0ZXN0X3NlY3JldA==")
}

pub fn parse_stytch_response_200_test() {
  let response =
    response.new(200)
    |> response.set_body("{\"user_id\": \"user-123\"}")

  let result =
    stytch_client.parse_stytch_response(response, {
      use user_id <- decode.field("user_id", decode.string)
      decode.success(user_id)
    })
  assert result == Ok("user-123")
}

pub fn parse_stytch_response_error_test() {
  let response =
    response.new(400)
    |> response.set_body("{\"error_type\": \"invalid_request\"}")

  let result = stytch_client.parse_stytch_response(response, decode.string)
  assert result.is_error(result)
}

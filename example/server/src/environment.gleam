import gleam/result
import glenvy/dotenv
import glenvy/env

pub type Environment {
  Environment(
    secret_key_base: String,
    stytch_project_id: String,
    stytch_secret: String,
    stytch_domain: String,
  )
}

pub fn load_env() -> Result(Environment, env.Error) {
  // intentionally ignore errors loading the file
  let _ = dotenv.load()

  // demand that certain keys be available
  use secret_key_base <- result.try(env.string("SECRET_KEY_BASE"))
  use stytch_project_id <- result.try(env.string("STYTCH_PROJECT_ID"))
  use stytch_secret <- result.try(env.string("STYTCH_SECRET"))

  // The WebAuthn relying-party domain is server configuration; the browser
  // must not assert it. Defaults to localhost for development.
  let stytch_domain = result.unwrap(env.string("STYTCH_DOMAIN"), "localhost")

  Ok(Environment(
    secret_key_base:,
    stytch_project_id:,
    stytch_secret:,
    stytch_domain:,
  ))
}

import gleam/result
import glenvy/dotenv
import glenvy/env

pub type Environment {
  Environment(
    secret_key_base: String,
    stytch_project_id: String,
    stytch_secret: String,
  )
}

pub fn load_env() -> Result(Environment, env.Error) {
  // intentionally ignore errors loading the file
  let _ = dotenv.load()

  // demand that certain keys be available
  use secret_key_base <- result.try(env.string("SECRET_KEY_BASE"))
  use stytch_project_id <- result.try(env.string("STYTCH_PROJECT_ID"))
  use stytch_secret <- result.try(env.string("STYTCH_SECRET"))

  Ok(Environment(secret_key_base:, stytch_project_id:, stytch_secret:))
}

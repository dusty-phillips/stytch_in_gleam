import environment
import gleam/erlang/process
import gleam/io
import mist
import router
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let assert Ok(environment) = environment.load_env()

  let assert Ok(priv_directory) = wisp.priv_directory("server")
  let static_directory = priv_directory <> "/static"

  let assert Ok(_) =
    router.handle_request(environment, static_directory, _)
    |> wisp_mist.handler(environment.secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  io.println("Running on port 3000")
  process.sleep_forever()
}

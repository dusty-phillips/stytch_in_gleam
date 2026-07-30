import auth_views
import gleam/list
import gleam/result
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import stytch_codecs
import stytch_ui_model as stytch

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(auth: stytch.AuthModel)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  #(
    Model(stytch.new(api_url, stytch.Passcode)),
    stytch.get_me(api_url) |> effect.map(AuthMsg),
  )
}

type Msg {
  AuthMsg(stytch.AuthMsg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case model, msg {
    Model(auth_model), AuthMsg(auth_msg) -> {
      let #(next_auth, effect) = stytch.update(auth_model, auth_msg)
      #(Model(auth: next_auth), effect.map(effect, AuthMsg))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  let Model(stytch.AuthModel(state:, ..)) = model
  case state {
    stytch.Authenticating ->
      auth_views.view_authenticating() |> element.map(AuthMsg)

    stytch.Unauthenticated(email) ->
      auth_views.view_sign_in_button(email) |> element.map(AuthMsg)

    stytch.SendingPasscodeEmail(email) ->
      auth_views.view_sending_passcode(email) |> element.map(AuthMsg)
    stytch.WaitingForPasscode(email, _email_id, passcode) ->
      auth_views.view_passcode_sent(email, passcode) |> element.map(AuthMsg)
    stytch.VerifyingPasscode(..) ->
      auth_views.view_authenticating() |> element.map(AuthMsg)

    stytch.PasskeyLoginInProgress ->
      auth_views.view_authenticating() |> element.map(AuthMsg)

    stytch.Authenticated(user:, passkey_state:) ->
      html.div([], [
        html.text("Logged in as " <> display_name(user)),
        auth_views.view_sign_out_button() |> element.map(AuthMsg),
        auth_views.view_passkeys(user, passkey_state) |> element.map(AuthMsg),
      ])

    stytch.WaitingForMagicLink(_) -> panic as "magic links not enabled"
  }
}

// Stytch does not collect a name at sign-up, so fall back to the first email.
fn display_name(user: stytch_codecs.StytchUser) -> String {
  case user.name.first_name {
    "" ->
      user.emails
      |> list.first
      |> result.map(fn(email) { email.email })
      |> result.unwrap("")
    first_name -> first_name
  }
}

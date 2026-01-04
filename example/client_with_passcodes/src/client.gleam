import auth_views
import cats
import gleam/list
import gleam/result
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import stytch_ui_model as stytch

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(auth: stytch.AuthModel, cat_counter: cats.CatCounter)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  #(
    Model(
      stytch.new("http://localhost:3000/api", stytch.Passcode),
      cats.init_cat_counter(),
    ),
    stytch.get_me(api_url) |> effect.map(AuthMsg),
  )
}

type Msg {
  CatMsg(cats.CatMsg)
  AuthMsg(stytch.AuthMsg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case model, msg {
    Model(auth_model, ..),
      AuthMsg(stytch.ApiConfirmsUnauthenticated as auth_msg)
    -> {
      let #(next_auth, effect) = stytch.update(auth_model, auth_msg)
      #(
        Model(auth: next_auth, cat_counter: cats.init_cat_counter()),
        effect.map(effect, AuthMsg),
      )
    }

    Model(auth_model, ..), AuthMsg(auth_msg) -> {
      let #(next_auth, effect) = stytch.update(auth_model, auth_msg)
      #(Model(..model, auth: next_auth), effect.map(effect, AuthMsg))
    }

    Model(auth_model, cat_counter), CatMsg(cat_msg) -> {
      let #(next_model, effect) = cats.update_cat_counter(cat_counter, cat_msg)
      #(Model(auth_model, next_model), effect |> effect.map(CatMsg))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  let Model(stytch.AuthModel(state:, ..), cat_counter:) = model
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

    stytch.Authenticated(user:) ->
      html.div([], [
        auth_views.view_sign_out_button() |> element.map(AuthMsg),
        cats.view_cat_model(
          user.emails
            |> list.first
            |> result.map(fn(email) { email.email })
            |> result.unwrap("Esteemed Cat Lover"),
          cat_counter,
        )
          |> element.map(CatMsg),
      ])

    stytch.WaitingForMagicLink(_) -> panic as "magic links not enabled"
  }
}

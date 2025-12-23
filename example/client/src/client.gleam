import auth_views
import cats
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import stytch_ui_model

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(auth: stytch_ui_model.AuthModel, cat_counter: cats.CatCounter)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  #(
    Model(
      stytch_ui_model.new("http://localhost:3000/api"),
      cats.init_cat_counter(),
    ),
    stytch_ui_model.get_me(api_url) |> effect.map(AuthMsg),
  )
}

type Msg {
  CatMsg(cats.CatMsg)
  AuthMsg(stytch_ui_model.AuthMsg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case model, msg {
    Model(auth_model, ..),
      AuthMsg(stytch_ui_model.ApiConfirmsUnauthenticated as auth_msg)
    -> {
      let #(next_auth, effect) =
        stytch_ui_model.update_auth(auth_model, auth_msg)
      #(
        Model(auth: next_auth, cat_counter: cats.init_cat_counter()),
        effect.map(effect, AuthMsg),
      )
    }

    Model(auth_model, ..), AuthMsg(auth_msg) -> {
      let #(next_auth, effect) =
        stytch_ui_model.update_auth(auth_model, auth_msg)
      #(Model(..model, auth: next_auth), effect.map(effect, AuthMsg))
    }

    Model(
      stytch_ui_model.AuthModel(api_url, stytch_ui_model.Authenticated(email:)),
      cat_counter,
    ),
      CatMsg(cat_msg)
    -> {
      let #(next_model, effect) = cats.update_cat_counter(cat_counter, cat_msg)
      #(
        Model(
          stytch_ui_model.AuthModel(
            api_url,
            stytch_ui_model.Authenticated(email),
          ),
          next_model,
        ),
        effect |> effect.map(CatMsg),
      )
    }

    // haven't decided best way to handle the "got a message that didn't match current state" cases.
    // panic seems heavy, but silent dropping seems bad too. (should be impossible but...)
    Model(
      stytch_ui_model.AuthModel(state: stytch_ui_model.Authenticating, ..),
      ..,
    ),
      _
    -> #(model, effect.none())

    Model(
      stytch_ui_model.AuthModel(state: stytch_ui_model.Unauthenticated(_), ..),
      ..,
    ),
      _
    -> #(model, effect.none())

    Model(
      stytch_ui_model.AuthModel(
        state: stytch_ui_model.WaitingForMagicLink(_),
        ..,
      ),
      ..,
    ),
      _
    -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  let Model(stytch_ui_model.AuthModel(state:, ..), cat_counter:) = model
  case state {
    stytch_ui_model.Authenticating ->
      auth_views.view_authenticating() |> element.map(AuthMsg)
    stytch_ui_model.Unauthenticated(email) ->
      auth_views.view_sign_in_button(email) |> element.map(AuthMsg)
    stytch_ui_model.WaitingForMagicLink(email) ->
      auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)
    stytch_ui_model.Authenticated(email:) ->
      html.div([], [
        auth_views.view_sign_out_button() |> element.map(AuthMsg),
        cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
      ])
  }
}

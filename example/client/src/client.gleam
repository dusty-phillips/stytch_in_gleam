import auth
import auth_views
import cats
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(auth.AuthModel(cats.CatCounter))
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  #(
    Model(auth.new("http://localhost:3000/api")),
    auth.get_me(api_url) |> effect.map(AuthMsg),
  )
}

type Msg {
  CatMsg(cats.CatMsg)
  AuthMsg(auth.AuthMsg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case model, msg {
    Model(auth_model), AuthMsg(auth_msg) -> {
      let #(model, effect) =
        auth.update_auth(auth_model, auth_msg, cats.init_cat_counter)
      #(Model(model), effect.map(effect, AuthMsg))
    }
    Model(auth.AuthModel(
      api_url,
      auth.Authenticated(email:, model: cat_counter),
    )),
      CatMsg(cat_msg)
    -> {
      let #(model, effect) = cats.update_cat_counter(cat_counter, cat_msg)
      #(
        Model(auth.AuthModel(api_url, auth.Authenticated(email, model))),
        effect |> effect.map(CatMsg),
      )
    }

    // haven't decided best way to handle the "got a message that didn't match current state" cases.
    // panic seems heavy, but silent dropping seems bad too.
    // I think these aren't possible if gleam routes things correctly but I don't know it.
    // feels like lustre probably has opinions on this.
    Model(auth.AuthModel(state: auth.Authenticating, ..)), _ -> #(
      model,
      effect.none(),
    )
    Model(auth.AuthModel(state: auth.Unauthenticated(_), ..)), _ -> #(
      model,
      effect.none(),
    )
    Model(auth.AuthModel(state: auth.WaitingForMagicLink(_), ..)), _ -> #(
      model,
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  let Model(auth.AuthModel(state:, ..)) = model
  case state {
    auth.Authenticating ->
      auth_views.view_authenticating() |> element.map(AuthMsg)
    auth.Unauthenticated(email) ->
      auth_views.view_sign_in_button(email) |> element.map(AuthMsg)
    auth.WaitingForMagicLink(email) ->
      auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)
    auth.Authenticated(email:, model: cat_counter) ->
      html.div([], [
        auth_views.view_sign_out_button() |> element.map(AuthMsg),
        cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
      ])
  }
}

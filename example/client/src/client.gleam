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
  #(Model(auth.Authenticating), auth.get_me() |> effect.map(AuthMsg))
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
    Model(auth.Authenticated(email:, model: cat_counter)), CatMsg(cat_msg) -> {
      let #(model, effect) = cats.update_cat_counter(cat_counter, cat_msg)
      #(Model(auth.Authenticated(email, model)), effect |> effect.map(CatMsg))
    }

    // haven't decided best way to handle the "got a message that didn't match current state" cases.
    // panic seems heavy, but silent dropping seems bad too.
    // I think these aren't possible if gleam routes things correctly but I don't know it.
    // feels like lustre probably has opinions on this.
    Model(auth.Authenticating), _ -> #(model, effect.none())
    Model(auth.Unauthenticated(_)), _ -> #(model, effect.none())
    Model(auth.WaitingForMagicLink(_)), _ -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  case model {
    Model(auth.Authenticating) ->
      auth_views.view_authenticating() |> element.map(AuthMsg)
    Model(auth.Unauthenticated(email)) ->
      auth_views.view_sign_in_button(email) |> element.map(AuthMsg)
    Model(auth.WaitingForMagicLink(email)) ->
      auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)
    Model(auth.Authenticated(email:, model: cat_counter)) ->
      html.div([], [
        auth_views.view_sign_out_button() |> element.map(AuthMsg),
        cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
      ])
  }
}

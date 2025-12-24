import auth_views
import cats
import gleam/result
import gleam/uri
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import stytch_ui_model

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Route {
  Wibble
  Wobble
  Auth
  Cats(cats.CatCounter)
}

type Model {
  Model(auth: stytch_ui_model.AuthModel, route: Route)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  let route =
    modem.initial_uri()
    |> result.map(fn(uri) { uri.path_segments(uri.path) })
    |> fn(path) {
      case path {
        Ok(["wibble"]) -> Wibble
        Ok(["wobble"]) -> Wobble
        Ok(["cats"]) -> Cats(cats.init_cat_counter())
        _ -> Auth
      }
    }
  #(
    Model(stytch_ui_model.new("http://localhost:3000/api"), route),
    effect.batch([
      stytch_ui_model.get_me(api_url) |> effect.map(AuthMsg),
      modem.init(on_url_change),
    ]),
  )
}

fn on_url_change(uri: uri.Uri) -> Msg {
  case uri.path_segments(uri.path) {
    ["wibble"] -> OnRouteChange(Wibble)
    ["wobble"] -> OnRouteChange(Wobble)
    // meant to be protected, so initializing Cats here feels wrong
    ["cats"] -> OnRouteChange(Cats(cats.init_cat_counter()))
    _ -> OnRouteChange(Auth)
  }
}

type Msg {
  CatMsg(cats.CatMsg)
  AuthMsg(stytch_ui_model.AuthMsg)
  OnRouteChange(Route)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  echo msg
  case model, msg {
    Model(auth_model, Auth), AuthMsg(auth_msg) -> {
      let #(next_auth, effect) =
        stytch_ui_model.update_auth(auth_model, auth_msg)
      #(Model(..model, auth: next_auth), effect.map(effect, AuthMsg))
    }

    Model(
      stytch_ui_model.AuthModel(api_url, stytch_ui_model.Authenticated(email:)),
      Cats(cat_counter),
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
          Cats(next_model),
        ),
        effect |> effect.map(CatMsg),
      )
    }

    Model(auth:, route: _), OnRouteChange(Wibble) -> #(
      Model(auth, Wibble),
      effect.none(),
    )

    Model(auth:, route: _), OnRouteChange(Wobble) -> #(
      Model(auth, Wobble),
      effect.none(),
    )

    Model(auth:, route: _), OnRouteChange(Auth) -> #(
      Model(auth, Auth),
      effect.none(),
    )

    Model(auth:, route: _), OnRouteChange(Cats(cat_counter)) -> #(
      Model(auth, Cats(cat_counter)),
      effect.none(),
    )

    // haven't decided best way to handle the "got a message that didn't match current state" cases.
    // panic seems heavy, but silent dropping seems bad too. (should be impossible but...)
    Model(stytch_ui_model.AuthModel(..), ..), AuthMsg(_) -> #(
      model,
      effect.none(),
    )

    Model(stytch_ui_model.AuthModel(..), ..), CatMsg(_) -> #(
      model,
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  let Model(stytch_ui_model.AuthModel(state:, ..), route:) = model
  echo route
  html.div([], [
    nav_bar(),
    case state, route {
      _, Wibble -> html.div([], [html.text("wibble")])

      _, Wobble -> html.div([], [html.text("wobble")])

      stytch_ui_model.Authenticated(email:), Cats(cat_counter) ->
        html.div([], [
          cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
        ])

      _, Cats(_) ->
        html.div([], [
          html.text("You must"),
          html.a([attribute.href("/auth")], [html.text("log in")]),
        ])

      stytch_ui_model.Authenticating, Auth ->
        auth_views.view_authenticating() |> element.map(AuthMsg)

      stytch_ui_model.Unauthenticated(email), Auth ->
        auth_views.view_sign_in_button(email) |> element.map(AuthMsg)

      stytch_ui_model.WaitingForMagicLink(email), Auth ->
        auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)

      stytch_ui_model.Authenticated(_), Auth ->
        html.div([], [html.text("logged in")])
    },
  ])
}

fn nav_bar() -> Element(Msg) {
  html.nav([], [
    html.a([attribute.href("/wibble")], [element.text("Go to wibble")]),
    html.a([attribute.href("/wobble")], [element.text("Go to wobble")]),
    html.a([attribute.href("/cats")], [element.text("Go to cats")]),
    auth_views.view_sign_out_button() |> element.map(AuthMsg),
  ])
}

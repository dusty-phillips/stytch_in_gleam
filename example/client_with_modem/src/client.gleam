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
  Cats
}

type RouteModel {
  EmptyModel
  CatsModel(cats.CatCounter)
}

type Model {
  Model(auth: stytch_ui_model.AuthModel, route: Route, model: RouteModel)
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
        Ok(["cats"]) -> Cats
        _ -> Auth
      }
    }
  #(
    Model(stytch_ui_model.new("http://localhost:3000/api"), route, EmptyModel),
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
    ["cats"] -> OnRouteChange(Cats)
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
    Model(auth_model, ..),
      AuthMsg(stytch_ui_model.UserClickedSignOut as auth_msg)
    -> {
      let #(next_auth, effect) =
        stytch_ui_model.update_auth(auth_model, auth_msg)
      #(
        Model(..model, auth: next_auth, model: EmptyModel),
        effect.map(effect, AuthMsg),
      )
    }

    Model(auth_model, Auth, ..), AuthMsg(auth_msg) -> {
      let #(next_auth, effect) =
        stytch_ui_model.update_auth(auth_model, auth_msg)
      #(Model(..model, auth: next_auth), effect.map(effect, AuthMsg))
    }

    Model(
      stytch_ui_model.AuthModel(state: stytch_ui_model.Authenticated(..), ..) as auth,
      Cats,
      CatsModel(cat_counter),
    ),
      CatMsg(cat_msg)
    -> {
      let #(next_model, effect) = cats.update_cat_counter(cat_counter, cat_msg)
      #(Model(auth, Cats, CatsModel(next_model)), effect |> effect.map(CatMsg))
    }

    Model(auth:, route: _, model: _), OnRouteChange(Wibble) -> #(
      Model(auth, Wibble, EmptyModel),
      effect.none(),
    )

    Model(auth:, route: _, model: _), OnRouteChange(Wobble) -> #(
      Model(auth, Wobble, EmptyModel),
      effect.none(),
    )

    Model(auth:, route: _, model: _), OnRouteChange(Auth) -> #(
      Model(auth, Auth, EmptyModel),
      effect.none(),
    )

    Model(
      stytch_ui_model.AuthModel(state: stytch_ui_model.Authenticated(..), ..) as auth,
      route: _,
      model: _,
    ),
      OnRouteChange(Cats)
    -> #(Model(auth, Cats, CatsModel(cats.init_cat_counter())), effect.none())

    Model(auth:, route: _, model: _), OnRouteChange(Cats) -> #(
      Model(auth, Cats, EmptyModel),
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
  let Model(stytch_ui_model.AuthModel(state:, ..), route:, model: data) = model
  html.div([], [
    nav_bar(),
    case state, route, data {
      _, Wibble, _ -> html.div([], [html.text("wibble")])

      _, Wobble, _ -> html.div([], [html.text("wobble")])

      stytch_ui_model.Authenticated(email:), Cats, CatsModel(cat_counter) ->
        html.div([], [
          cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
        ])

      _, Cats, EmptyModel ->
        html.div([], [
          html.text("You must"),
          html.a([attribute.href("/auth")], [html.text("log in")]),
        ])

      // Really don't like that these states can be modelled, even if they
      // are not intended to be possible
      _, Cats, CatsModel(_) ->
        panic as "Unexpected CatsModel state in view on Cats route"
      _, Auth, CatsModel(_) ->
        panic as "Unexpected CatsModel state in view on Auth route"

      stytch_ui_model.Authenticating, Auth, EmptyModel ->
        auth_views.view_authenticating() |> element.map(AuthMsg)

      stytch_ui_model.Unauthenticated(email), Auth, EmptyModel ->
        auth_views.view_sign_in_button(email) |> element.map(AuthMsg)

      stytch_ui_model.WaitingForMagicLink(email), Auth, EmptyModel ->
        auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)

      stytch_ui_model.Authenticated(_), Auth, EmptyModel ->
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

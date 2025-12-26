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
  Cats
}

type Page {
  WibblePage
  WobblePage
  CatsPage(cats.CatCounter)
}

type AuthGuard {
  Unknown(route: Route)
  RequiresAuth(return_to: Route)
  Show(Page)
}

type Model {
  Model(auth: stytch_ui_model.AuthModel, route: Route, page: AuthGuard)
}

type Msg {
  CatMsg(cats.CatMsg)
  AuthMsg(stytch_ui_model.AuthMsg)
  RouteChanged(Route)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  let route =
    modem.initial_uri()
    |> result.map(path_to_route)
    |> result.unwrap(todo as "404 page")

  #(
    Model(
      stytch_ui_model.new("http://localhost:3000/api"),
      route,
      Unknown(route),
    ),
    effect.batch([
      stytch_ui_model.get_me(api_url) |> effect.map(AuthMsg),
      modem.init(on_url_change),
    ]),
  )
}

fn on_url_change(uri: uri.Uri) -> Msg {
  uri |> path_to_route |> RouteChanged
}

fn path_to_route(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["wibble"] -> Wibble
    ["wobble"] -> Wobble
    ["cats"] -> Cats
    _ -> todo as "404 page"
  }
}

fn set_page_from_route(model: Model, route: Route) -> Model {
  let page = case
    stytch_ui_model.is_authenticated(model.auth),
    route,
    model.page
  {
    True, Cats, Show(CatsPage(_)) -> model.page
    True, Cats, _ -> Show(CatsPage(cats.init_cat_counter()))
    _, Wibble, _ -> Show(WibblePage)
    _, Wobble, _ -> Show(WobblePage)
    False, Cats, _ -> RequiresAuth(route)
  }

  Model(..model, route:, page:)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  echo msg
  case msg {
    RouteChanged(route) -> #(set_page_from_route(model, route), effect.none())

    AuthMsg(auth_msg) -> {
      let #(next_auth, auth_effect) =
        stytch_ui_model.update_auth(model.auth, auth_msg)

      #(
        set_page_from_route(Model(..model, auth: next_auth), model.route),
        auth_effect |> effect.map(AuthMsg),
      )
    }

    CatMsg(cat_msg) -> {
      echo cat_msg
      echo model.page

      case model.page {
        Show(CatsPage(cat_counter)) -> {
          let #(next_cats, cats_effect) =
            cats.update_cat_counter(cat_counter, cat_msg)

          #(
            Model(..model, page: Show(CatsPage(next_cats))),
            cats_effect |> effect.map(CatMsg),
          )
        }
        _ -> #(model, effect.none())
      }
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  let Model(stytch_ui_model.AuthModel(state:, ..), page:, ..) = model
  html.div([], [
    nav_bar(model.auth),
    case page {
      Show(WibblePage) -> html.div([], [html.text("wibble")])

      Show(WobblePage) -> html.div([], [html.text("wobble")])

      Show(CatsPage(cat_counter)) -> {
        let email = case state {
          stytch_ui_model.Authenticated(email) -> email
          _ -> "Esteemed Cat Lover"
        }
        html.div([], [
          cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
        ])
      }

      Unknown(_) -> html.div([], [html.text("Loading...")])

      RequiresAuth(_) ->
        case state {
          stytch_ui_model.Authenticating ->
            auth_views.view_authenticating() |> element.map(AuthMsg)

          stytch_ui_model.Unauthenticated(email) ->
            auth_views.view_sign_in_button(email) |> element.map(AuthMsg)

          stytch_ui_model.WaitingForMagicLink(email) ->
            auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)

          stytch_ui_model.Authenticated(email) ->
            html.div([], [html.text("Welcome " <> email)])
        }
    },
  ])
}

fn nav_bar(auth: stytch_ui_model.AuthModel) -> Element(Msg) {
  html.nav([], [
    html.a([attribute.href("/wibble")], [element.text("Go to wibble")]),
    html.a([attribute.href("/wobble")], [element.text("Go to wobble")]),
    html.a([attribute.href("/cats")], [element.text("Go to cats")]),
    case stytch_ui_model.is_authenticated(auth) {
      True -> auth_views.view_sign_out_button() |> element.map(AuthMsg)
      False -> element.none()
    },
  ])
}

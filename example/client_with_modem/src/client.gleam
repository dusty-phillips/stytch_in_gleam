import auth_views
import cats
import gleam/list
import gleam/result
import gleam/uri
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import stytch_ui_model as stytch

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
  Model(auth: stytch.AuthModel, route: Route, page: AuthGuard)
}

type Msg {
  CatMsg(cats.CatMsg)
  AuthMsg(stytch.AuthMsg)
  RouteChanged(Route)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let api_url = "http://localhost:3000/api"
  let route =
    modem.initial_uri()
    |> result.map(path_to_route)
    |> result.lazy_unwrap(fn() { todo as "404 page" })

  #(
    Model(stytch.new(api_url, stytch.MagicLink), route, Unknown(route)),
    effect.batch([
      stytch.get_me(api_url) |> effect.map(AuthMsg),
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
  let page = case stytch.is_authenticated(model.auth), route, model.page {
    True, Cats, Show(CatsPage(_)) -> model.page
    True, Cats, _ -> Show(CatsPage(cats.init_cat_counter()))
    _, Wibble, _ -> Show(WibblePage)
    _, Wobble, _ -> Show(WobblePage)
    False, Cats, _ -> RequiresAuth(route)
  }

  Model(..model, route:, page:)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RouteChanged(route) -> #(set_page_from_route(model, route), effect.none())

    AuthMsg(auth_msg) -> {
      let #(next_auth, auth_effect) = stytch.update(model.auth, auth_msg)

      #(
        set_page_from_route(Model(..model, auth: next_auth), model.route),
        auth_effect |> effect.map(AuthMsg),
      )
    }

    CatMsg(cat_msg) -> {
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
  let Model(stytch.AuthModel(state:, ..), page:, ..) = model
  html.div([], [
    nav_bar(model.auth),
    case page {
      Show(WibblePage) -> html.div([], [html.text("wibble")])

      Show(WobblePage) -> html.div([], [html.text("wobble")])

      Show(CatsPage(cat_counter)) -> {
        let email = case state {
          stytch.Authenticated(user) ->
            user.emails
            |> list.first
            |> result.map(fn(email) { email.email })
            |> result.unwrap("Esteemed Cat Lover")
          _ -> "Esteemed Cat Lover"
        }
        html.div([], [
          cats.view_cat_model(email, cat_counter) |> element.map(CatMsg),
        ])
      }

      Unknown(_) -> html.div([], [html.text("Loading...")])

      RequiresAuth(_) ->
        case state {
          stytch.Authenticating ->
            auth_views.view_authenticating() |> element.map(AuthMsg)

          stytch.Unauthenticated(email) ->
            auth_views.view_sign_in_button(email) |> element.map(AuthMsg)

          stytch.WaitingForMagicLink(email) ->
            auth_views.view_magic_link_sent(email) |> element.map(AuthMsg)

          stytch.Authenticated(user) ->
            html.div([], [
              html.text(
                "Welcome "
                <> user.emails
                |> list.first
                |> result.map(fn(email) { email.email })
                |> result.unwrap("Potential Cat Lover"),
              ),
            ])

          stytch.PasscodeState(..) -> panic as "passcode auth not enabled"
        }
    },
  ])
}

fn nav_bar(auth: stytch.AuthModel) -> Element(Msg) {
  html.nav([], [
    html.a([attribute.href("/wibble")], [element.text("Go to wibble")]),
    html.a([attribute.href("/wobble")], [element.text("Go to wobble")]),
    html.a([attribute.href("/cats")], [element.text("Go to cats")]),
    case stytch.is_authenticated(auth) {
      True -> auth_views.view_sign_out_button() |> element.map(AuthMsg)
      False -> element.none()
    },
  ])
}

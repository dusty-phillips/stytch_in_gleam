import gleam/dynamic/decode
import gleam/int
import gleam/list
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

pub type CatCounter {
  CatCounter(total: Int, cats: List(Cat))
}

pub type Cat {
  Cat(id: String, url: String)
}

pub type CatMsg {
  UserClickedAddCat
  UserClickedRemoveCat
  ApiReturnedCats(Result(List(Cat), rsvp.Error))
}

pub fn init_cat_counter() {
  CatCounter(total: 0, cats: [])
}

pub fn update_cat_counter(
  cat_counter: CatCounter,
  msg: CatMsg,
) -> #(CatCounter, Effect(CatMsg)) {
  case msg {
    UserClickedAddCat -> #(
      CatCounter(..cat_counter, total: cat_counter.total + 1),
      get_cat(),
    )
    UserClickedRemoveCat -> #(
      CatCounter(
        total: cat_counter.total - 1,
        cats: list.drop(cat_counter.cats, 1),
      ),
      effect.none(),
    )
    ApiReturnedCats(Ok(cats)) -> #(
      CatCounter(..cat_counter, cats: list.append(cat_counter.cats, cats)),
      effect.none(),
    )
    ApiReturnedCats(Error(_)) -> #(cat_counter, effect.none())
  }
}

pub fn view_cat_model(email, cat_counter: CatCounter) -> Element(CatMsg) {
  html.div([], [
    html.h1([], [html.text("Welcome " <> email)]),
    html.button([event.on_click(UserClickedAddCat)], [
      html.text("Add cat"),
    ]),
    html.p([], [html.text(int.to_string(cat_counter.total))]),
    html.button([event.on_click(UserClickedRemoveCat)], [
      html.text("Remove cat"),
    ]),

    html.div(
      [],
      list.map(cat_counter.cats, fn(cat) {
        html.img([
          attribute.src(cat.url),
          attribute.width(400),
          attribute.height(400),
        ])
      }),
    ),
  ])
}

// API calls

fn get_cat() -> Effect(CatMsg) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use url <- decode.field("url", decode.string)
    decode.success(Cat(id:, url:))
  }

  let url = "https://api.thecatapi.com/v1/images/search"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedCats)

  rsvp.get(url, handler)
}

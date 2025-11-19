import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import stytch_ui_model

pub fn view_sign_in_button(
  email: String,
) -> element.Element(stytch_ui_model.AuthMsg) {
  html.div([], [
    html.input([
      attribute.value(email),
      attribute.placeholder("Enter your e-mail"),
      event.on_input(fn(email) { stytch_ui_model.UserUpdatedEmail(email) }),
    ]),
    html.button([event.on_click(stytch_ui_model.UserClickedSendMagicLink)], [
      html.text("Sign Up or Log In"),
    ]),
  ])
}

pub fn view_sign_out_button() -> element.Element(stytch_ui_model.AuthMsg) {
  html.button([event.on_click(stytch_ui_model.UserClickedSignOut)], [
    html.text("Sign Out"),
  ])
}

pub fn view_magic_link_sent(
  email: String,
) -> element.Element(stytch_ui_model.AuthMsg) {
  html.div([], [html.text("Please click the link sent to " <> email)])
}

pub fn view_authenticating() -> element.Element(stytch_ui_model.AuthMsg) {
  html.div([], [html.text("Authenticating...")])
}

import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import stytch_ui_model as stytch

pub fn view_sign_in_button(email: String) -> element.Element(stytch.AuthMsg) {
  html.div([], [
    html.input([
      attribute.value(email),
      attribute.placeholder("Enter your e-mail"),
      event.on_keyup(fn(key) {
        stytch.UserPressedKeyOnEmail(key)
      }),
      event.on_input(fn(value) {
        stytch.UserUpdatedEmail(value)
      }),
    ]),
    html.button(
      [event.on_click(stytch.UserClickedSend)],
      [
        html.text("Sign Up or Log In"),
      ],
    ),
  ])
}

pub fn view_sign_out_button() -> element.Element(stytch.AuthMsg) {
  html.button(
    [event.on_click(stytch.UserClickedSignOut)],
    [
      html.text("Sign Out"),
    ],
  )
}

pub fn view_sending_passcode(email: String) -> element.Element(stytch.AuthMsg) {
  html.div([], [html.text("Sending one time passcode to " <> email)])
}

pub fn view_passcode_sent(
  email: String,
  passcode: String,
) -> element.Element(stytch.AuthMsg) {
  html.div([], [
    html.text("Please enter the passcode sent to " <> email),
    html.input([
      attribute.value(passcode),
      event.on_input(fn(value) {
        stytch.UserUpdatedPasscode(value)
      }),
    ]),
    html.button(
      [
        event.on_click(
          stytch.UserClickedPasscodeSend,
        ),
      ],
      [html.text("Verify Passcode")],
    ),
  ])
}

pub fn view_authenticating() -> element.Element(stytch.AuthMsg) {
  html.div([], [html.text("Authenticating...")])
}

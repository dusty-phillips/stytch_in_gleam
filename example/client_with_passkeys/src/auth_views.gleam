import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import stytch_codecs
import stytch_ui_model as stytch

pub fn view_sign_in_button(email: String) -> element.Element(stytch.AuthMsg) {
  html.div([], [
    html.input([
      attribute.value(email),
      attribute.placeholder("Enter your e-mail"),
      event.on_keyup(fn(key) { stytch.UserPressedKeyOnEmail(key) }),
      event.on_input(fn(value) { stytch.UserUpdatedEmail(value) }),
    ]),
    html.button([event.on_click(stytch.UserClickedSend)], [
      html.text("Sign Up or Log In"),
    ]),
    html.button([event.on_click(stytch.UserClickedPasskeySignIn)], [
      html.text("Sign in with a passkey"),
    ]),
  ])
}

pub fn view_sign_out_button() -> element.Element(stytch.AuthMsg) {
  html.button([event.on_click(stytch.UserClickedSignOut)], [
    html.text("Sign Out"),
  ])
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
      event.on_input(fn(value) { stytch.UserUpdatedPasscode(value) }),
    ]),
    html.button(
      [
        event.on_click(stytch.UserClickedPasscodeSend),
      ],
      [html.text("Verify Passcode")],
    ),
  ])
}

pub fn view_authenticating() -> element.Element(stytch.AuthMsg) {
  html.div([], [html.text("Authenticating...")])
}

pub fn view_passkeys(
  user: stytch_codecs.StytchUser,
  passkey_state: stytch.PasskeyState,
) -> element.Element(stytch.AuthMsg) {
  let registrations = list_registration_items(user.webauthn_registrations)

  let status = case passkey_state {
    stytch.PasskeyIdle -> element.none()
    stytch.StartingPasskeyRegister ->
      html.p([], [html.text("Contacting server...")])
    stytch.CreatingPasskeyCredential ->
      html.p([], [html.text("Follow your browser's prompt to create a passkey...")])
    stytch.FinishingPasskeyRegister ->
      html.p([], [html.text("Finishing passkey registration...")])
    stytch.PasskeyRegisterFailed(reason) ->
      html.p([], [html.text("Passkey registration failed: " <> reason)])
  }

  html.div([], [
    html.h2([], [html.text("Your passkeys")]),
    registrations,
    status,
    html.button([event.on_click(stytch.UserClickedAddPasskey)], [
      html.text("Add passkey"),
    ]),
  ])
}

fn list_registration_items(
  registrations: List(stytch_codecs.WebAuthnRegistration),
) -> element.Element(stytch.AuthMsg) {
  case registrations {
    [] -> html.p([], [html.text("No passkeys registered yet.")])
    _ ->
      html.ul([], list.map(registrations, view_registration_item))
  }
}

fn view_registration_item(
  registration: stytch_codecs.WebAuthnRegistration,
) -> element.Element(stytch.AuthMsg) {
  html.li([], [
    html.strong([], [html.text(registration.name)]),
    html.dl([], [
      html.dt([], [html.text("Device")]),
      html.dd([], [html.text(user_agent_or_unknown(registration.user_agent))]),
      html.dt([], [html.text("Type")]),
      html.dd([], [html.text(authenticator_type_label(registration))]),
      html.dt([], [html.text("Domain")]),
      html.dd([], [html.text(registration.domain)]),
      html.dt([], [html.text("Verified")]),
      html.dd([], [html.text(verified_label(registration.verified))]),
    ]),
  ])
}

fn user_agent_or_unknown(user_agent: String) -> String {
  case user_agent {
    "" -> "Unknown device"
    _ -> user_agent
  }
}

fn authenticator_type_label(
  registration: stytch_codecs.WebAuthnRegistration,
) -> String {
  case registration.authenticator_type {
    "platform" -> "This device (platform authenticator)"
    "cross-platform" -> "Roaming authenticator (e.g. security key)"
    _ -> registration.authenticator_type
  }
}

fn verified_label(verified: Bool) -> String {
  case verified {
    True -> "Yes"
    False -> "No"
  }
}

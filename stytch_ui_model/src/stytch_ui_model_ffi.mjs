// Small glue helper that plinth does not provide. The WebAuthn ceremony
// itself is handled by plinth/browser/credentials/public_key.

// gleam_json has no Dynamic -> Json coercion, but Json is a zero-cost wrapper
// at runtime, so parsing straight to the opaque Json type here is safe.
export function parseJson(jsonString) {
  return JSON.parse(jsonString);
}

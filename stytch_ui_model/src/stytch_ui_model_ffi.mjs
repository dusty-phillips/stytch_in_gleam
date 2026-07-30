// Small glue helper that plinth does not provide. The WebAuthn ceremony
// itself is handled by plinth/browser/credentials/public_key.

import { Ok, Error as GleamError } from "./gleam.mjs";

// gleam_json has no Dynamic -> Json coercion, but Json is a zero-cost wrapper
// at runtime, so returning the parsed value as the opaque Json type is safe.
// Returns a Gleam Result so malformed input from the server cannot throw
// inside the Lustre runtime.
export function parseJson(jsonString) {
  try {
    return new Ok(JSON.parse(jsonString));
  } catch (error) {
    return new GleamError(String(error));
  }
}

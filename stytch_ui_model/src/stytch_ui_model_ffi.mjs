import { Ok, Error as GleamError } from "./gleam.mjs";

// nasty coercion function
export function parseJson(jsonString) {
  try {
    return new Ok(JSON.parse(jsonString));
  } catch (error) {
    return new GleamError(String(error));
  }
}

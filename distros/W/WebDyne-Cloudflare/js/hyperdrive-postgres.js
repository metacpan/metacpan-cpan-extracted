import { decodeParameter, encodeResult } from "./hyperdrive-codec.js";

function databaseError(error) {
  // System codes such as EPIPE also have five uppercase characters. They are
  // not SQLSTATEs and their messages can contain connection details.
  return !error.local && typeof error.code === "string" && /^[0-9A-Z]{5}$/.test(error.code)
    && /^(?:[0-9]{2}|0[A-Z]|P0|F0|HV|XX)/.test(error.code);
}

function publicError(error) {
  if (!error || typeof error !== "object") error = {};
  const database = databaseError(error);
  const result = {
    name: database ? "DATABASE_ERROR" : "HYPERDRIVE_ERROR",
    code: database || error.local ? error.code : "CONNECTION_ERROR",
    // Connection errors can contain connection strings; never expose their text.
    message: database || error.local ? error.message : "PostgreSQL connection failed",
  };
  if (database) for (const key of ["severity", "detail", "hint", "position", "schema", "table", "column", "constraint"]) {
    if (typeof error[key] === "string") result[key] = error[key];
  }
  if (error.outcomeUnknown) result.outcomeUnknown = true;
  return result;
}

export const postgresProtocol = Object.freeze({ name: "postgres", decodeParameter, encodeResult, databaseError, publicError });

const bindingPattern = /^[A-Z_][A-Z0-9_]*$/;

export function storageBindingNames(value, service) {
  if (value === undefined || value === null || value === "") return [];
  const names = Array.isArray(value) ? value : String(value).split(",");
  return [...new Set(names.map((name) => String(name).trim()).filter(Boolean).map((name) => {
    if (!bindingPattern.test(name)) throw new TypeError(`Invalid ${service} binding name: ${name}`);
    return name;
  }))];
}

export function scopeExtensions(scope, service) {
  if (!scope || typeof scope !== "object" || Array.isArray(scope)) {
    throw new TypeError(`${service} capability requires a PAGI scope object`);
  }
  if (scope.extensions === undefined) scope.extensions = {};
  else if (!scope.extensions || typeof scope.extensions !== "object" || Array.isArray(scope.extensions)) {
    throw new TypeError("PAGI scope extensions must be an object");
  }
  return scope.extensions;
}

export function createCapability(capabilities, tokenFactory, service) {
  const capability = tokenFactory();
  if (typeof capability !== "string" || capability.length < 8 || capabilities.has(capability)) {
    throw new Error(`${service} capability token factory returned an invalid or duplicate token`);
  }
  return capability;
}

export function bytesToBase64(bytes) {
  let binary = "";
  const view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  for (let offset = 0; offset < view.length; offset += 0x8000) {
    binary += String.fromCharCode(...view.subarray(offset, offset + 0x8000));
  }
  return btoa(binary);
}

export function base64ToBytes(encoded) {
  const binary = atob(encoded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

export function encodeBytes(value) {
  if (value instanceof ArrayBuffer) {
    return { type: "bytes", base64: bytesToBase64(value) };
  }
  if (ArrayBuffer.isView(value)) {
    return {
      type: "bytes",
      base64: bytesToBase64(new Uint8Array(value.buffer, value.byteOffset, value.byteLength)),
    };
  }
  return value;
}

export function decodeBytes(value, description, maxBytes) {
  if (!value || typeof value !== "object" || Array.isArray(value)
    || value.type !== "bytes" || typeof value.base64 !== "string") {
    throw new TypeError(`${description} must be text or an explicit bytes envelope`);
  }
  const bytes = base64ToBytes(value.base64);
  if (bytes.byteLength > maxBytes) throw new RangeError(`${description} exceeds the configured byte limit`);
  return bytes;
}

export function storageErrorResponse(error, fallbackName) {
  const cause = error?.cause;
  const code = error?.code ?? cause?.code;
  return {
    ok: false,
    error: {
      name: typeof error?.name === "string" ? error.name : fallbackName,
      message: typeof error?.message === "string" ? error.message : String(error),
      ...(typeof code === "string" || typeof code === "number" ? { code } : {}),
      ...(typeof cause === "string" ? { cause } : cause?.message ? { cause: cause.message } : {}),
    },
  };
}

export function positiveInteger(value, description, { minimum = 1, maximum } = {}) {
  if (!Number.isInteger(value) || value < minimum || (maximum !== undefined && value > maximum)) {
    throw new TypeError(`${description} must be an integer between ${minimum} and ${maximum ?? "the supported maximum"}`);
  }
  return value;
}

export function plainObject(value, description) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new TypeError(`${description} must be an object`);
  }
  return value;
}

// Protocol v1 uses tagged cells; JSON documents are always PostgreSQL text.
export function protocolError(message, code = "PROTOCOL_ERROR") {
  return Object.assign(new Error(message), { code, local: true });
}

export function decodeParameter(cell) {
  if (!Array.isArray(cell)) throw protocolError("Invalid parameter envelope");
  const [type, value] = cell;
  if (type === "null" && cell.length === 1) return null;
  if (cell.length !== 2) throw protocolError("Invalid parameter envelope");
  if (type === "text" && typeof value === "string" && !value.includes("\0")) return value;
  if (type === "bool" && typeof value === "boolean") return value;
  if (type === "bytes" && typeof value === "string" && /^(?:[0-9a-f]{2})*$/.test(value)) {
    // PostgreSQL bytea hex input avoids depending on Buffer in the generic bridge.
    return `\\x${value}`;
  }
  throw protocolError("Invalid parameter type or value");
}

export function encodeCell(value, oid) {
  if (value === null) return ["null"];
  if (typeof value !== "string") throw protocolError("Driver must return PostgreSQL text values");
  if (oid === 16) {
    if (value !== "t" && value !== "f") throw protocolError("Invalid PostgreSQL boolean");
    return ["bool", value === "t"];
  }
  if (oid === 17) {
    if (!/^\\x(?:[0-9a-f]{2})*$/.test(value)) throw protocolError("Expected PostgreSQL hex bytea output");
    return ["bytes", value.slice(2)];
  }
  if ([21, 23, 26].includes(oid)) {
    const number = Number(value);
    if (!/^-?\d+$/.test(value) || !Number.isSafeInteger(number)) throw protocolError("Invalid PostgreSQL integer");
    return ["number", number];
  }
  if ([700, 701].includes(oid)) {
    if (["NaN", "Infinity", "-Infinity"].includes(value)) return ["special", value];
    const number = Number(value);
    if (!Number.isFinite(number) || value.trim() === "") throw protocolError("Invalid PostgreSQL float");
    return ["number", number];
  }
  return ["text", value];
}

export function encodeResult(result, limits) {
  const columns = result.fields.map(({ name, dataTypeID }) => ({ name, oid: dataTypeID }));
  const rows = result.rows.map(row => {
    if (row.length !== columns.length) throw protocolError("Driver returned inconsistent columns");
    return row.map((value, index) => encodeCell(value, columns[index].oid));
  });
  const encoded = { columns, rows, count: result.rowCount, command: result.command };
  if (rows.length > limits.maxRows || new TextEncoder().encode(JSON.stringify(encoded)).length > limits.maxResultBytes) {
    throw protocolError("Query result limit exceeded", "RESULT_LIMIT");
  }
  return encoded;
}

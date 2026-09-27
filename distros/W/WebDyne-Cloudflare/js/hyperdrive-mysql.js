import mysql from "mysql2";
import { Buffer } from "node:buffer";
import { protocolError } from "./hyperdrive-codec.js";

function decodeParameter(cell) {
  if (!Array.isArray(cell)) throw protocolError("Invalid parameter envelope");
  const [type, value] = cell;
  if (type === "null" && cell.length === 1) return null;
  if (cell.length !== 2) throw protocolError("Invalid parameter envelope");
  if (type === "text" && typeof value === "string" && !value.includes("\0")) return value;
  if (type === "bool" && typeof value === "boolean") return value;
  if (type === "bytes" && typeof value === "string" && /^(?:[0-9a-f]{2})*$/.test(value)) return Buffer.from(value, "hex");
  throw protocolError("Invalid parameter type or value");
}

// Hex literals avoid SQL-mode-dependent string escaping. Only placeholders in
// SQL code are substituted: mysql2.format also substitutes inside quoted text.
function literal(value) {
  if (value === null) return "NULL";
  if (typeof value === "boolean") return value ? "1" : "0";
  if (Buffer.isBuffer(value)) return `X'${value.toString("hex")}'`;
  if (typeof value === "string") return `CONVERT(X'${Buffer.from(value, "utf8").toString("hex")}' USING utf8mb4)`;
  throw protocolError("Invalid MySQL parameter");
}

export function mysqlSql(sql, values, { transaction = false, control = false } = {}) {
  let output = "", index = 0, parameter = 0, ended = false;
  const words = [], tokens = [];
  while (index < sql.length) {
    const char = sql[index];
    if (/\s/.test(char)) { output += char; index++; continue; }
    if (char === "#" || (sql.startsWith("--", index) && /[\s\x00-\x20]/.test(sql[index + 2] ?? "\n"))) {
      const end = sql.indexOf("\n", index);
      const next = end < 0 ? sql.length : end;
      output += sql.slice(index, next); index = next; continue;
    }
    if (sql.startsWith("/*", index)) {
      if (/^\/\*(?:!|M!)/i.test(sql.slice(index))) throw protocolError("Executable MySQL comments are unsupported", "UNSUPPORTED_SQL");
      const end = sql.indexOf("*/", index + 2);
      if (end < 0) throw protocolError("Unterminated SQL comment");
      output += sql.slice(index, end + 2); index = end + 2; continue;
    }
    if (ended) throw protocolError("Multiple SQL statements are unsupported", "UNSUPPORTED_SQL");
    if (["'", '"', "`"].includes(char)) {
      const start = index++;
      let closed = false;
      while (index < sql.length) {
        if (sql[index] === "\\") throw protocolError("Bind strings containing backslashes instead of quoting them in SQL", "UNSUPPORTED_SQL");
        if (sql[index++] === char) {
          if (sql[index] === char) { index++; continue; }
          closed = true; break;
        }
      }
      if (!closed) throw protocolError("Unterminated SQL quote");
      output += sql.slice(start, index); tokens.push("literal"); continue;
    }
    if (char === "?") {
      if (sql[index + 1] === "?") throw protocolError("Identifier placeholders are unsupported", "UNSUPPORTED_SQL");
      if (parameter >= values.length) throw protocolError("MySQL placeholder count does not match parameters", "PARAMETER_COUNT");
      const value = values[parameter++];
      const limit = ["LIMIT", "OFFSET"].includes(tokens.at(-1))
        || (tokens.at(-1) === "," && tokens.at(-3) === "LIMIT");
      if (limit) {
        if (typeof value !== "string" || !/^(?:0|[1-9][0-9]*)$/.test(value)
          || BigInt(value) > 18446744073709551615n) throw protocolError("MySQL LIMIT/OFFSET requires an unsigned integer", "PARAMETER_TYPE");
        output += value;
      } else output += literal(value);
      tokens.push("?"); index++; continue;
    }
    if (char === ";") ended = true;
    const word = /^[a-z_][a-z0-9_]*/i.exec(sql.slice(index));
    if (word) { words.push(word[0].toUpperCase()); tokens.push(word[0].toUpperCase()); output += word[0]; index += word[0].length; }
    else {
      const number = /^[0-9]+/.exec(sql.slice(index));
      if (number) { output += number[0]; tokens.push(number[0]); index += number[0].length; }
      else { output += char; tokens.push(char); index++; }
    }
  }
  if (parameter !== values.length) throw protocolError("MySQL placeholder count does not match parameters", "PARAMETER_COUNT");
  const command = words[0];
  const readsAndWrites = ["SELECT", "INSERT", "UPDATE", "DELETE", "REPLACE", "WITH", "EXPLAIN", "SHOW", "DESCRIBE", "DESC"];
  const ddl = ["CREATE", "ALTER", "DROP", "TRUNCATE", "RENAME", "ANALYZE", "OPTIMIZE", "CHECK"];
  if (!control && !readsAndWrites.includes(command) && !ddl.includes(command)) throw protocolError("Unsupported MySQL statement; use transaction methods for transaction control", "UNSUPPORTED_SQL");
  // These operations can commit implicitly, defeating rollback guarantees.
  if (!control && transaction && ddl.includes(command)) throw protocolError("MySQL implicit-commit statements are unsupported in transactions", "TRANSACTION_CONTROL");
  return { sql: output, command };
}

function encodeCell(value, field) {
  if (value === null) return ["null"];
  if (Buffer.isBuffer(value)) return ["bytes", value.toString("hex")];
  if (typeof value === "number" && Number.isFinite(value)) return ["number", value];
  if (typeof value === "string") return ["text", value];
  throw protocolError(`Unsupported MySQL result type ${field.columnType}`);
}

function encodeResult(result, limits) {
  const columns = result.fields.map(field => ({ name: field.name, type: field.columnType,
    driver: "mysql", flags: field.flags, charset: field.characterSet }));
  const rows = result.rows.map(row => {
    if (row.length !== columns.length) throw protocolError("Driver returned inconsistent columns");
    return row.map((value, index) => encodeCell(value, result.fields[index]));
  });
  const encoded = { columns, rows, count: result.rowCount, command: result.command };
  if (result.insertId !== undefined) encoded.insert_id = String(result.insertId);
  if (result.affectedRows !== undefined) encoded.affected_rows = result.affectedRows;
  if (result.warningStatus !== undefined) encoded.warning_count = result.warningStatus;
  if (rows.length > limits.maxRows || Buffer.byteLength(JSON.stringify(encoded)) > limits.maxResultBytes) throw protocolError("Query result limit exceeded", "RESULT_LIMIT");
  return encoded;
}

function databaseError(error) {
  return !error?.local && Number.isInteger(error?.errno) && typeof error?.code === "string"
    && /^ER_/.test(error.code) && /^[0-9A-Z]{5}$/.test(error.sqlState ?? "") && !error.fatal && !/^08/.test(error.sqlState);
}
function publicError(error) {
  const database = databaseError(error);
  return { name: database ? "DATABASE_ERROR" : "HYPERDRIVE_ERROR",
    code: database || error?.local ? error.code : "CONNECTION_ERROR",
    message: database ? (error.sqlMessage || "MySQL query failed") : error?.local ? error.message : "MySQL connection failed",
    ...(database ? { sqlstate: error.sqlState, errno: error.errno } : {}),
    ...(error?.outcomeUnknown ? { outcomeUnknown: true } : {}) };
}
export const mysqlProtocol = Object.freeze({ name: "mysql", decodeParameter, encodeResult, databaseError, publicError,
  validateQuery: (sql, values, transaction) => mysqlSql(sql, values, { transaction }) });

// Request-owned connection; Hyperdrive supplies origin pooling. Stream rows to
// enforce limits during collection, with static parsers for the Workers runtime.
export function createMysqlClient({ connectionString, limits, onError }, { createConnection = mysql.createConnection } = {}) {
  const url = new URL(connectionString);
  let client, destroyed = false, closed;
  const transportClosed = new Promise(resolve => { closed = resolve; });
  const destroy = () => {
    if (destroyed) return;
    destroyed = true;
    // mysql2.destroy() only half-closes its socket. Force transport destruction
    // for a deadline/overflow and await close before releasing request ownership.
    client?.destroy();
    client?.stream.destroy();
  };
  return {
    connect() {
      if (destroyed) return Promise.reject(protocolError("Connection closed", "CONNECTION_CLOSED"));
      client = createConnection({ host: url.hostname, port: Number(url.port || 3306),
        user: decodeURIComponent(url.username), password: decodeURIComponent(url.password),
        database: decodeURIComponent(url.pathname.slice(1)), charset: "utf8mb4", disableEval: true,
        rowsAsArray: true, supportBigNumbers: true, bigNumberStrings: true,
        dateStrings: true, jsonStrings: true, multipleStatements: false,
        flags: ["-LOCAL_FILES"], connectTimeout: limits.connectTimeoutMs });
      client.stream.once("close", closed);
      client.on("error", onError);
      return new Promise((resolve, reject) => client.connect(error => { if (error) { error.fatal = true; reject(error); } else resolve(); }));
    },
    destroy,
    close: () => !client ? Promise.resolve() : destroyed ? transportClosed
      : Promise.all([transportClosed, new Promise((resolve, reject) => client.end(error => error ? reject(error) : resolve()))]),
    query({ text, values, limits: queryLimits }) {
      const { sql, command } = mysqlSql(text, values, { control: ["BEGIN", "COMMIT", "ROLLBACK"].includes(text) });
      return new Promise((resolve, reject) => {
        const rows = []; let fields = [], header, bytes = 0, failed = false, resultSets = 0;
        const fail = error => { if (!failed) { failed = true; reject(error); if (error.local) destroy(); } };
        const query = client.query({ sql, rowsAsArray: true });
        query.on("fields", value => {
          if (!value) return;
          if (++resultSets > 1) return fail(protocolError("Multiple result sets are unsupported", "UNSUPPORTED_SQL"));
          fields = value;
        });
        query.on("result", row => {
          if (failed) return;
          try {
            if (!Array.isArray(row)) { header = row; return; }
            bytes += Buffer.byteLength(JSON.stringify(row.map((value, index) => encodeCell(value, fields[index])))) + 1;
            if (rows.length >= queryLimits.maxRows || bytes > queryLimits.maxResultBytes) throw protocolError("Query result limit exceeded", "RESULT_LIMIT");
            rows.push(row);
          } catch (error) { fail(error); }
        });
        query.on("error", fail);
        query.on("end", () => {
          if (!failed) resolve({ fields, rows, rowCount: header?.affectedRows ?? rows.length, command,
            ...(header ? { insertId: header.insertId, affectedRows: header.affectedRows, warningStatus: header.warningStatus } : {}) });
        });
      });
    },
  };
}

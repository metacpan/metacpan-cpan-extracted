import pg from "pg";
import { encodeCell, protocolError } from "./hyperdrive-codec.js";

// Keep pg's event/stream APIs here. The host and Perl protocol do not depend on
// node-postgres. Pin pg and exercise this adapter when upgrading it.
export function createPgClient({ connectionString, limits, onError }, { Client = pg.Client, Query = pg.Query } = {}) {
  const client = new Client({ connectionString, connectionTimeoutMillis: limits.connectTimeoutMs });
  let closed;
  const transportClosed = new Promise(resolve => { closed = resolve; });
  client.once("end", closed);
  let destroyed = false;
  const destroy = error => {
    if (destroyed) return;
    destroyed = true;
    // pg-cloudflare emits error, but not close, when the Workers socket's
    // closed Promise rejects. Observe actual transport closure before destroy
    // so pg.Client.end() cannot wait forever for its missing end event.
    const socketClosed = client.connection.stream._cfSocket?.closed;
    if (socketClosed) void Promise.resolve(socketClosed).then(closed, closed);
    client.connection.stream.destroy(error);
  };
  client.on("error", error => { onError(error); });
  return {
    connect: () => client.connect(),
    close: () => destroyed ? transportClosed : Promise.race([client.end(), transportClosed]),
    destroy,
    query({ text, values, limits: queryLimits }) {
      return new Promise((resolve, reject) => {
        const rows = [];
        let bytes = 0;
        let failed = false;
        const query = new Query({ text, values, rowMode: "array", queryMode: "extended",
          types: { getTypeParser: () => value => value } });
        query.on("row", (row, result) => {
          if (failed) return;
          try {
            const cells = row.map((value, index) => encodeCell(value, result.fields[index].dataTypeID));
            bytes += new TextEncoder().encode(JSON.stringify(cells)).length + 1;
            if (rows.length >= queryLimits.maxRows || bytes > queryLimits.maxResultBytes) throw protocolError("Query result limit exceeded", "RESULT_LIMIT");
            rows.push(row);
          } catch (error) { failed = true; reject(error); destroy(error); }
        });
        query.on("error", error => { failed = true; reject(error); });
        query.on("end", result => {
          if (!failed) resolve({ fields: result.fields, rows, rowCount: result.rowCount, command: result.command });
        });
        try { client.query(query); } catch (error) { reject(error); }
      });
    },
  };
}

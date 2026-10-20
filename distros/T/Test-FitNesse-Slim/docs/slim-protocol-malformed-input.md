# SLiM malformed-input handling

## Scope and authority

The normative source is the [FitNesse SLiM protocol guide](https://fitnesse.org/FitNesse/UserGuide/WritingAcceptanceTests/SliM/SlimProtocol.html). The pinned implementation is FitNesse v20251025 from `/opt/fitnesse/fitnesse.jar` (manifest version 20251025). Its source was inspected at the matching [20251025 source tree](https://github.com/unclebob/fitnesse/tree/20251025/src/fitnesse/slim) and [`util/StreamReader.java`](https://github.com/unclebob/fitnesse/blob/20251025/src/util/StreamReader.java).

The protocol requires a `Slim -- V<version>\n` greeting; outer frame lengths in bytes; string and nested-list lengths in UTF-16 code units; repeated request/response frames; and a framed `bye` directive. Its standard exception list defines `MALFORMED_INSTRUCTION` for malformed SLiM instructions. It does **not** specify a universal response or stream-resynchronization procedure for malformed frame prefixes, invalid serialized lists, incomplete frames, or resource-limit violations. Closing a malformed client without a reply is the Perl server's defensive policy, not an added protocol requirement.

## Pinned Java v20251025 observations

The main source paths are `SlimStreamReader`, `SlimServer`, `protocol/SlimDeserializer`, `ListExecutor`, `instructions/InstructionFactory`, and `instructions/InvalidInstruction`.

| Input | Java v20251025 source/runtime behavior | Perl policy |
|---|---|---|
| Valid unknown operation in a valid list | `InstructionFactory` creates `InvalidInstruction`; execution returns a framed `__EXCEPTION__` result in the `MALFORMED_INSTRUCTION` category with the instruction ID. A stack trace is included in the rendered exception text. A separate daemon listener remained available for later clients in the probe. | Return a bounded `MALFORMED_INSTRUCTION` result with the ID when it is a scalar; continue the session. |
| Invalid outer length text, negative length, absent colon, incomplete prefix, or value above Java `int` | `SlimStreamReader.getLengthToRead` reads the first six characters and then through `:`, calls `Integer.parseInt`, and throws `IOException` for nonnumeric/overflow values or EOF. Negative values are not explicitly rejected before `StreamReader.read`; the runtime probe observed the affected connection close without a response. | Reject the prefix and close only that client. Do not search for another prefix. |
| Expanded field wider than six digits | Accepted when its numeric value is valid. A raw-socket request with an eight-digit field received a valid Java response. | Accept six or more digits, including leading zeroes, within the Perl frame cap and 32-digit prefix cap. |
| Declared payload is truncated | `StreamReader.readBytes` returns the bytes received before EOF; `SlimServer` passes the resulting string to `SlimDeserializer`, which raises `SyntaxError` for the tested partial list. The worker logs an exception and closes the socket. | Report a truncated-payload error and close the client without a response. |
| Empty frame | Java receives an empty string, `SlimDeserializer` rejects it, and the worker closes the socket. | The frame parser accepts a zero-byte payload as a frame; list deserialization then rejects it and closes the client. |
| Corrupt top-level serialized list | `SlimDeserializer` throws `SyntaxError`; `SlimServer` does not turn that into a SLiM response. The Java worker logs a stack trace and closes the socket. | Reject the whole request before execution, log a short diagnostic, and close the client. |
| Malformed nested-list-looking item | `maybeReadList` attempts recursive parsing only for nonblank strings beginning with `[`. If recursive parsing throws `SyntaxError`, Java retains the item as a literal string. | Preserve this fallback. Resource-limit errors are not treated as ordinary syntax fallback. |
| Trailing text after the root `]` | Java's `checkForClosedBracket` consumes one closing bracket but does not verify that the input ended. This is source-inspected; no separate runtime probe was needed. | Reject trailing serialized data as a defensive structural check. |
| Invalid UTF-8 | `StreamReader.bytesToString` constructs a Java `String` using `FileUtil.CHARENCODING`, which is UTF-8; Java's decoder replaces malformed input. A structurally valid list containing `0xff` received a framed Java response. | Strictly decode UTF-8 and reject malformed or truncated sequences. This intentional difference avoids silently changing fixture values. |
| Clean EOF at a frame boundary | `getLengthToRead` still requests its initial six bytes and reports EOF as an `IOException`; it does not treat boundary EOF as a clean session end. The runtime probe observed EOF errors for incomplete prefixes. | Clean boundary EOF ends the session without an error. EOF during a prefix or payload is diagnosed and closes the client. |
| Extremely large but Java-int-valid frame | The source has no frame-size cap and passes the declared size to `StreamReader.read`; the large allocation case was not sent to Java to avoid memory pressure. | Reject above the configured cap before reading or allocating the body. |

Java `SlimServer.executeInstructions` deserializes the entire top-level list before calling `ListExecutor.execute`, so a top-level structural parse error cannot partially execute an earlier instruction. Java instruction construction and execution happen in sequence after that parse. The Perl implementation preserves this deserialize-before-execute boundary and adds per-message structure and resource checks.

## Perl policy and limits

`Server::_read_exact` loops until it has the requested number of bytes, retries interrupted reads, distinguishes clean boundary EOF from a partial read, and never treats a short read as a complete message. An invalid frame is not resynchronized. `_process` fully decodes a request before calling `ListExecutor`; any structural parse or limit failure closes that client's worker connection. The listener process remains available for new clients. No response is fabricated for malformed framing or serialization.

A valid frame with a structurally valid instruction that is unknown or has invalid required fields returns the ordinary two-item response shape with `MALFORMED_INSTRUCTION`, preserving a usable instruction ID. Malformed-instruction detail is bounded to avoid reflecting an attacker-sized operand list. A subsequent valid frame on the same connection is still processed.

| Limit | Default | Configuration | Reason |
|---|---:|---|---|
| Outer frame payload | 67,108,864 bytes (64 MiB) | `TEST_SLIM_MAX_FRAME_BYTES`, range 1..1,073,741,824 | The repository already exercises 1,000,000-byte frames and 1,000,000-unit list values; 64 MiB provides substantial headroom while bounding reads and output frames. |
| Decimal outer-prefix digits | 32 digits | Fixed policy | Allows expanded lengths and generous leading zeroes while bounding prefix storage and parsing work. |
| Nested list depth | 128 | Internal parser limit | Bounds recursive parsing depth. |
| Total decoded list elements | 1,000,000 per message | Internal parser limit | Bounds allocation and per-element work across nested lists. |
| Declared item length | 16,777,216 UTF-16 units | Internal parser limit | Bounds a single item; also remains below the default frame-byte cap for ordinary encoded strings. |

These values are implementation policies, not limits published by FitNesse. The frame setting is the only limit exposed as an environment override. All decimal values are compared as strings against limits before conversion to Perl numeric values. The parser uses a cursor rather than repeatedly copying the unconsumed suffix. It enforces the root closing delimiter and rejects trailing data.

The outer prefix counts transmitted bytes. The list parser strictly decodes UTF-8, then counts decoded strings in UTF-16 code units: a supplementary character counts as two, combining marks remain separate code points, and delimiters inside string payloads do not affect framing. The parser preserves FitNesse's ambiguous convention that a bracket-prefixed but invalid nested-list string is a literal string. Invalid UTF-8 never enters that fallback because it is rejected at the outer decode boundary.

## Regression evidence

`t/server-malformed-input.t` launches the actual Perl TCP listener with a deliberately small frame cap and uses raw sockets with bounded read timeouts. It covers:

- Handshake, fragmented bytes, an expanded header, Unicode fixture round trips, and multiple frames on one connection.
- A malformed instruction followed by a valid request on the same connection.
- Invalid frame prefix followed by an attempted valid frame, a declared-shorter-than-body frame, a truncated payload after client half-close, an oversized declaration, and invalid UTF-8.
- A fresh valid client after each rejected connection.
- A batch whose first instruction would create a marker file and whose later serialized element is truncated. The file remains absent, proving no earlier instruction executed.

`t/server-frame.t` additionally covers zero-byte framing, six-digit minimum width, expanded fields and leading zeroes, nonnumeric and negative lengths, missing colon, incomplete prefix, excessive prefix length, over-limit declaration, and truncated payload. `t/list-malformed-input.t` covers list delimiters, counts, item lengths, separators, trailing data, nested fallback, nesting/element/item/frame limits, invalid and truncated UTF-8, UTF-16 boundary splits, empty/null/zero, punctuation, and Unicode round trips.

The Java comparison was run against `fitnesse.slim.SlimService -d` from the pinned JAR. Probes were time-bounded; malformed connections were closed and the daemon accepted later probes. Tests did not send Java a multi-gigabyte declaration. The source-level Java observations and runtime probes are distinguished above; Java behavior is reference evidence, not the normative protocol for malformed transport.

## Remaining limitations

The Perl listener still uses one forked worker per accepted socket and has no per-client idle-read deadline. A peer that connects and keeps a partial prefix open without closing can retain its worker; adding global connection quotas, general concurrency stress tests, or shutdown redesign is outside this hardening increment. The configured 1 GiB upper override is intentionally large and should only be raised for known workloads. Perl's character model does not represent isolated UTF-16 surrogate code units as ordinary Unicode scalars; existing Character converter policy remains documented separately. Java itself has no observed frame cap and replaces malformed UTF-8, so the Perl service intentionally differs in both areas.

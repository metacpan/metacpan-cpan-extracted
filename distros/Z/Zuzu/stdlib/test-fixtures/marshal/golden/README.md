# Zuzu Marshal Golden Fixtures

These files are base64-encoded Zuzu Marshal CBOR v1 envelopes emitted by
the Perl implementation. They are strong-reference-only fixtures and do
not contain weak storage records.

The fixture names cover:

- `scalar-null.b64`: scalar root;
- `array-cycle.b64`: self-referential array;
- `dict-pairlist.b64`: Dict and PairList payloads;
- `time-path.b64`: runtime-backed Time and Path values;
- `function.b64`: user function code record;
- `class.b64`: user class code record with scalar capture;
- `trait.b64`: user trait code record with scalar capture;
- `object-instance.b64`: user object instance with its class code.

Reserved weak-storage fixtures are tracked separately in
`../weak-records.json` so runtimes can distinguish format recognition
from implemented weak-storage semantics.

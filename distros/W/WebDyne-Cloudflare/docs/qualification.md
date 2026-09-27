# Qualification record

This is a summary of dated evidence, not a claim that old test resources remain
available. The detailed pre-cleanup reports and sanitized result snapshots are
preserved in Git history at `d97a804608a7081afcbc4ef6a9a13b6025ebb73b`.
Current reproducible commands are in [TEST.md](../TEST.md).

| Date | Surface | Evidence and limits |
| --- | --- | --- |
| 2026-09-11 | D1/KV/R2 | Local Perl/WASM reads, writes, bytes, JSON routes, concurrent requests, D1 batch rollback and scoped cleanup passed. Earlier remote D1/KV basic operations passed; remote batch/R2 were not qualified. |
| 2026-09-12 | PostgreSQL Hyperdrive | CRUD, bound/exact types, statements, explicit/callback transactions, SQLSTATE, limits, backend termination, rollback and recovery passed against the dedicated cache-disabled fixture. SSE observed an active origin query before client disconnect. The exact rebuilt ZeroPerl 1.0.11 artifact passed the six-case suite plus four concurrent recovery requests. Temporary Worker and test rows were removed. |
| 2026-09-13 | MySQL Hyperdrive | Aiven MySQL 8.4.8 through Hyperdrive/Perl WASM, plus direct MySQL 8.4.11 and MariaDB 11.8.9 adapter tests passed. PlanetScale/Vitess was not qualified. Temporary Workers and test tables were removed. |
| 2026-09-13 | Secrets Store | Four concurrent local requests passed with a dummy secret, candidate extension 1.5.0 and updated runtime generator. No production secret or remote resource was used. |
| 2026-09-13 | D1 sessions | Extension 1.6.0 with ZeroPerl 1.0.12 passed build/dry run and ten local requests, including bookmark continuation and concurrency. Remote replica routing/lag was not exercised. |
| 2026-09-13 | Durable Objects | Local workerd/Perl checks covered RPC, concurrent updates, independent objects, rollback, stale handles, cycles, errors, serialization and restart persistence. Initial qualification used portable runtime source with verified 1.0.9 WASM; newer exact-artifact results belong with the release being tested. |

## Interpretation

A client timeout or disconnect does not prove immediate origin query cancellation.
The PostgreSQL verifier waited longer than the deliberate query sleep and checked
write outcomes independently. Unknown COMMIT outcomes and Perl Future cancellation
were tested deterministically, not induced as live database failures. Individual
pg field allocation is not bounded before decoding, so row/byte checks do not
establish an absolute memory ceiling.

Local D1 cannot establish remote replica routing or lag. Local Secrets Store tests
do not establish production permissions. Durable Object WASM memory measurements
exclude JavaScript, VFS and other interpreters and are not capacity guarantees.
The declared Perl 5.20 minimum has not been separately qualified.

## Cleanup candidate

The pre-cleanup baseline passed 399 Perl assertions, 77 JavaScript tests and the
73-file npm inventory check. The cleanup verification used the exact ZeroPerl 1.0.14 artifact from
[GitHub run 34735360890](https://github.com/aspeer/zeroperl/actions/runs/34735360890),
source `8628c7e5244f4fd8a612cb12864aa7bddd752277`. Tarball SHA-1 and packaged WASM
SHA-256 matched the artifact metadata. Local Sigstore verification could not
initialize its verifier; this is not a claim of local provenance verification.

- 399 Perl assertions and 78 JavaScript tests passed, including the retained
  integration-authentication test. Distribution and 76-file npm inventory checks
  passed. The production dependency audit reported no vulnerabilities.
- All nine PSP pages passed `wdlint`. All six independent example applications
  passed generated builds, Wrangler dry runs and actual WebDyne HTTP rendering;
  all five native PAGI supplements passed JSON/text and concurrent request checks.
- Inventory examples used disposable local PostgreSQL/MySQL servers and verified
  escaping of script-like database text. These checks bypass Hyperdrive pooling.
- The full local D1/KV/R2 fixture passed, including 24 concurrent reads, eight
  atomic D1 batch checks and scoped storage cleanup. Direct MySQL 8.4.11 adapter
  tests also passed types, insert IDs, binding, SQL modes, commit/rollback and errors.
- The independent Durable Objects fixture passed concurrency, rollback, capability
  expiry, cycles, serialization and restart persistence with the exact runtime.
- The moved MySQL harness passed all local cases and concurrent recovery. The
  PostgreSQL harness passed five non-disconnect cases, four concurrent recovery
  requests and all scoped cleanup checks. Its unchanged `/abort` assertion failed
  under local Wrangler: completion was rejected but `request.signal.aborted` was
  false. The smoke script is byte-identical to the pre-cleanup version; its remote
  disconnect assertion remains intact. Remote cancellation has not been requalified
  with this candidate, and the local run must not be described as a full pass.

## Local example setup

The 1.7.1 example setup passed with the same ZeroPerl 1.0.14 artifact:

- All six WebDyne applications and five native PAGI supplements ran through their
  documented npm development commands and passed HTML/JSON/text checks.
- `setup:local` created the Secrets Store dummy value without remote access and
  succeeded when repeated; neither client rendered the secret.
- Both Compose databases passed readiness, automatic schema initialization,
  inventory queries and HTML escaping. `db:down`/`db:up` preserved an added row;
  `db:reset` removed it and restored only seed data. Test volumes were removed.
- Database images pin official PostgreSQL/MySQL digests and copy the schema at
  build time, avoiding Docker Desktop/Colima host file-sharing requirements.
- Standard checks remain 399 Perl assertions, 78 JavaScript tests and a 76-file
  npm package. Relative documentation links and source manifest checks passed.

The maintainer accepted the documented local PostgreSQL cancellation limitation
for this cleanup release; its remote assertion remains unchanged.

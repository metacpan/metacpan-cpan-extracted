# WebDyne::Cloudflare

Use Cloudflare services from WebDyne PSP pages or native PAGI applications under
[ZeroPerl](https://github.com/aspeer/zeroperl/blob/main/WEBDYNE.md).
The npm package `@webdyne/webdyne-cloudflare` includes both the Perl modules and
JavaScript adapters. No separate CPAN installation is required in the Worker.

## GitHub Attestations

The release workflows generate [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
for release archives. Install the [GitHub CLI](https://cli.github.com/) with
`gh attestation` support and authenticate with `gh auth login`.

Download the npm package with `npm pack`, replace `VERSION`, and verify the
resulting archive with:

```sh
npm pack @webdyne/webdyne-cloudflare@VERSION
gh attestation verify webdyne-webdyne-cloudflare-VERSION.tgz --repo aspeer/pm-WebDyne-Cloudflare
```

For a CPAN distribution archive, use:

```sh
gh attestation verify WebDyne-Cloudflare-VERSION.tar.gz --repo aspeer/pm-WebDyne-Cloudflare
```

A successful verification confirms that the archive's checksum matches an
attestation from this repository. Attestations cover archives produced by the
attestation-enabled release workflows. Older releases and GitHub's
automatically generated source-code archives are not covered.

| Service | Perl API | WebDyne example |
| --- | --- | --- |
| D1 queries and atomic batches | [D1](lib/WebDyne/Cloudflare/D1.pm.md) | [Storage](examples/storage/README.md) |
| D1 sessions and bookmarks | [Sessions](lib/WebDyne/Cloudflare/D1/Session.pm.md) | [Bookmark continuation](examples/d1-sessions/README.md) |
| Workers KV | [KV](lib/WebDyne/Cloudflare/KV.pm.md) | [Storage](examples/storage/README.md) |
| R2 buffered objects | [R2](lib/WebDyne/Cloudflare/R2.pm.md) | [Storage](examples/storage/README.md) |
| PostgreSQL through Hyperdrive | [Hyperdrive](lib/WebDyne/Cloudflare/Hyperdrive.pm.md) | [Inventory](examples/hyperdrive/README.md) |
| MySQL through Hyperdrive | [MySQL](lib/WebDyne/Cloudflare/Hyperdrive.pm.md#mysql-and-compatible-databases) | [Inventory](examples/hyperdrive-mysql/README.md) |
| Secrets Store retrieval | [Secrets Store](lib/WebDyne/Cloudflare/SecretsStore.pm.md) | [Safe retrieval](examples/secrets-store/README.md) |
| Durable Object RPC and Perl SQLite handlers | [Durable Objects](lib/WebDyne/Cloudflare/DurableObject.pm.md) | [Counter](examples/durable-objects/README.md) |

## Quick start

Start with the [examples guide](examples/README.md). Each service directory is a
standalone application with WebDyne as its default entry and, where useful, a
native PAGI alternative.

For a new application:

```sh
npm init -y
npm install @webdyne/webdyne-zeroperl@^1.0.14 @webdyne/webdyne-cloudflare@^1.7.1
npx webdyne-cloudflare init
```

Install the released packages from npm. See the examples guide for complete
local development instructions.
Create `app/app.psp`, enable the extension and configure the required bindings
in package.json using the [configuration guide](docs/configuration.md), then
run `npm run check` and `npm run dev`. Initialization creates scaffolding;
it does not create your application page or provision Cloudflare resources.

## Request lifetime and Futures

Construct facades inside the request. In WebDyne, the scope is
`$self->r()->{'scope'}`; native PAGI receives `$scope_hr` directly.
Cloudflare bindings and database credentials remain in JavaScript. Perl receives
an opaque capability that expires when the request or invocation finishes.
Do not retain facades, statements, or unfinished operations in package globals.

Service I/O returns Futures. The WebDyne examples retrieve results with `->get()`
through ZeroPerl's host bridge. Native async handlers use `Future::AsyncAwait`
and `await`. Complete all work within the request; dropping a Future does not
schedule background work. Hyperdrive uses familiar DBI-style method names and
argument positions, but is asynchronous and is not DBI-compatible.

```perl
use WebDyne::Cloudflare::D1;

sub customer {
    my ($self, $match_hr)=@_;
    my $db_or=WebDyne::Cloudflare::D1->new(
        scope => $self->r()->{'scope'}, binding => 'DB',
    );
    return $db_or->prepare('SELECT name FROM customers WHERE id=?1')
        ->bind($match_hr->{'id'})->first()->get();
}
```

Use bound SQL parameters and the service's explicit byte/blob wrapper for binary
data. Escape values inserted into HTML. See the individual API references for
result types, errors, limits, and transaction behavior. A timeout or failed commit
does not prove a database write was cancelled; ambiguous writes are never retried
automatically. Runtime teardown awaits resource cleanup.

## Text, binary data and errors


Perl character strings cross as text. Unflagged non-ASCII strings are decoded
strictly as UTF-8, including SQL, keys, column names and nested metadata/JSON
keys and values. Invalid UTF-8 fails before the host call. Normalization copies
containers without changing caller data; cycles and keys which become identical
after UTF-8 decoding are rejected.

Use the service's `blob($bytes)` wrapper for binary values. Returned binary
data becomes ordinary Perl byte strings. D1 preserves numbers, zero, empty
strings, JSON booleans and SQL NULL (`undef`). KV/R2 `put` treats a plain numeric
body as text; use KV `put_json` to retain JSON numeric/boolean types.

Missing capabilities or invalid constructor arguments throw immediately.
Service operations fail their Future on errors. Host errors use
`WebDyne::Cloudflare::D1::Error`, `KV::Error` or `R2::Error`, with `name()`,
`message()`, `code()` and `cause()` accessors and stringification. Local input
validation errors can be plain exceptions. Catch failures around `await` or
`->get()`; don't assume every exception is a service Error object.

KV values and R2 bodies are buffered, with a default bridge limit of 16 MiB.
KV provider reads are buffered before the limit check; it is not a streaming
memory guarantee. R2 rejects oversized reads and cancels unread bodies.
Increasing the limits increases interpreter/Worker memory pressure and does
not lift Cloudflare's own service limits.

R2 streaming, multipart uploads, conditional requests, signed URL
generation and automatic retries are not implemented for the storage APIs. Use the documented methods rather than assuming the complete
JavaScript binding API is available in Perl.

## Development and documentation

Perl 5.20+ with Future and Future::AsyncAwait is declared; current native tests
use Perl 5.44. Use Node.js 24+ for the full suite, including SQLite tests.

```sh
npm ci --ignore-scripts
perl Makefile.PL
make test
make distcheck
npm run pack:check
```

- [API overview](lib/WebDyne/Cloudflare.pm.md): maintained sidecars beside Perl source.
- [Configuration](docs/configuration.md): binding allowlists and generated Wrangler resources.
- [Examples](examples/README.md): runnable applications, separate from regression fixtures.
- [Testing](TEST.md): contract, package and Worker integration commands.
- [Qualification record](docs/qualification.md): dated evidence and explicit limits.
- [Release and staging](docs/releasing.md): GitHub qualification, attestations and npm MFA handoff.
- `t/`: Perl tests, fixtures and maintained integration harnesses.
- `t.js/`: JavaScript tests, smoke runners and package checks.

Generated consumers, npm archives and local Wrangler state are ignored build
outputs. Keep them out of source distributions. Historical implementation reports
and superseded prototypes are available in Git history before the 1.7.1 cleanup.

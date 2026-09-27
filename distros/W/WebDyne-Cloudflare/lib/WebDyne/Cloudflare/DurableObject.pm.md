# WebDyne::Cloudflare::DurableObject

Request-scoped Durable Object namespace and RPC client for WebDyne under ZeroPerl.
Requires the finite-invocation tooling in ZeroPerl 1.0.13 or later for Perl-hosted
objects, and targets Wrangler 4.131.1. Client-only access uses the normal extension
lifecycle. No inheritance framework is required for application handlers.

## Synopsis

```perl
use Future::AsyncAwait;
use WebDyne::Cloudflare::DurableObject;

my $namespace_or=WebDyne::Cloudflare::DurableObject->new(
    scope => $scope_hr, binding => 'COUNTERS',
);
my $counter_or=await $namespace_or->get_by_name('account:123');
my $result_hr=await $counter_or->call('increment', 1);
```

`new(scope => ..., binding => ...)` validates the invocation's binding allowlist.
`get_by_name($name)` and `get_by_id($id)` return Futures resolving to a stub.
`call($method, @args)` returns a Future resolving to one value. `id()` returns a
stub's canonical ID; `binding()` returns the configured binding name. Names are
non-empty strings. Persist names or IDs, not namespace/stub objects: capabilities
expire at invocation completion. These operations do not retry failed calls.

## Values and errors

RPC supports strings, finite numbers (integer values within JavaScript's safe
integer range), JSON booleans, `undef`, arrays, hashes, and explicit byte values:

```perl
my $bytes_or=WebDyne::Cloudflare::DurableObject::bytes("\0\xff");
my $echo_or=await $counter_or->call('echo', $bytes_or);
my $raw=$echo_or->value();
```

Incoming bytes are `DurableObject::Bytes` objects, not implicit text. Tagged wire
containers prevent ordinary hashes from being misinterpreted as bytes. Cycles,
other blessed objects, streams, RPC targets and coderefs are unsupported. Nesting
is limited to 64 and complete messages to 1 MiB. Keep large integers as text;
SQL applications can select `CAST(value AS TEXT)` when exact integer values exceed
the safe range. SQL blobs use the same explicit bytes wrapper.

Host and remote failures fail the Future, normally with a
`WebDyne::Cloudflare::DurableObject::Error` exposing `name`, `message`, and `code`.
Validation errors may be plain exceptions. A failure after a write does not imply
rollback. Use idempotency keys for operations the application may retry.

## Configuration

```json
{
  "webdyne": {
    "entry": "app.psp",
    "perlLibrary": ["lib"],
    "extensions": {"@webdyne/webdyne-cloudflare": {}},
    "cloudflare": {
      "durableObjects": [
        {
          "binding": "COUNTERS",
          "className": "Counter",
          "perlPackage": "Example::Counter",
          "methods": ["increment", "read"],
          "initialize": true
        }
      ]
    }
  }
}
```

The updated ZeroPerl CLI adds namespace capabilities, exports the named JavaScript
class, and generates Wrangler `durable_objects.bindings` and SQLite `exports`.
`initialize` is optional and defaults to false. Methods must be explicitly listed;
constructors, lifecycle handlers, `then`, `AUTOLOAD`, `DESTROY`, and internal dispatch
names cannot be RPC methods. JavaScript class names start with an uppercase letter. Class and package names are validated before code
is generated. The application package must be in `perlLibrary`.

For another Worker's Perl-hosted class, specify `binding`, `className`, and
`scriptName`, omitting local package, methods, and initialization. For an existing
ordinary JavaScript object, also specify `native: true`. Native calls invoke the
named method directly; framework calls use the versioned `webdyneInvoke` protocol.
Native bindings cannot carry our ancestry metadata, so call-cycle detection is
only guaranteed along framework-to-framework call paths. Native services must
not synchronously call back into a waiting framework object.

Custom Workers can set `durableObjectBindings` and `durableObjectNativeBindings`
on `createWebDyneCloudflareExtension`. For hosting, import
`createWebDyneDurableObject` from `@webdyne/webdyne-cloudflare/durable-object`, and
supply `createRuntime`, `runtimeOptions`, `definition`, and a `createExtensions`
factory. Each object receives fresh extension instances. The generated Worker
illustrates this composition. Direct JavaScript clients can call the explicitly
exposed methods normally; calls made by Perl should use this module so ancestry
is preserved.

Existing custom Wrangler configurations remain user-owned. Add the equivalent
bindings and SQLite declarations there. Do not combine `exports` and legacy
`migrations`, or switch an existing deployment without reviewing its namespace
history. Application schema initialization and Cloudflare class lifecycle
configuration are separate concerns.

## Object behavior

A JavaScript class owns one isolated interpreter per active Durable Object. Each
RPC invocation has a fresh context and capability lifetime. Complete invocations,
including initialization and awaited cleanup, run one at a time; at most 64 calls
may be queued/running. Call chains are bounded to 32 and reject cycles, including
same-object re-entry through binding aliases. A long or never-settling handler
blocks later calls; there is no automatic handler retry or forced timeout.

Object handler signatures and SQLite operations are documented in
[Context.pm.md](DurableObject/Context.pm.md). Alarms, hibernating WebSockets, callback
transactions, HTTP forwarding and rich RPC objects are deferred. The finite event
transport is separate from HTTP/PAGI response transport so future event adapters
can share scheduling and cleanup without keeping a request open.

Perl memory, globals, `/tmp`, and virtual filesystem writes are temporary. Store
important state in SQLite before returning. Initialization runs again after an
object or interpreter is reconstructed. There is no shutdown-save guarantee.
Runtime/cleanup failures retire the hosting runtime reference; the next call
initializes a fresh interpreter. Ordinary reported application errors preserve the
interpreter, so application caches must remain consistent with any partial work.

One interpreter starts with a 32 MiB WASM memory allocation in the qualified build;
this is not a total-memory estimate. JavaScript, filesystems, additional active
objects and application allocations add overhead. Avoid one global object for
unrelated entities and qualify workloads within Cloudflare's isolate limits.

## References

- [RPC invocation](https://developers.cloudflare.com/durable-objects/best-practices/create-durable-object-stubs-and-send-requests/)
- [SQLite storage](https://developers.cloudflare.com/durable-objects/api/sqlite-storage-api/)
- [Object lifecycle](https://developers.cloudflare.com/durable-objects/concepts/durable-object-lifecycle/)
- [Class exports](https://developers.cloudflare.com/durable-objects/reference/durable-objects-migrations/)

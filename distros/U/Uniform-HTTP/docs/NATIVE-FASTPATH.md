# Native FastPath

Uniform::HTTP 0.06 provides an optional C header for XS-based HTTP engines.
It builds and inspects the same canonical Message, Request, and Response objects
used by the Perl API. Normal application code does not need this interface.

Uniform::HTTP remains pure Perl. No compiler is required to install it.
The engine compiles the header as part of its own distribution.

## Consumer setup

The header is installed as data at
`Uniform/HTTP/FastPath/uniform_http_fastpath.h` beside the Perl modules.
Uniform::HTTP is pure Perl. It compiles nothing and needs no compiler to install.
Only the XS consumer compiles the header, using the Perl against which that
consumer is built. There is no shared native Uniform library to link.

Find the installed include directory in the consumer's `Makefile.PL`:

```perl
use Uniform::HTTP::FastPath 0.06 ();

my $include = Uniform::HTTP::FastPath::native_include_dir();
# Pass qq(-I"$include") in the consumer's MakeMaker INC setting.
```

Declare Uniform::HTTP 0.06 or newer as both a configure dependency (to locate
the header) and runtime dependency in that distribution. For optional native support, test
`Uniform::HTTP::FastPath->can('native_include_dir')` before selecting this build
path. Released 0.05 has only the Perl FastPath and supplies no native header.

Include the header after Perl's headers:

```c
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "uniform_http_fastpath.h"
```

Initialize a handle in the consumer's per-interpreter state:

```c
uhttp_native_api api;
if (!uhttp_native_init(aTHX_ &api, UHTTP_NATIVE_ABI_VERSION)) {
    /* Disable the native path; use the portable API or Perl FastPath. */
}
```

`uhttp_native_init` loads FastPath and checks the installed runtime's native ABI
and private storage revision. It returns 0 on a mismatch, including a runtime
that predates this interface. A missing module or a Perl exception propagates.
A failed or uninitialized handle cannot construct or inspect an object.

The handle owns no resources and needs no destructor. Keep it local to one Perl
interpreter. Reinitialize in each cloned thread; do not put it in a shared C
static. Do not reuse a handle across interpreter destruction or module reloads.
Do not change the canonical packages or replace their implementations while
using a handle. The author fixture demonstrates `MY_CXT` and `CLONE` handling.

The native ABI is currently **1**. The existing Perl FastPath ABI is still **1**;
these are separate contracts. The header supplies its own storage revision to
`native_compatible(abi, layout)`. Consumers must not hardcode or override the
layout revision or use that Perl check in place of `uhttp_native_init`.

Any incompatible descriptor, ownership, semantic, or storage change requires
rejecting the old native contract. A future runtime may accept an older header
only while that header can safely use the same storage and semantics. Exact
matching is intentional; an unrelated distribution version is not an ABI check.

## Construction

Initialize an input descriptor with `uhttp_native_input_init(&input, kind)`.
Kinds are `UHTTP_KIND_MESSAGE`, `UHTTP_KIND_REQUEST`, and `UHTTP_KIND_RESPONSE`.
The initializer selects complete, fully mutable, lossless defaults, with exact
target fidelity for requests. It does not mark the input trusted.

```c
uhttp_native_input input;
SV *request;
uhttp_native_field fields[1];

uhttp_native_input_init(&input, UHTTP_KIND_REQUEST);
input.version.data = "1.1"; input.version.len = 3;
input.method.data = "GET"; input.method.len = 3;
input.target.data = "/"; input.target.len = 1;
fields[0].name.data = "Host"; fields[0].name.len = 4;
fields[0].value.data = "example.com"; fields[0].value.len = 11;
input.headers = fields;
input.header_count = 1;

/* The parser must already have checked all Uniform field rules. */
request = uhttp_native_from_validated(aTHX_ &api, &input, UHTTP_NATIVE_TRUSTED);
/* Return request through an XS SV* typemap, or release/mortalize it yourself. */
```

The public input fields are:

| Fields | Meaning |
| --- | --- |
| `kind`, `flags` | Message class and lifecycle/fidelity state |
| `version` | Optional version bytes, without `HTTP/` |
| `method`, `target` | Required for requests |
| `scheme`, `authority`, `protocol` | Optional request metadata; never inferred |
| `status` | Response integer from 100 through 599; zero for other kinds |
| `reason` | Optional response reason; absent for other kinds |
| `headers`, `header_count` | Ordered native name/value pairs |
| `trailers`, `trailer_count` | Separate ordered native name/value pairs |
| `body` | Optional buffered bytes, including empty or binary bodies |

Byte spans contain a `const char *data` and a `STRLEN len`. They do not require
NUL termination. `NULL, 0` means absent; a non-NULL pointer with zero length
means an empty string. Required values and each pair's name and value must be
present. Empty header names, methods, and targets are rejected.

Set `UHTTP_HAS_BUFFERED_BODY` exactly when `body.data` is non-NULL. Body length
may be zero. Arrays may be NULL only when their count is zero. Each array has
at most `I32_MAX` pairs, for compatibility with older Perl array APIs; byte
lengths must not exceed `IV_MAX - 1`. All pointers must address the declared
amount of readable storage. The C API cannot validate a pointer's allocation.

Flags correspond to the existing Perl FastPath flags, without the `FLAG_`
prefix: `UHTTP_HAS_BUFFERED_BODY`, `UHTTP_COMPLETE`, `UHTTP_MUTABLE`,
`UHTTP_INITIAL_MUTABLE`, `UHTTP_BODY_MUTABLE`, `UHTTP_TRAILERS_MUTABLE`,
`UHTTP_HEADERS_LOSSLESS`, `UHTTP_TRAILERS_LOSSLESS`, and `UHTTP_TARGET_EXACT`.
Unknown flags and inconsistent combinations throw. Body mutability equals
whole-message mutability. A fully immutable object has no mutable sections.
Completion is independent of all freeze flags. Both lossless flags are required;
exact target fidelity is required only for requests and forbidden otherwise.

Construction checks descriptor shape and state but **does not validate HTTP
syntax**. The explicit trust marker prevents accidental default opt-in; it is
not proof that validation happened and is not a security boundary. The parser
must enforce every ordinary Uniform rule before supplying spans:

- token syntax for method, protocol, and field names;
- nonempty target with no spaces or prohibited control bytes;
- digit/optional-decimal version syntax;
- URI scheme syntax and Uniform's minimal authority restrictions;
- permitted field-value and reason bytes;
- byte strings rather than an implicit character encoding.

Use ordinary constructors for application input and untrusted values. Do not
expose the trusted helper as a general Perl constructor. This distinction
preserves the 0.05 FastPath's validation boundary. Protocol-specific requirements,
such as legal pseudo-field combinations or framing, remain the engine's job.

## Ownership

Construction borrows the descriptor, spans, and native field arrays only for
the duration of the call. It copies bytes into the final canonical Perl scalars
and creates owned header/trailer arrays. It retains no parser memory, takes no
ownership of caller allocations, and accepts no SV or AV ownership transfers.
The caller can immediately reuse or free its input buffers after return.

The returned object is an owned, non-mortal `SV *` with reference count 1. Return
it through the usual XS typemap, mortalize it, or decrement it when finished.
Validation exceptions occur before allocation. The temporary construction root
is protected by a Perl save scope so a later exception unwinds owned storage.

Objects have the exact canonical class and use normal Perl methods afterward.
There is no native attachment, destructor, second object model, or alternate
freeze/completion implementation. The pre-existing Perl FastPath still adopts
its supplied Perl arrays; the native span interface deliberately copies bytes.

## Inspection

```c
uhttp_native_view view;
SV *name, *value;
Size_t i;

if (uhttp_native_inspect(aTHX_ &api, request, &view)) {
    /* Scalar fields such as view.method are borrowed SVs. */
    for (i = 0; i < uhttp_native_field_count(aTHX_ &view.headers); ++i) {
        uhttp_native_field_at(aTHX_ &view.headers, i, &name, &value);
        /* Consume the name/value bytes here. Do not modify either SV. */
    }
}
else {
    /* Adapter, subclass, or unsupported storage: use portable methods. */
}
```

The view has `kind`, `flags`, the same named metadata fields, `body`, and
`headers`/`trailers` section handles. All metadata fields, including `status`,
are borrowed `SV *` values. Absent values are Perl undef. Request-only fields
are undef for other kinds, and response-only fields are undef for other kinds.
Section handles are opaque; use only `uhttp_native_field_count` and
`uhttp_native_field_at`. Out-of-range access returns 0 and undef values.

Inspection makes no Perl method calls and allocates no Perl view. It accepts
only exact canonical classes. Magical/tied or malformed top-level storage returns
0 without invoking callbacks. Nested pairs are checked when read; malformed or
magical pair storage throws. Inspection trusts the semantic validity of canonical
objects; it does not certify wire safety or redo field validation.

The caller must retain the source object. Views, sections, scalar pointers, and
any extracted byte pointers expire when the object is changed or released. They
must not cross callbacks, Perl method calls that might mutate the object,
asynchronous boundaries, or interpreter boundaries. A stale view is not detected
automatically. Get a new view after mutation. Copy scalars with `newSVsv` and
copy field pairs when longer ownership is needed; incrementing the object
reference alone does not prevent later mutation. Never mutate a borrowed SV,
array, or byte buffer. Use the ordinary setters and lifecycle methods.

Members or helpers marked private, including names beginning `_` or
`uhttp_private_`, are not a consumer API. Do not use hash keys, array internals,
stash pointers, cached flags, or private storage revision values directly.

## Author checks and benchmarks

From a repository checkout with normal dependencies installed:

```text
perl Makefile.PL
make test
perl author/check-pure-perl.pl
perl author/native/build.pl
prove author/native.t
perl bench/native-fastpath.pl
```

`author/check-pure-perl.pl` stages the distribution from MANIFEST, rejects shipped
XS/build sources, and configures, tests, and installs using compiler/linker
commands that fail if invoked. It checks ordinary installed object behavior and
the installed header location. The XS fixture and benchmarks stay repository-only
and are never run by installation. CI explicitly builds the fixture on Perl
5.16, 5.38, and the current Perl.

The benchmark uses identical native byte spans for all three construction
paths. It includes fresh intermediate fields for ordinary/Perl FastPath calls,
final object allocation, and destruction. Inspection uses the same C checksum
through ordinary Perl method calls, a Perl FastPath view, or the native view.
It checks equal results and reports medians while rotating measurement order.
Inputs include requests and responses with zero, four, and 32 headers, a trailer,
metadata, and a small binary body. These measurements isolate object costs.
Real engine performance and protocol workloads must be measured separately.

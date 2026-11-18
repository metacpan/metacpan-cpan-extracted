---
name: getty-perl-typing
description: "Use when typing Perl attributes or parameters — isa, Type::Tiny, Types::Standard, Moose constraints, or whether a project needs types at all."
---

# Perl Typing — Getty House Rules

Two decisions, in this order: **does this project need types at all**, then
**which tool**. The common failure is pulling `Type::Tiny` into a 200-line Moo
distribution that had no shape problem. This skill is the authority on whether
to type; `getty-perl-moo` / `getty-perl-moose` cover the attribute mechanics.

## Choosing the tool

| Situation | Use |
|---|---|
| Small Moo distribution, simple shapes | **No type system.** `required => 1` and a clear attribute name carry it. |
| Moo, and the data genuinely is complex | **`Types::Standard`** (Type::Tiny). Moo has no types of its own. |
| Moose | **`Types::Standard`** in new code — same vocabulary as Moo, better messages. |
| A dist already typed with strings (`isa => 'ArrayRef[Int]'`) | **Keep the strings** — one type vocabulary per dist; no `Types::Standard` beside them. |
| The same domain type across many classes | **A `<Dist>::Types` library** on `Type::Library` (below). |

Start a type library when the same type is imported in several places and its
definition needs one home — never just because the distribution has types.

## Where typing pays

Type what arrives from outside; be sparing inside.

- **Yes:** data crossing a boundary (API responses, config, user input); result objects wrapping a foreign response; a closed set of values (`Enum` beats a `Str` with the values in a comment).
- **Usually:** parameters of a real entry point — a public API call, a CLI command; not internal methods.
- **Rarely:** internal attributes from your own lazy builder — `_cache` holding a hashref does not need `HashRef`.
- **No:** types for consistency. If you cannot say which wrong value the type would have caught, leave it off.

## Rules

- **Parametrise instead of loosening:** `ArrayRef[Str]` over `ArrayRef`.
- **`Maybe[X]` for anything the source may send as null** — not `Str` with a default that invents data. `required => 1` (must be supplied) is a separate statement; both may apply.
- **A declared type states its failure:** give `message { ... }` when "did not pass type constraint" would not tell the reader what to fix.
- **No `coerce` for anything lossy.** Coercion is the same value in another notation — a string to a `Path::Tiny`, an epoch to a `DateTime`. Anything that guesses, truncates or fills in a default belongs in explicit code.
- **Never type an attribute you then also check by hand** — one place decides validity.
- **Import the exact types you use:** `use Types::Standard qw( Str Maybe );` — spaces inside the parens. `-types` only inside a type library.

## A type library, once it has earned it

```perl
package WWW::Example::Types;
# ABSTRACT: Domain types for WWW::Example

use Type::Library -base, -declare => qw( AccountName );
use Type::Utils -all;
use Types::Standard -types;

declare AccountName,
  as Str,
  where { /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/ },
  message { "$_ is not a valid account name" };

1;
```

Consumers import by name: `use WWW::Example::Types qw( AccountName );`

## Validating parameters

Getty code validates with `Params::ValidationCompiler` (`validation_for( params => { name => { type => Str } } )`);
`Type::Params` does the same job — one of the two per distribution. With
`signature_for` on a method, **`method => 1` is mandatory**: without it `$self`
is read as the first argument and every call fails with a parameter-count error
that says nothing about the cause.

## Edge cases

- **A type would need the object's other attributes** → that is a `BUILD` check, not a type. Types see one value.
- **A third-party class instance** → `InstanceOf['DateTime']`; with Moose's built-ins, `isa => 'DateTime'`.
- **Performance in a hot path** → install `Type::Tiny::XS`; do not remove the type.
- **`MooseX::Types`** → superseded; use `Types::Standard`.

## Related

- `getty-perl-core` — house rules the example follows.
- `getty-perl-moo` / `getty-perl-moose` — attribute mechanics per object system.

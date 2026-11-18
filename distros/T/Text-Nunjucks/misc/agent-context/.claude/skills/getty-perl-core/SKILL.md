---
name: getty-perl-core
description: "Use when editing any Perl in a Getty project — module loading, subs, errors, style, cpanfile pins, per-file $VERSION."
---

# Perl Core — Getty House Rules

These override defaults in every Getty project. Object-system specifics:
`getty-perl-moo` / `getty-perl-moose`; whether and where to type: `getty-perl-typing`.

## Module loading

- **`use Module;` at the top** — every dependency loads at compile time. A `require Foo;` in a method body (to "speed up startup", or `require` + `->new` in a controller action) → hoist it to a top-level `use`.
- **`require` only for true runtime plugin loading** — the class name comes from config/DB (`Module::Runtime::use_module($class_from_db)`). Known at write-time → `use`.
- `strict` + `warnings` in every file: written out in scripts, tests and plain modules; Moo/Moose/Catalyst classes get them on import — not repeated there.

## Object system

- **One object system per distribution** — Moo or Moose everywhere; mixing only at a boundary a framework forces (e.g. RapidApp).
- **`is => 'ro'` by default**; `rw` needs a reason.
- **Non-trivial values come from a builder `sub _build_foo`**, never `default => sub {...}`: Moo `is => 'lazy'`, Moose `lazy_build => 1`.
- **Class hygiene:** Moo class `use namespace::clean;` (not in roles); Moose class `use namespace::autoclean;` (or `no Moose;`) and `__PACKAGE__->meta->make_immutable;` as its last line.
- **`weak_ref => 1`** on attributes holding a reference back to a parent/owner.
- **`->instance`** on `MooseX::Singleton` / `MooX::Singleton` classes, never `->new`.

## Subroutines

- **`my ( $self, $x ) = @_;` as the first line** — spaces inside the parens; never `my $self = shift;`. One-liners skip unpacking: `sub trace { shift->_logger->trace(@_) }`. A builder ignoring `$self` is one line: `sub _build_readonly { 0 }`.
- **`_` prefix marks private** subs and attributes; a private attribute's builder doubles up: `sub _build__mp`.
- **In a class every helper is a method on `$self`**, never a bare `_foo($self->config, $x)` — bare subs can't be overridden or mocked. Bare subs only in non-class utility modules imported as functions.
- **No package-level state** but true constants (an `%ENGINE_CLASS` table counts); a per-process cache is an attribute on the singleton (`has _cache => ( is => 'ro', default => sub { {} } )`), not `my %CACHE`.

### Dispatch through the invocant, never a hardcoded class name

A literal `Some::Package->helper(...)` nails the call to that package — no subclass or mock can reach it. Call the class's own methods through `$self`, and name each collaborator class once in an overridable resolver:

```perl
package My::Pipe;

sub backend_class { 'My::Backend::Age' }        # override point, named once

sub decrypt {
  my ( $self, %arg ) = @_;
  my $key = $self->backend_class->unwrap( $arg{header} );  # not My::Backend::Age->unwrap
  return $self->_finish( $key );                           # not My::Pipe->_finish
}

package My::Pipe::Vault;
use parent -norequire, 'My::Pipe';
sub backend_class { 'My::Backend::Vault' }       # a subclass swaps it; the pipeline follows
```

Class-method-only modules too: `my ( $self, ... ) = @_;` and dispatch through `$self` — the class name *is* the invocant, and `Thing->do(...)` callers keep working.

## Errors, strings, control flow

- **`croak`, never `die`** — `use Carp qw( croak );`, called bare; the message names the origin: `croak __PACKAGE__."->state too many args"`.
- **Concatenate, do not interpolate:** `'Adding '.$f.' with '.$length.' bytes'`. Interpolate only where concatenation would be unreadable.
- **Single quotes by default**; `"` only when you need interpolation or escapes.
- **Import lists as `qw( croak confess )`** — spaces inside; never rely on default exports.
- **Postfix `if`/`unless`** for guards and short conditions; **`unless $x`**, not `if !$x`.
- **Guard clauses return bare:** `return unless $res->is_success;` — not `return undef;`.
- **Nested ternaries** for a return that picks between expressions, instead of an if/elsif chain.

## Data

- **`Path::Tiny`** for every file operation — not `File::Spec`, not bare `open`.
- **`JSON::MaybeXS`** always — never `JSON::PP`, `JSON::XS`, `Cpanel::JSON::XS` directly. Encoders get `canonical => 1, convert_blessed => 1`. Booleans `JSON->true` / `JSON->false`, never `JSON::PP::true` barewords.
- **Every serializer is deterministic** — MessagePack `->canonical`, DBIC `serializer_options => { canonical => 1 }`, every format.
- `$YAML::XS::Boolean = 'JSON::PP'` is a YAML::XS mode name, not a module choice — leave it.
- **Align `=>`** in multi-line hashes when keys are of similar length; optional pairs inline: `$cond ? ( experimental => 1 ) : (),`

## Configuration and DBIC

- **Config comes from env vars prefixed with the project name** (`$ENV{MYPROJECT_TIME_ZONE}`), each with a default in code. Many attributes of that shape → a generator sub that wraps `has`, not N copied declarations.
- **DBIx::Class / DBIO result classes** (columns, NonMoose classes): read [references/dbic.md](references/dbic.md) before editing one.

## Style

- **2-space indentation** — not 4, not tabs.
- **Trailing comma after the last element** of every multi-line list, hash or call.
- **Section long files with a figlet banner** comment (`standard`, `slant`, `small`, `banner`); short file or no figlet → a `#### <Name>` rule.
- **Debug with `DDP`** (`Data::Printer`), never `Data::Dumper` in shipped code. Live debug calls go before commit; **commented-out ones stay** (`#use DDP; p($res);`) — they mark where debugging was needed.

## cpanfile

- **Requirements live in `cpanfile`**, not `dist.ini` prereq blocks.
- **`requires 'Module::Name';`** — omit the version when unpinned, never `'0'`. A version means "or higher": `requires 'Foo', '5.0';`, never `'>= 5.0'`.
- **Alphabetical**, phase blocks (`on test => sub {...}`) at the end.

### Getty-authored dependencies — CRITICAL

`[@Author::GETTY]` keeps a repo's `$VERSION` at the **next, unreleased** version (`0.402` while CPAN has `0.401`) — a sibling checkout is always one ahead of CPAN.

1. **Pin what the code needs, not the number in front of you.** Pinning a sibling's `$VERSION` while using nothing that version introduced names an unreleased version and breaks the build off this machine.
2. **Get the released version from `cpanm --info`**; if it carries what you use, that is the pin:
   ```bash
   cpanm --info Module::Name | tail -1
   # → GETTY/Module-Name-1.234.tar.gz  ← pin to 1.234
   ```
3. **Pin the next, unreleased version only when the change spans both repos** — the sibling gained what this code calls, or both are tested together from working trees for a release. Then the dependency is released first; nothing goes out ahead of it.
4. **Pin every Getty-authored distribution**, current — not stale, not omitted. Re-check on upgrade.

Getty-authored (non-exhaustive): `Langertha`, `IO::K8s`, `Kubernetes::REST`, `WWW::Crawl4AI`, `Net::Async::Crawl4AI`, `Net::Async::WebSearch`, `Catalyst::Plugin::ChainedURI`, `Locale::Simple`, `DBIO::*`, `WWW::Zitadel`, `WWW::PayPal`, `WWW::Chain`.

## `$VERSION` and files

- **Every module under `lib/` and every Perl executable under `bin/` carries its own `our $VERSION = '...';`** — the next, unreleased version.
- **One package per file** — the release rewrites only the first `our $VERSION` in a file.
- **Executables live in `bin/`, never `script/`** — `script/` is neither installed nor versioned.

Mechanics: skill `getty-perl-release-author-getty`.

## When in doubt

Grep hand-written Getty code for the pattern — an older repo with no AI commits in its history. Newer repos may show an agent's guess, not the house rule.

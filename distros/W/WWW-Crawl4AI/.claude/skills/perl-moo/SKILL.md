---
name: Perl Moo
description: Moo Perl object system - roles, attributes, inheritance patterns, and best practices
trigger: when working with Moo, Moo::Role, Perl OO, or perl-moo
category: language
---

# Perl/Moo – Architecture & Implementation Patterns

## Core Principle
Use **inheritance sparingly** (stable "is-a" contracts), **roles heavily** (horizontal reuse). When in doubt: role, not subclass.

---

## Pattern 1 – `extends` + Attribute Override

```perl
package App::Base;
use Moo;
has prefix => (is => 'ro', default => sub { 'Hello' });
sub greet { $_[0]->prefix . ", " . $_[0]->name }

package App::Friendly;
use Moo;
extends 'App::Base';
has '+prefix' => (default => sub { 'Hi' });   # override via +attr
```

**Rules:** Multiple `extends` calls REPLACE (don't add). Reference defaults always as coderefs (`sub { [] }`, never `[]`).

---

## Pattern 2 – Role with `requires`

```perl
package App::Role::UppercaseName;
use Moo::Role;
requires 'name';                          # contract: consumer must have name()
sub uppercase_name { uc $_[0]->name }

package App::User;
use Moo;
extends 'App::Base';
with 'App::Role::UppercaseName';          # composed; missing 'name' → loud failure
```

**Rules:** `requires` fails at composition time, not runtime. Imports inside a role land as methods on the consumer unless cleaned up – everything loaded *before* `use Moo::Role` is auto-cleaned; everything after is composed.

---

## Pattern 3 – Thin Classes (roles only, no base)

```perl
package App::Role::HasId;  use Moo::Role; has id => (is => 'ro', required => 1);
package App::Role::CanDescribe;
use Moo::Role; requires 'id';
sub describe { "id=" . $_[0]->id }

package App::Thing;
use Moo;
with 'App::Role::HasId', 'App::Role::CanDescribe';
```

Use when there's no meaningful "is-a" relationship. Prefer over deep hierarchies.

---

## Pattern 4 – House-Style Import Module

```perl
package My::Mooish;
use Import::Into;
sub import {
    my $target = caller;
    strict->import::into($target);
    warnings->import::into($target);
    Moo->import::into($target);
    namespace::clean->import::into($target);   # after Moo, cleans stray imports
}

package App::Thing;
use My::Mooish;
has x => (is => 'ro', default => sub { 1 });
```

**Rules:** Order matters: imports → `use Moo` → `namespace::clean`. Use `namespace::autoclean` ≥ 0.16 only (older versions inflate Moo classes to Moose). Use `strictures` v2 with Moo 2.

---

## Pattern 5 – Delegation via `handles`

```perl
package App::UsesCounter;
use Moo;
has counter => (
    is      => 'ro',
    required => 1,
    handles => 'App::Role::CounterAPI',   # role defines the interface (inc/reset/value)
);
```

Three forms: `handles => 'RoleName'` (interface from role), `handles => [qw(inc reset)]` (list), `handles => { add => 'push' }` (rename). Does not trigger `isa`/`coerce`/`trigger` on the delegate itself.

---

## Pattern 6 – Native-Trait Delegation via `Sub::HandlesVia`

```perl
package Kitchen;
use Moo;
use Sub::HandlesVia;
use Types::Standard qw(ArrayRef Str);
has food => (
    is          => 'ro',
    isa         => ArrayRef[Str],
    handles_via => 'Array',
    default     => sub { [] },
    handles     => { add => 'push', find => 'grep' },
);
```

**Use `Sub::HandlesVia` over `MooX::HandlesVia`** – the latter documents that triggers/coercions don't fire on delegated mutations. Load `Sub::HandlesVia` *after* `use Moo`.

---

## Pattern 7 – Method Modifiers

```perl
before calc => sub { die "x<0" if $_[1] < 0 };         # validate, can't change return

around calc => sub {
    my ($orig, $self, $x) = @_;
    return $self->$orig($x) + 1;                        # can change return value
};

after calc => sub { ... };                               # side-effects, logging
```

**Rules:** `before`/`after` cannot alter return value; `around` can. Always forward `@_` correctly in `around`. Multiple modifiers from multiple roles stack – order is composition-order-sensitive.

---

## Pattern 8 – Attribute Options Cheatsheet

```perl
has name   => (is => 'ro',   required => 1);
has tags   => (is => 'ro',   default  => sub { [] });    # ALWAYS coderef for refs
has id     => (is => 'lazy');                             # built on first access
sub _build_id { "id:" . $_[0]->name }

has status => (
    is      => 'rw',
    trigger => 1,                                        # calls _trigger_status on set
);
sub _trigger_status { die "bad" unless $_[1] =~ /\A(new|ok)\z/ }

has _secret => (is => 'ro', init_arg => 'secret');       # constructor param alias
```

`trigger` fires on `new()` and `set`, NOT on `default`/`builder`. Old value is NOT passed (unlike Moose). `is => 'lazy'` = lazy reader, runs builder on first access.

---

## Pattern 9 – Lifecycle Hooks

```perl
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    return { source => $args[0] } if @args == 1 && !ref $args[0];  # normalize
    $class->$orig(@args);
};

sub FOREIGNBUILDARGS {          # maps args to non-Moo parent's constructor
    my ($class, $args) = @_;
    return ($args->{source});
}

sub BUILD {                     # runs AFTER all attributes are set; parent→child order
    my ($self, $args) = @_;
    die "invalid" unless length $args->{source};
}
# DEMOLISH: child→parent order. Never override DESTROY directly.
```

Do NOT call `SUPER::BUILD` manually – Moo handles the chain.

---

## Pattern 10 – Strict Constructor

```perl
package StrictThing;
use Moo;
use MooX::StrictConstructor;
has size => (is => 'rw');

StrictThing->new(size => 5, colour => 'blue');  # dies: unknown attribute 'colour'
```

**Caveat:** Interacts with `namespace::clean` (can sweep `new`). If needed, protect via `-except => ['new']` or adjust import order per the module docs.

---

## Pattern 11 – Role Conflict Resolution

```perl
# Single with → conflict → dies:
# with 'RoleA', 'RoleB';   # both define foo() → fatal

# Sequential with → first wins:
with 'RoleA';   # foo() from RoleA is now in the class
with 'RoleB';   # foo() already exists → RoleA wins silently
```

"Class wins": if the class defines `foo()` itself, neither role's version is used. For complex conflict strategies: refactor roles to avoid the overlap.

---

## Pattern 12 – Parameterized Roles

```perl
package Counter;
use Moo::Role;
use MooX::Role::Parameterized;
parameter name => (is => 'ro', required => 1);
role {
    my ($p, $mop) = @_;
    my $n = $p->name;
    $mop->has($n => (is => 'rw', default => sub { 0 }));
    $mop->method("inc_$n" => sub { $_[0]->$n($_[0]->$n + 1) });
};

package Thing;
use Moo;
use MooX::Role::Parameterized::With;
with Counter => { name => 'hits' };

Thing->new->inc_hits;   # generates: hits attribute + inc_hits method
```

Module is marked **experimental**. `role { }` block runs at composition time; `$mop` proxies `has/around/before/after/requires`.

---

## Pattern 13 – Moose Interop

When Moose is loaded before Moo classes are compiled, Moo auto-inflates its metaclasses. This means:

- Moose class can `extends` a Moo class
- Moo class can `with` a Moose role

```perl
BEGIN { require Moose }
package MyMooseClass;
use Moose;
extends 'MyMooClass';   # works if Moose was loaded first
```

For Moose-style syntax in Moo (`isa => 'Str'`, `lazy_build`), use `MooX::late`. Avoid `Any::Moose` – deprecated, points to Moo.

---

## Type Constraints

Moo has no built-in type system. `isa` takes a coderef:

```perl
use Types::Standard qw(Str Int ArrayRef);
has name => (is => 'ro', isa => Str);
has tags => (is => 'ro', isa => ArrayRef[Str], default => sub { [] });
```

`Type::Tiny` / `Types::Standard` is the official recommendation in Moo docs (replaces `MooseX::Types`).

---

## Decision Guide

| Situation | Use |
|---|---|
| Shared attributes/methods, stable "is-a" | `extends` |
| Optional/horizontal feature | `Moo::Role` + `with` |
| Same pattern, different config | `MooX::Role::Parameterized` |
| Delegate method set to sub-object | `handles` |
| Array/Hash operations on attribute | `Sub::HandlesVia` |
| Logging/validation/caching wrapper | `before`/`around`/`after` |
| Catch constructor typos | `MooX::StrictConstructor` |
| Cross-project boilerplate | `Import::Into` house-style module |
| Named types | `Type::Tiny` / `Types::Standard` |
| Multiple roles define same method | Sequential `with` or refactor |
| Legacy non-Moo parent | `FOREIGNBUILDARGS` |
| Multiple inheritance | Last resort; use `mro 'c3'` |

---

## Common Pitfalls

- `default => []` → **shared state bug**. Always `default => sub { [] }`.
- `extends 'A'; extends 'B'` → replaces, does NOT add B to A. Use `extends 'A', 'B'`.
- Imports after `use Moo::Role` are **composed into consumers** as methods.
- `namespace::autoclean` < 0.16 inflates Moo classes to Moose unexpectedly.
- `trigger` does NOT receive old value (unlike Moose).
- `Sub::HandlesVia` must be loaded *after* `use Moo`.
- `BUILD` chain is automatic; calling `SUPER::BUILD` manually breaks it.
- Never override `DESTROY`; use `DEMOLISH`.
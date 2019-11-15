# NAME

Types::Const - Types that coerce references to read-only

# VERSION

version v0.3.8

# SYNOPSIS

```perl
use Moo;
use Types::Const -types;
use Types::Standard -types;

...

has bar => (
  is      => 'ro',
  isa     => Const[ArrayRef[Str]],
  coerce  => 1,
);
```

# DESCRIPTION

This is an _experimental_ type library that provides types that force
read-only hash and array reference attributes to be deeply read-only.

See the [known issues](#known-issues) below for a discussion of
side-effects.

# TYPES

## `` Const[`a] ``

Any defined reference value that is read-only.

If parameterized, then the referred value must also pass the type
constraint, for example `Const[HashRef[Int]]` must a a hash reference
with integer values.

It supports coercions to read-only.

This was added in v0.3.0.

# ROADMAP

Support for Perl versions earlier than 5.10 will be removed sometime
in 2019.

# SEE ALSO

[Const::Fast](https://metacpan.org/pod/Const::Fast)

[Type::Tiny](https://metacpan.org/pod/Type::Tiny)

[Types::Standard](https://metacpan.org/pod/Types::Standard)

[Types::ReadOnly](https://metacpan.org/pod/Types::ReadOnly)

# KNOWN ISSUES

## Side-effects of read-only data structures

A side-effect of read-only data structures is that an exception will
be thrown if you attempt to fetch the value of a non-existent key:

```
Attempt to access disallowed key 'foo' in a restricted hash
```

The work around for this is to check that a key exists beforehand.

## Performance issues

Validating that a complex data-structure is read-only can affect
performance.  If this is an issue, one workaround is to use
[Devel::StrictMode](https://metacpan.org/pod/Devel::StrictMode) and only validate data structures during tests:

```perl
has bar => (
  is      => 'ro',
  isa     => STRICT ? Const[ArrayRef[Str]] : ArrayRef,
  coerce  => 1,
);
```

Another means of improving performance is to only check the type
once. (Since it is read-only, there is no need to re-check it.)

## RegexpRefs

There may be an issue with regexp references. See
[RT#127635](https://rt.cpan.org/Ticket/Display.html?id=127635).

## Bug reports and feature requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Types-Const/issues](https://github.com/robrwo/Types-Const/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# SOURCE

The development version is on github at [https://github.com/robrwo/Types-Const](https://github.com/robrwo/Types-Const)
and may be cloned from [git://github.com/robrwo/Types-Const.git](git://github.com/robrwo/Types-Const.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# Uniform

Uniform is the specification and utility anchor for the Uniform Perl ecosystem.

The Uniform namespace is intended to make reusable web and protocol components less
dependent on a particular framework, event loop, transport, or deployment model.

Some Uniform distributions provide portable protocol or domain objects. Others
provide explicit adapters for specific frameworks. The goal is to keep application
logic portable while making framework-specific behavior clear and intentional.

## Install

Install the distribution from CPAN:

    cpanm Uniform

or with the CPAN client:

    cpan Uniform

## What this distribution provides

This distribution contains:

- `Uniform` - the ecosystem specification
- `Uniform::Utils` - shared utility functions
- `Uniform::Exceptions` - structured exceptions used by Uniform components

Most application-facing features live in companion distributions under the
`Uniform::` namespace.

## Design rules

Uniform components follow a few basic rules:

- Portable components should describe their own domain instead of copying one
  framework's object model.
- Framework adapters should be selected explicitly rather than auto-detected.
- Configuration-style mutators should support fluent method chaining.
- External side effects should happen at documented boundaries.
- Programmer errors should fail early and clearly.

See the POD for `Uniform` for the complete component specification.

## Example

Shared utilities can be used independently:

    use Uniform::Utils qw(parse_size_limit);

    my $bytes = parse_size_limit('2M');

## Companion distributions

Examples in the Uniform ecosystem include:

- `Uniform::HTTP`
- `Uniform::HTTP::Auth`
- `Uniform::HTMX`
- `Uniform::Upload`

Each companion distribution documents its own supported interfaces and adapters.

## Repository

Development repository:

    https://github.com/haxmeister/perl-Uniform

Issues:

    https://github.com/haxmeister/perl-Uniform/issues

## Author

Joshua S. Day <HAX@cpan.org>

## License

This software is Copyright (c) 2026 by Joshua S. Day.

This is free software, licensed under the MIT License.

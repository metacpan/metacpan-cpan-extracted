package Uniform;

use strict;
use warnings;

our $VERSION = '1.04';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Uniform - The Unified, Framework-Agnostic Web Infrastructure Specification for Perl

=head1 SYNOPSIS

    # This is the specification and utility anchor distribution.
    # Companion distributions provide active implementations:

    # cpanm Uniform::HTMX
    # cpanm Uniform::HTTP::Auth


=head1 DESCRIPTION

The C<Uniform> ecosystem provides standardized, framework-agnostic interfaces,
domain components, and adapters for modern Perl web development.

Web frameworks (such as Dancer2, Mojolicious, Catalyst, and raw Plack/PSGI) handle
common tasks such as processing HTTP headers, manipulating file uploads, and tracking
session authentication using widely divergent object models and execution semantics.

Some Uniform components implement portable protocol or domain semantics and require
no framework integration. Other components isolate operational differences in
explicitly selected framework adapters. By programming against a C<Uniform::*>
interface, application logic can remain decoupled from the underlying deployment
engine, transport, or framework.

=head1 THE UNIFORM COMPONENT SPECIFICATION

Components under the C<Uniform::*> namespace fall into two categories.

=over 4

=item * Protocol and domain components

These provide portable data models, value objects, parsers, or protocol mechanics.
They must not depend unnecessarily on a web framework, transport, event loop, or
application lifecycle. Examples include authentication calculations and HTTP message
semantics.

=item * Framework adapters

These translate between a Uniform interface and a specific framework or gateway.
Framework-specific objects and lifecycle behavior belong in these adapters rather
than in the portable component.

=back

All components must follow the applicable contracts below.

=over 4

=item 1. Framework-Neutral Semantics

Portable components must describe their own domain rather than copy the object model
or lifecycle of one framework. They should accept and return plain Perl data or
documented Uniform interfaces whenever practical.

=item 2. Explicit Framework Adapters

When framework integration is required, components must not use runtime
auto-detection or implicit framework guessing. The adapter must be explicitly loaded
and instantiated by the application developer:

    use Uniform::HTMX::PSGI;
    my $hx = Uniform::HTMX::PSGI->new($env);

Portable components do not need framework subclasses when their work is inherently
framework-independent.

=item 3. Fluent Mutators

Public mutator methods whose primary purpose is setting configuration or object state
must return C<$self> to preserve clean method-chaining capabilities. An operation may
return its domain result even when it also updates private bookkeeping as part of that
operation.

=item 4. Explicit Side-Effect Boundaries

Changing a detached value object or adapter-owned in-memory state is not itself an
outbound side effect and does not require an C<apply()> method.

When a component stages changes that will be written to a framework, gateway,
transport, or other external system, it must not emit those changes unexpectedly
mid-operation. The component must expose a documented explicit boundary for that
effect. Existing framework adapters normally use C<apply()> for this purpose; a pure
calculation, value object, or data conversion requires no such method.

=item 5. Fail-Fast Programmer Errors

Methods must strictly validate caller-supplied arguments. Invalid references,
unsupported options, and malformed parameter structures must throw an immediate
exception using L<Uniform::Exceptions> or C<Carp::croak>.

This rule applies to programmer misuse of the API. It does not require a protocol
component to throw merely because untrusted remote input is malformed. A component
may instead represent malformed peer input as data when its documented contract calls
for inspection, recovery, or fallback.

=back

=head1 CENTRAL UTILITIES

This root distribution exposes shared internal utility libraries designed to accelerate
the development of external driver plugins. See L<Uniform::Utils> for details.

=head1 SEE ALSO

L<Uniform::HTMX>

L<Uniform::Upload>

L<Uniform::HTTP::Auth>

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Joshua S. Day.
This is free software, licensed under the MIT License.

=cut

#!/usr/bin/false
# ABSTRACT: The type of a Bugzilla flag, as returned in flag activity records
# PODNAME: WebService::Bugzilla::FlagActivity::Type

package WebService::Bugzilla::FlagActivity::Type 0.001;
use strictures 2;
use Moo;
use namespace::clean;

has description      => (is => 'ro');
has id               => (is => 'ro');
has is_active        => (is => 'ro');
has is_multiplicable => (is => 'ro');
has is_requesteeble  => (is => 'ro');
has name             => (is => 'ro');
has type             => (is => 'ro');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::FlagActivity::Type - The type of a Bugzilla flag, as returned in flag activity records

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $activity = $bz->flag_activity->get;
    for my $flag (@{$activity}) {
        my $type = $flag->type;
        say 'Flag type: ', $type->name;
        say '  Description: ', $type->description;
        say '  Requestable: ', $type->is_requesteeble ? 'yes' : 'no';
        say '  Multiplicable: ', $type->is_multiplicable ? 'yes' : 'no';
    }

=head1 DESCRIPTION

This class represents metadata about a Bugzilla flag type.  Flag types
define what kinds of flags can be used (e.g. C<review>, C<feedback>,
C<approval>).

Flag type objects are typically accessed via the C<type> attribute of a
L<WebService::Bugzilla::FlagActivity> object.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<description>

Human-readable description of what this flag type is used for.

=item C<id>

Unique numeric flag type ID.

=item C<is_active>

Boolean.  Whether this flag type is currently active.

=item C<is_multiplicable>

Boolean.  Whether multiple flags of this type can be set on the same bug
or attachment.

=item C<is_requesteeble>

Boolean.  Whether this flag type allows specifying a requested person.

=item C<name>

Internal name of the flag type (e.g. C<review>, C<feedback>).

=item C<type>

Kind of object this flag applies to (C<bug> or C<attachment>).

=back

=for Pod::Coverage is_requesteeble

=head1 SEE ALSO

L<WebService::Bugzilla::FlagActivity> - flag activity objects

L<WebService::Bugzilla> - main client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut

package WebService::PivotalTracker::Entity;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.11';

use DateTime::Format::RFC3339;
use URI;

use WebService::PivotalTracker::Types qw( ClientObject HashRef PTAPIObject );

use Moo::Role;

requires '_self_uri';

has _pt_api => (
    is       => 'ro',
    isa      => PTAPIObject,
    init_arg => 'pt_api',
    required => 1,
    handles  => ['_client'],
);

has raw_content => (
    is       => 'rw',
    writer   => '_set_raw_content',
    isa      => HashRef,
    required => 1,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

# The PT docs specify ISO8601 but the examples all seem to be RFC3339
# compliant.
sub _inflate_iso8601_datetime {
    return DateTime::Format::RFC3339->parse_datetime( $_[1] );
}

sub _inflate_uri {
    return URI->new( $_[1] );
}

sub _refresh_raw_content {
    my $self = shift;

    $self->_set_raw_content( $self->_client->get( $self->_self_uri ) );

    return;
}

## use critic

1;

# ABSTRACT: A shared role for all PT resources

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::Entity - A shared role for all PT resources

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This role has no user-facing parts.

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

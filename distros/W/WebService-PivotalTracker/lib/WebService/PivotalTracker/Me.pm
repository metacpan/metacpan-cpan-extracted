package WebService::PivotalTracker::Me;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.11';

use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Types
    qw( ArrayRef Bool DateTimeObject NonEmptyStr PositiveInt );

use Moo;

has( @{$_} ) for props_to_attributes(
    id                            => PositiveInt,
    name                          => NonEmptyStr,
    initials                      => NonEmptyStr,
    username                      => NonEmptyStr,
    time_zone                     => NonEmptyStr,
    api_token                     => NonEmptyStr,
    has_google_identity           => Bool,
    email                         => NonEmptyStr,
    receives_in_app_notifications => Bool,
    created_at                    => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    updated_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    kind => NonEmptyStr,
);

with 'WebService::PivotalTracker::Entity';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _self_uri {
    die 'Me has no uri';
}
## use critic

1;

# ABSTRACT: The /me resource, an expanded Person

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::Me - The /me resource, an expanded Person

=head1 VERSION

version 0.11

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents the person to whom the token belongs.

=for Test::Synopsis my $pt;

  my $me = $pt->me;

=head1 ATTRIBUTES

This class provides the following attribute accessor methods. Each one
corresponds to a property defined by the L<PT REST API V5 me resource
docs|https://www.pivotaltracker.com/help/api/rest/v5#me_resource>.

=head2 id

=head2 name

=head2 initials

=head2 username

=head2 time_zone

=head2 api_token

=head2 has_google_identity

=head2 email

=head2 receives_in_app_notifications

=head2 created_at

This will be returned as a L<DateTime> object.

=head2 updated_at

This will be returned as a L<DateTime> object.

=head2 kind

=head2 raw_content

The raw JSON used to create this object.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

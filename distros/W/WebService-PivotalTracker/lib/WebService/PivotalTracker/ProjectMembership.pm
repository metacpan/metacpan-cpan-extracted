package WebService::PivotalTracker::ProjectMembership;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.12';

use WebService::PivotalTracker::Person ();
use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Types qw(
    Bool
    DateTimeObject
    NonEmptyStr
    PersonObject
    PositiveInt
);

use Moo;

has( @{$_} ) for props_to_attributes(
    kind           => NonEmptyStr,
    project_id     => PositiveInt,
    id             => PositiveInt,
    last_viewed_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    created_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    updated_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    role                                         => NonEmptyStr,
    project_color                                => NonEmptyStr,
    favorite                                     => Bool,
    wants_comment_notification_emails            => Bool,
    will_receive_mention_notifications_or_emails => Bool,
);

has person => (
    is      => 'ro',
    isa     => PersonObject,
    lazy    => 1,
    default => sub {
        my $self = shift;
        WebService::PivotalTracker::Person->new(
            pt_api      => $self->_pt_api,
            raw_content => $self->raw_content->{person},
        );
    },
);

with 'WebService::PivotalTracker::Entity';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _self_uri {
    my $self = shift;

    return $self->_client->build_uri(
        sprintf(
            '/projects/%s/membership/%s',
            $self->project_id,
            $self->id,
        )
    );
}
## use critic

1;

# ABSTRACT: A single project membership

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::ProjectMembership - A single project membership

=head1 VERSION

version 0.12

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a single project membership.

=for Test::Synopsis my $pt;

  my $memberships = $pt->project_memberships(...)->[0];
  say $_->person->name for $memberships->@*;

=head1 ATTRIBUTES

This class provides the following attribute accessor methods. Each one
corresponds to a property defined by the L<PT REST API V5 project membership
resource
docs|https://www.pivotaltracker.com/help/api/rest/v5#project_membership_resource>.

=head2 kind

=head2 project_id

=head2 id

=head2 last_viewed_at

=head2 created_at

=head2 updated_at

=head2 role

=head2 project_color

=head2 favorite

=head2 wants_comment_notification_emails

=head2 will_receive_mention_notifications_or_emails

=head2 raw_content

The raw JSON used to create this object.

=head1 METHODS

This class provides the following methods:

=head2 $membership->person

This method returns the L<WebService::PivotalTracker::Person> object contained
in the project membership.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2020 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

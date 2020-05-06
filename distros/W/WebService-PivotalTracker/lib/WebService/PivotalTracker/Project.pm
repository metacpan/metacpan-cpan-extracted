package WebService::PivotalTracker::Project;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.12';

use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Story;
use WebService::PivotalTracker::Types
    qw( Bool DateTimeObject DayOfWeek HashRef NonEmptyStr PositiveInt PositiveNum ProjectType Str );

use Moo;

has( @{$_} ) for props_to_attributes(
    id                              => PositiveInt,
    name                            => NonEmptyStr,
    version                         => PositiveInt,
    iteration_length                => PositiveInt,
    week_start_day                  => DayOfWeek,
    point_scale                     => NonEmptyStr,
    point_scale_is_custom           => Bool,
    bugs_and_chores_are_estimatable => Bool,
    automatic_planning              => Bool,
    enable_tasks                    => Bool,
    start_date                      => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    time_zone                  => HashRef,
    velocity_averaged_over     => PositiveInt,
    show_iterations_start_time => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    start_time => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    number_of_done_iterations_to_show => PositiveInt,
    has_google_domain                 => Bool,
    description                       => Str,
    profile_content                   => Str,
    enable_incoming_emails            => Bool,
    initial_velocity                  => PositiveInt,
    project_type                      => ProjectType,
    public                            => Bool,
    atom_enabled                      => Bool,
    current_iteration_number          => PositiveInt,
    account_id                        => PositiveInt,
    created_at                        => {
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

sub memberships {
    my $self = shift;

    return $self->_pt_api->project_memberships(
        @_,
        project_id => $self->id,
    );
}

sub stories {
    my $self = shift;

    return
        map { WebService::PivotalTracker::Story->new( %{$_} ) }
        @{ $self->raw_content->{stories} };
}

sub iterations {
    my $self = shift;

    return $self->_pt_api->project_iterations(
        @_,
        project_id => $self->id,
    );
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _self_uri {
    my $self = shift;

    return $self->_client->build_uri(
        sprintf(
            '/projects/%s/iterations/%s',
            $self->id,
            $self->number,
        )
    );
}
## use critic

1;

# ABSTRACT: A single iteration in a project

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::Project - A single iteration in a project

=head1 VERSION

version 0.12

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a single project iteration.

=for Test::Synopsis my $pt;

  my $iterations = $pt->project( project_id => 42 );

=head1 ATTRIBUTES

This class provides the following attribute accessor methods. Each one
corresponds to a property defined by the L<PT REST API V5 project resource
docs|https://www.pivotaltracker.com/help/api/rest/v5#project_resource>.

=head2 id

=head2 name

=head2 version

=head2 iteration_length

=head2 week_start_day

=head2 point_scale

=head2 point_scale_is_custom

=head2 automatic_planning

=head2 enable_tasks

=head2 start_date

This will be returned as a L<DateTime> object.

=head2 time_zone

=head2 velocity_averaged_over

=head2 show_iterations_start_time

This will be returned as a L<DateTime> object.

=head2 start_time

This will be returned as a L<DateTime> object.

=head2 number_of_done_iterations_to_show

=head2 has_google_domain

=head2 description

=head2 profile_content

=head2 enable_incoming_emails

=head2 initial_velocity

=head2 project_type

=head2 public

=head2 atom_enabled

=head2 current_iteration_number

=head2 account_id

=head2 created_id

This will be returned as a L<DateTime> object.

=head2 updated_at

This will be returned as a L<DateTime> object.

=head2 kind

=head2 raw_content

The raw JSON used to create this object.

=head1 METHODS

This class provides the following methods:

=head2 $project->memberships(...)

This method returns an array reference of
L<WebService::PivotalTracker::ProjectMembership> objects, one for each member
of the project.

=head2 $project->stories(...)

This method returns an array of L<WebService::PivotalTracker::Story> objects,
one for each story in the project.

=head2 $project->iterations(...)

This method returns an array reference of
L<WebService::PivotalTracker::ProjectIteration> objects based on the provided
arguments.

This method accepts the following arguments:

=over 4

=item * label

A label on which to filter the stories contained in each iteration object.

=item * limit

The number of items to be returned. If not specified the default number of
iterations will be returned.

=item * offset

The offset at which to start returning results.

=item * scope

The scope of the iterations to return. This can be one of the following
strings:

=over 8

=item done

=item current

=item backlog

=item current_backlog

=item done_current

=back

By default all iterations are returned, including done iterations.

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2020 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

package WebService::PivotalTracker::Project;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

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
    show_iterations_start_Time => {
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

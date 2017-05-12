package WebService::PivotalTracker::ProjectIteration;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Story;
use WebService::PivotalTracker::Types
    qw( DateTimeObject NonEmptyStr PositiveInt PositiveNum );

use Moo;

has( @{$_} ) for props_to_attributes(
    number        => PositiveInt,
    length        => PositiveInt,
    team_strength => PositiveNum,
    start         => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    finish => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    kind => NonEmptyStr,
);

with 'WebService::PivotalTracker::Entity';

sub stories {
    my $self = shift;

    return [
        map {
            WebService::PivotalTracker::Story->new(
                raw_content => $_,
                pt_api      => $self->_pt_api,
                )
        } @{ $self->raw_content->{stories} }
    ];
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _self_uri {
    my $self = shift;

    return $self->_client->build_uri(
        sprintf(
            '/projects/%s/iterations/%s',
            $self->project_id,
            $self->number,
        )
    );
}
## use critic

1;

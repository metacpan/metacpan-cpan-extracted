package WebService::PivotalTracker::Label;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Types
    qw( DateTimeObject NonEmptyStr PositiveInt PositiveOrZeroInt );

use Moo;

has( @{$_} ) for props_to_attributes(
    id         => PositiveInt,
    project_id => PositiveInt,
    name       => NonEmptyStr,
    created_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    updated_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    counts => {
        type                => PositiveOrZeroInt,
        may_require_refresh => 1,
    },
    kind => NonEmptyStr,
);

with 'WebService::PivotalTracker::Entity';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _self_uri {
    my $self = shift;

    return sprintf( '/projects/%s/labels/%s', $self->project_id, $self->id );
}
## use critic

1;

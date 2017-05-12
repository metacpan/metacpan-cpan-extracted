package WebService::PivotalTracker::Me;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

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
    has_google_identit            => Bool,
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

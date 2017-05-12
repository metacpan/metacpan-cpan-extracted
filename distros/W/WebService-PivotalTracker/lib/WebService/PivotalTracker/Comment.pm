package WebService::PivotalTracker::Comment;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Types
    qw( ArrayRef DateTimeObject Maybe NonEmptyStr PositiveInt );

use Moo;

has( @{$_} ) for props_to_attributes(
    id         => PositiveInt,
    story_id   => Maybe [PositiveInt],
    epic_id    => Maybe [PositiveInt],
    text       => NonEmptyStr,
    person_id  => PositiveInt,
    created_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    updated_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    file_attachment_ids   => ArrayRef [PositiveInt],
    google_attachment_ids => ArrayRef [PositiveInt],
    commit_identifier     => Maybe    [NonEmptyStr],
    commit_type           => Maybe    [NonEmptyStr],
    kind                  => NonEmptyStr,
);

with 'WebService::PivotalTracker::Entity';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _self_uri {
    my $self = shift;

    return $self->_client->build_uri(
        sprintf(
            '/projects/%s/stories/%s/comments/%s',
            $self->project_id,
            $self->story_id,
            $self->id,
        )
    );
}
## use critic

1;

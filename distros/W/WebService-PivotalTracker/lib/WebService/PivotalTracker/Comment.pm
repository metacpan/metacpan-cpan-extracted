package WebService::PivotalTracker::Comment;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.11';

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

# ABSTRACT: A story comment

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::Comment - A story comment

=head1 VERSION

version 0.11

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a single comment on a story or epic.

=for Test::Synopsis my $story;

  my $comment = $story->comments->[0];
  say $comment->text;

=head1 ATTRIBUTES

This class provides the following attribute accessor methods. Each one
corresponds to a property defined by the L<PT REST API V5 comment resource
docs|https://www.pivotaltracker.com/help/api/rest/v5#comment_resource>.

=head2 id

=head2 story_id

This will be C<undef> for epic comments.

=head2 epic_id

This will be C<undef> for story comments.

=head2 text

The text in Markdown.

=head2 person_id

=head2 created_at

This will be returned as a L<DateTime> object.

=head2 updated_at

This will be returned as a L<DateTime> object.

=head2 file_attachment_ids

An arrayref of ids.

=head2 google_attachment_ids

An arrayref of ids.

=head2 commit_identifier

=head2 commit_type

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

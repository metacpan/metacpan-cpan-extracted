package WebService::PivotalTracker::Label;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.12';

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

# ABSTRACT: A label on a story

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::Label - A label on a story

=head1 VERSION

version 0.12

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a label on a story.

=for Test::Synopsis my $story;

  my $label = $story->labels->[0];
  say $label->name;

=head1 ATTRIBUTES

This class provides the following attribute accessor methods. Each one
corresponds to a property defined by the L<PT REST API V5 label resource
docs|https://www.pivotaltracker.com/help/api/rest/v5#label_resource>.

=head2 id

=head2 project_id

=head2 name

=head2 created_at

This will be returned as a L<DateTime> object.

=head2 updated_at

This will be returned as a L<DateTime> object.

=head2 counts

=head2 kind

=head2 raw_content

The raw JSON used to create this object.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2020 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

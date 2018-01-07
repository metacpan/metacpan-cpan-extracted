package WebService::PivotalTracker::ProjectIteration;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.10';

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

# ABSTRACT: A single iteration in a project

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker::ProjectIteration - A single iteration in a project

=head1 VERSION

version 0.10

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a single project iteration.

=for Test::Synopsis my $pt;

  my $iterations = $pt->project_iterations(...)->[0];
  say $_->name for $iteration->stories->@*;

=head1 ATTRIBUTES

This class provides the following attribute accessor methods. Each one
corresponds to a property defined by the L<PT REST API V5 iteration resource
docs|https://www.pivotaltracker.com/help/api/rest/v5#iteration_resource>.

=head2 number

=head2 length

=head2 team_strength

=head2 start

This will be returned as a L<DateTime> object.

=head2 finish

This will be returned as a L<DateTime> object.

=head2 kind

=head2 raw_content

The raw JSON used to create this object.

=head1 METHODS

This class provides the following methods:

=head2 $iter->stories

This method contains an array reference of
L<WebService::PivotalTracker::Story> object contained in the iteration.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

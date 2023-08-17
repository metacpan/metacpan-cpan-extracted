package WebService::OpenSky::Response::FlightTrack;

# ABSTRACT: A class representing a flight track from the OpenSky Network API
use WebService::OpenSky::Moose;
use WebService::OpenSky::Core::Waypoint;
extends 'WebService::OpenSky::Response';

our $VERSION = '0.4';

my @ATTRS = qw(
  icao24
  callsign
  startTime
  endTime
  path
);

# XXX ugly, but this is part of an experimental API endpoint from OpenSky
param [@ATTRS] => ( is => 'rw', required => 0 );

method BUILD(@args) {
    foreach my $attr (@ATTRS) {
        $self->$attr( $self->raw_response->{$attr} );
    }
}

method _create_response_objects() {
    my @path = map { WebService::OpenSky::Core::Waypoint->new($_) } $self->path->@*;
    $self->path( \@path );
    return \@path;
}

method _empty_response() {
    return { path => [] };
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Response::FlightTrack - A class representing a flight track from the OpenSky Network API

=head1 VERSION

version 0.4

=head1 DESCRIPTION

A set of "waypoints" for a given aircraft flight.

This class inherits from L<WebService::OpenSky::Response>. Please see that
module for the available methods. Individual responses are from the
L<WebService::OpenSky::Core::Waypoint> class.

=head1 ADDITIONAL ATTRIBUTES

In addition to the methods and attributes provided by the parent class, this
class provides the following:

=head2 C<icao24>

The ICAO24 ID of the aircraft.

=head2 C<callsign>

The callsign of the aircraft. Can be C<undef>.

=head2 C<startTime>

The time of the first waypoint in seconds since epoch (Unix time).

=head2 C<endTime>

The time of the last waypoint in seconds since epoch (Unix time).

=head2 C<waypoints>

The waypoints of the flight. This is an arrayref of L<WebService::OpenSky::Core::Waypoint> objects.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

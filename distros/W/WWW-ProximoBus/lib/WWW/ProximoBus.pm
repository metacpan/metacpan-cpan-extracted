package WWW::ProximoBus;

use strict;
use warnings;

use Any::Moose;
use Carp;
use JSON;
use LWP::UserAgent;

our $VERSION = '0.01';

has 'api_host' => ( is => 'rw', default => 'proximobus.appspot.com' );

has 'ua' => (
    is     => 'rw',
    isa    => 'LWP::UserAgent',

    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->max_redirect( 0 );
        $ua->timeout( 5 );
        return $ua;
    },
);

sub uri_for {
    my $self = shift;
    my ($path) = @_;

    $path = '/' . $path unless $path =~ m!^/!;
    return 'http://' . $self->api_host . $path;
}

sub get {
    my $self = shift;
    my ($path) = @_;

    my $uri = $self->uri_for($path);
    my $res = $self->ua->get($uri);
    if ($res->is_success) {
        return JSON::decode_json($res->content);
    }
    else {
        die "ProximoBus HTTP error " . $res->code . ": " . $res->content;
    }
}

sub agencies {
    my $self = shift;
    my $path = "/agencies.json";
    return $self->get($path);
}

sub agency {
    my $self = shift;
    my ($agency) = @_;
    croak "need an agency" unless ($agency);

    my $path = "/agencies/$agency.json";
    return $self->get($path);
}

sub routes {
    my $self = shift;
    my ($agency) = @_;
    croak "need an agency" unless ($agency);

    my $path = "/agencies/$agency/routes.json";
    return $self->get($path);
}

sub route {
    my $self = shift;
    my ($agency, $route) = @_;
    croak "need an agency" unless ($agency);
    croak "need a route" unless ($route);

    my $path = "/agencies/$agency/routes/$route.json";
    return $self->get($path);
}

sub stops_for_route {
    my $self = shift;
    my ($agency, $route) = @_;
    croak "need an agency" unless ($agency);
    croak "need a route" unless ($route);

    my $path = "/agencies/$agency/routes/$route/stops.json";
    return $self->get($path);
}

sub runs {
    my $self = shift;
    my ($agency, $route) = @_;
    croak "need an agency" unless ($agency);
    croak "need a route" unless ($route);

    my $path = "/agencies/$agency/routes/$route/runs.json";
    return $self->get($path);
}

sub run {
    my $self = shift;
    my ($agency, $route, $run) = @_;
    croak "need an agency" unless ($agency);
    croak "need a route" unless ($route);
    croak "need a run" unless ($run);

    my $path = "/agencies/$agency/routes/$route/runs/$run.json";
    return $self->get($path);
}

sub stops_for_run {
    my $self = shift;
    my ($agency, $route, $run) = @_;
    croak "need an agency" unless ($agency);
    croak "need a route" unless ($route);
    croak "need a run" unless (run);

    my $path = "/agencies/$agency/routes/$route/runs/$run/stops.json";
    return $self->get($path);
}

sub vehicles_for_route {
    my $self = shift;
    my ($agency, $route) = @_;
    croak "need an agency" unless ($agency);
    croak "need a route" unless ($route);

    my $path = "/agencies/$agency/routes/$route/vehicles.json";
    return $self->get($path);
}

sub stop {
    my $self = shift;
    my ($agency, $stop) = @_;
    croak "need an agency" unless ($agency);
    croak "need a stop" unless ($stop);

    my $path = "/agencies/$agency/stops/$stop.json";
    return $self->get($path);
}

sub routes_for_stop {
    my $self = shift;
    my ($agency, $stop) = @_;
    croak "need an agency" unless ($agency);
    croak "need a stop" unless ($stop);

    my $path = "/agencies/$agency/stops/$stop/routes.json";
    return $self->get($path);
}

sub predictions_for_stop {
    my $self = shift;
    my ($agency, $stop) = @_;
    croak "need an agency" unless ($agency);
    croak "need a stop" unless ($stop);

    my $path = "/agencies/$agency/stops/$stop/predictions.json";
    return $self->get($path);
}

sub predictions_for_stop_by_route {
    my $self = shift;
    my ($agency, $stop, $route) = @_;
    croak "need an agency" unless ($agency);
    croak "need a stop" unless ($stop);
    croak "need a route" unless ($route);

    my $path = "/agencies/$agency/stops/$stop/predictions/by-route/$route.json";
    return $self->get($path);
}

sub vehicles {
    my $self = shift;
    my ($agency) = @_;
    croak "need an agency" unless ($agency);

    my $path = "/agencies/$agency/vehicles.json";
    return $self->get($path);
}

sub vehicle {
    my $self = shift;
    my ($agency, $vehicle) = @_;
    croak "need an agency" unless ($agency);
    croak "need a vehicle" unless ($vehicle);

    my $path = "/agencies/$agency/vehicles/$vehicle.json";
    return $self->get($path);
}

"The next inbound train is going out of service. Do not board.";

=head1 NAME

WWW::ProximoBus - A simple client library for the ProximoBus API.

=head1 SYNOPSIS

    my $proximo = WWW::ProximoBus->new();
    my $agencies = $proximo->agencies();
    my $agency = $agencies->{items}[0];
    my $routes = $proximo->routes($agency->{id});
    for my $route (@{$routes->{items}}) {
        print $route->{id};
    }

=head1 DESCRIPTION

WWW::ProximoBus is a Perl library implementing an interface to the ProximoBus API.

ProximoBus is a simple alternative API for NextBus' publicly-available data.
Read more about it at http://proximobus.appspot.com/docs.html .

=head1 WARNINGS

From the ProximoBus documentation:

=over 4

This API is provided in the hope that it is useful, but there are no availability guarantees nor any warranty about the accuracy of the provided data. Use of this data is at the risk of the user.

The author reserves the right to deny access to ProximoBus to anyone at any time and for any reason. While backward compatibility will be preserved as much as possible, the author reserves the right to change any aspect of the provided API at any time for any reason and with no notice.

=back

=head1 AUTHOR

Sam Kimbrel (kimbrel@me.com)

=head1 COPYRIGHT

Copyright 2011 - Sam Kimbrel

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://proximobus.appspot.com/
http://nextbus.com/

=cut







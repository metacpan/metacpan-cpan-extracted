package Transport::AU::PTV::Route;
$Transport::AU::PTV::Route::VERSION = '0.03';
# VERSION
# PODNAME
# ABSTRACT: a route on the Victorian Public Transport Network.

use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;
use Transport::AU::PTV::Stops;
use Transport::AU::PTV::Runs;


sub new {
    my $class = shift;
    my ($api, $args_ref) = @_;

    my $api_response = $api->request("/v3/routes/$args_ref->{route_id}");

    return $api_response if $api_response->error;
    
    return bless { api => $api, route => $api_response->content()->{route} }, $class;
}



sub raw {
    my $class = shift;
    my ($api, $route) = @_;

    return bless { api => $api, route => $route }, $class;
}

sub id { return $_[0]->{route}{route_id}; }


sub gtfs_id { return $_[0]->{route}{route_gtfs_id}; }


sub number { return $_[0]->{route}{route_number}; }


sub name { return $_[0]->{route}{route_name}; }


sub type { return $_[0]->{route}{route_type}; }



sub stops {
    my $self = shift;

    return Transport::AU::PTV::Stops->new( $self->{api}, { route_id => $self->{route}{route_id}, route_type => $self->{route}{route_type} } );
}


sub runs {
    my $self = shift;

    return Transport::AU::PTV::Runs->new( $self->{api}, { route_id => $self->{route}{route_id}, route_type => $self->{route}{route_type} } );
}








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Route - a route on the Victorian Public Transport Network.

=head1 VERSION

version 0.03

=head1 NAME

Transport::AU::PTV::Routes - a collection of Melbourne public transport routes (train, tram, bus, etc).

=head1 Synopsis

    # Get a single route from the list of all routes.
    my $route = Transport::AU::PTV->new({ ...})->routes->find({ id => 15 });
    my $route_name = $route->name;
    my $route_number = $route->number;

=head1 Description

This object represents a single route on the Public Transport Victoria network.

=head1 Methods

=head2 new

    my $route = Transport::AU::PTV::Route->( Transport::AU::PTV::APIRequest->new({ ... }, { route_id => 2 });

=head2 raw 

The constructor for this object should not be called directly - instead the route should be accesses from the L<Transport::AU::PTV::Routes> object.

=head2 id 

Returns the ID of the route.

=head2 gtfs_id 

    my $gtfs_id = $route->gtfs_id;

Returns the GTFS ID of the route.

=head2 number

    my $number = $route->number

Returns the number of the route.

=head2 name

    my $name = $route->name;

Returns the name of the route

=head2 type

    my $type = $route->type;

Returns the type of route.

=head2 stops

    my $stops = $route->stops;

Returns a L<Transport::AU::PTV::Stops> collection object representing the stops on the route.

=head2 runs 

    my $runs = $route->runs;

Returns a L<Transport::AU::PTV::Runs> collection object representing the runs of the route.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package WWW::EFA::RouteFactory;
use Moose;
use WWW::EFA::Route;
use WWW::EFA::PartialRoute;
use WWW::EFA::DateFactory;
use WWW::EFA::Stop;
use Carp;

=head1 NAME

WWW::EFA::RouteFactory - A factory for creating L<WWW::EFA::Route> objects.

=head1 VERSION

    Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  my $factory = WWW::EFA::RouteFactory->new();

=head1 ATTRIBUTES

TODO: RCL 2012-01-22 Documentation

=cut

has 'location_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::LocationFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::LocationFactory->new() },
    );

has 'date_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::DateFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::DateFactory->new() },
    );


=head1 METHODS

=head2 route_from_itdRoute

Returns a L<WWW::EFA::Route> object

  my $route = $factory->route_from_itdRoute( $element );

Expects an L<XML::LibXML::Element> of XML with this kind of XML:

TODO: RCL 2012-01-22 Example XML

=cut
sub route_from_itdRoute {
    my $self = shift;
    my $elem = shift;

    my $route = WWW::EFA::Route->new(
        changes         => $elem->getAttribute( 'changes' ),
        vehicle_time    => $elem->getAttribute( 'vehicleTime' ),
        );

    # TODO: RCL 2011-11-11 Implement handling for itdFare for #fares
    # my @fares = $elem->findnodes( 'itdfare' );
    my @partials;
    foreach my $part_elem ( $elem->findnodes( 'itdPartialRouteList/itdPartialRoute' ) ){
        my $partial = $self->partial_from_itdPartialRoute( $part_elem );
        push( @partials, $partial );
    }
    
    # TODO: RCL 2011-11-11 Sort @partial
    # Get earliest depart and latest arrive from @partial
    my %times;
    foreach my $partial( @partials ){
        if( not $times{departure} or $partial->departure_time < $times{departure} ){
            $times{departure} = $partial->departure_time;
        }
        if( not $times{arrival} or $partial->arrival_time > $times{arrival} ){
            $times{arrival} = $partial->arrival_time;
        }
    }
    $route->arrival_time( $times{arrival} );
    $route->departure_time( $times{departure} );

    $route->partial_routes( \@partials );

    return $route;
}

=head2 partial_from_itdPartialRoute

Returns a L<WWW::EFA::PartialRoute> object

  my $route = $factory->partial_from_itdPartialRoute( $part_element );

Expects an L<XML::LibXML::Element> of XML with this kind of XML:

TODO: RCL 2012-01-22 Example XML

=cut
sub partial_from_itdPartialRoute {
    my $self = shift;
    my $elem = shift;
    
    # TODO: RCL 2011-11-11 There's so much more stuff in here which we could use...
    # itdStopSeq - the sequence of stops for each partial
    #
    my %part_route_params;
    foreach my $point_elem ( $elem->findnodes( 'itdPoint' ) ){
        my $location = $self->location_factory->location_from_itdPoint( $point_elem );
        if( $location and $location->usage and $location->usage =~ m/^(departure|arrival)$/ ){
            $part_route_params{$location->usage . '_location'} = $location;
        }
        my( $date_elem ) = $point_elem->findnodes( 'itdDateTime' );
        if( $date_elem ){
            my $time = $self->date_factory->date_from_itdDateTime( $date_elem );
            $part_route_params{$location->usage . '_time'} = $time;
        }
    }

    my @stops;
    foreach my $stop_elem ( $elem->findnodes( 'itdStopSeq/itdPoint' ) ){
        my $location = $self->location_factory->location_from_itdPoint( $stop_elem );
        my %stop_params = ( location => $location );

        my @times;
        foreach my $time_elem ( $stop_elem->findnodes( 'itdDateTime' ) ){
            my $time = $self->date_factory->date_from_itdDateTime( $time_elem );
            push( @times, $time ) if $time;
        }
        @times = sort{ $a <=> $b } @times;
        
        if( scalar( @times ) > 0 ){
            $stop_params{departure_time} = $times[0];
            $stop_params{arrival_time} = $times[-1];
        }

        my $stop = WWW::EFA::Stop->new( %stop_params );
        push( @stops, $stop );
    }
    $part_route_params{stops} = \@stops;
    
    my $partial = WWW::EFA::PartialRoute->new( %part_route_params );
    return $partial;
}

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>


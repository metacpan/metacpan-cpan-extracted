package WWW::EFA::CoordinatesFactory;
use Moose;
use Carp;
use WWW::EFA::Coordinates;

=head1 NAME

A Factory for creating L<WWW::EFA::Coordinates> objects.

=head1 SYNOPSIS

  my $factory = WWW::EFA::CoordinatesFactory->new();

=cut

=head1 METHODS

=head2 coordinates_from_XY

Method to extract the coordinates from an element with x and y attributes

  my $coordinates = $factory->coordinates_from_XY( $doc->findnodes( 'itdDeparture' ) );

Expects an XML::LibXML::Element of XML like this:

  
<itdDeparture stopID="8" x="11535078.00000" y="48143035.00000" mapName="WGS84" area="5" 
    platform="" platformName="" stopName="Donnersbergerbrücke" nameWO="Donnersbergerbrücke" countdown="1"> 
    ...
</itdDeparture>

Returns a L<WWW::EFA::Coordinates> object

=cut
sub coordinates_from_XY {
    my $self = shift;
    my $elem = shift;
    
    if( not $elem->hasAttribute( 'y' ) or not $elem->hasAttribute( 'x' ) ){
        return undef;
    }

    my $coordinates = WWW::EFA::Coordinates->new(
        longitude   => &_clean_coordinates( $elem->getAttribute( 'x' ) ),
        latitude    => &_clean_coordinates( $elem->getAttribute( 'y' ) ),
        );
    return $coordinates;
}


=head2 coordinates_from_itdPathCoordinates

Method to extract the coordinates from an itdPathCoordinates element

  my $coordinates = $factory->coordinates_from_itdPathCoordinates( $doc->findnodes( 'itdPathCoordinates' ) );

Expects an XML::LibXML::Element of XML like this:

  
<itdPathCoordinates>
  <coordEllipsoid>WGS84</coordEllipsoid>
  <coordType>GEO_DECIMAL</coordType>
  <itdCoordinateString decimal="." cs="," ts="&#x20;">11529230.00000,48140331.00000</itdCoordinateString>
</itdPathCoordinates>

=cut
sub coordinates_from_itdPathCoordinates {
    my $self = shift;
    my $elem = shift;
    
    my( $map_elem ) = $elem->findnodes( 'coordEllipsoid' );
    if( not $map_elem ){
        croak( "Could not find element: coordEllipsoid" );
    }

    my( $type_elem ) = $elem->findnodes( 'coordType' );
    if( not $type_elem ){
        croak( "Could not find element: coordType" );
    }

    my( $coord_elem ) = $elem->findnodes( 'itdCoordinateString' );
    if( not $coord_elem ){
        croak( "Could not find element: itdCoordinateString" );
    }

    # Make sure expected type and map_name
    my $type = $type_elem->textContent;
    if( not $type eq 'GEO_DECIMAL' ){
        croak( "Invalid coordinate type: " . $type );
    }
    my $map_name = $map_elem->textContent;
    if( not $map_name eq 'WGS84' ){
        croak( "Invalid map name: " . $map_name );
    }

    my $separator = $coord_elem->getAttribute( 'cs' );
    my( $longitude, $latitude ) = &_clean_coordinates( split( $separator, $coord_elem->textContent ) );
    my $coordinates = WWW::EFA::Coordinates->new(
        longitude   => $longitude,
        latitude    => $latitude,
        map_name    => $map_name,
        );
    return $coordinates;

}

# Sometimes coordinates are given in the format '11529230.00000' when they really mean '11.529230'
# This will clean them up...
sub _clean_coordinates {
    my @in = @_;
    foreach( 0 .. $#in ){
        if( $in[$_] and $in[$_] =~ m/^(\d+)(\d{6})\D?/ ){
            $in[$_] = ( $1 + ( $2 * 1e-6 ) );
        }
    }
    return @in;
}

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>


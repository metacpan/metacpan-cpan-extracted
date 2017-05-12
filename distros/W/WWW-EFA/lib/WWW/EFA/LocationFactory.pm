package WWW::EFA::LocationFactory;
use Moose;
use WWW::EFA::Location;
use WWW::EFA::Coordinates;
use WWW::EFA::CoordinatesFactory;
use Carp;

=head1 NAME

WWW::EFA::LocationFactory - A Factory for creating L<WWW::EFA::Location> objects.

=head1 VERSION

    Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  my $factory = WWW::EFA::LocationFactory->new();

=head1 ATTRIBUTES

TODO: RCL 2012-01-22 Documentation

=cut

has 'coord_factory' => ( is => 'ro', isa => 'WWW::EFA::CoordinatesFactory', lazy => 1,
    default => sub{ WWW::EFA::CoordinatesFactory->new() },
);


=head1 METHODS

=head2 location_from_odvNameElem

Returns a L<WWW::EFA::Location> object

  my $location = $factory->location_from_odvNameElem( $itd_odv->findnodes( 'odvNameElem' ) );

Expects an XML::LibXML::Element of XML like this:

  
<odvNameElem x="11534639.00000" y="48142484.00000" 
  mapName="WGS84" stopID="8" value="8:1" isTransferStop="0" 
  matchQuality="100000">Donnersbergerbrücke</odvNameElem>

=cut
sub location_from_odvNameElem {
    my $self = shift;
    my $elem = shift;

    #TODO: RCL 2011-09-15 There must be a better way to do this...
    my @mapping_as_array = (
        anyType         => 'type',
        id              => 'id',
        locality        => 'locality',
        mapName         => 'map_name',
        matchQuality    => 'match_quality',
        objectName      => 'name',
        poiID           => 'poi_id',
        streetID        => 'street_id',
        isTransferStop  => 'is_transfer_stop',
        value           => 'value',
        stopID          => 'id',
        place           => 'name',
    );

    my @mapping_keys;
    foreach( my $idx = 0; $idx < scalar( @mapping_as_array ); $idx += 2 ){
        unshift( @mapping_keys, $mapping_as_array[$idx] );
    }
    my %mapping = @mapping_as_array;

    # Transform the location data to the format understood by WWW::EFA::Location
    my %loc_data = 
        map { $mapping{ $_ } => $elem->getAttribute( $_ ) }    # Create the new hash
        grep{ $elem->hasAttribute( $_ ) }                      # Only those which were defined in the data
        grep{ $mapping{ $_ } }                                      # Remove any whose mapping is undefined
        @mapping_keys;

    $loc_data{name}  ||= $elem->textContent();

    # Clean up the encoding on the text strings
    %loc_data = 
        map { $_  => $loc_data{$_} }
        keys %loc_data;
    
    my $coordinates = $self->coord_factory->coordinates_from_XY( $elem );
    $loc_data{ coordinates } = $coordinates if( $coordinates ); 
 
    my $loc = WWW::EFA::Location->new( %loc_data );
    
    return $loc;
}

=head2 location_from_itdOdvAssignedStop

Same as location_from_odvNameElem because these are basically the same XML, but
different element name.

=cut
sub location_from_itdOdvAssignedStop {
    my $self = shift;
    return $self->location_from_odvNameElem( @_ );
}


=head2 location_from_coordInfoItem

Returns a L<WWW::EFA::Location> object

  my $location = $factory->location_from_coordInfoItem( $itd_odv->findnodes( 'coordInfoItem' ) );

Expects an XML::LibXML::Element of XML like this:

  
<coordInfoItem type="STOP" id="64" name="Barthstraße" addName="" omc="9162000" 
    placeID="1" locality="München" gisLayer="SYS-STOP" gisID="64" 
    distance="190" stateless="64">
  <itdPathCoordinates>
    <coordEllipsoid>WGS84</coordEllipsoid>
    <coordType>GEO_DECIMAL</coordType>
    <itdCoordinateString decimal="." cs="," ts="&#x20;">11529230.00000,48140331.00000</itdCoordinateString>
  </itdPathCoordinates>
  <genAttrList>
    <genAttrElem>
      <name>STOP_NAME_WITH_PLACE </name>
      <value>Barthstraße</value>
    </genAttrElem>
    <genAttrElem>
      <name>STOP_MAJOR_MEANS</name>
      <value>4</value>
    </genAttrElem>
  </genAttrList>
</coordInfoItem>

=cut
sub location_from_coordInfoItem {
    my $self = shift;
    my $elem = shift;

    if( not $elem->hasAttribute( 'type' ) or $elem->getAttribute( 'type' ) ne 'STOP' ){
        croak( sprintf "Unknown location type found: %s", $elem->getAttribute( 'type' ) );
    }

    my( $coord_elem ) = $elem->findnodes( 'itdPathCoordinates' );
    if( not $coord_elem ){
        croak( "Could not find itdPathCoordinates\n" . $elem->toString( 2 ) );
    }

    my $coordinates = $self->coord_factory->coordinates_from_itdPathCoordinates( $coord_elem );
   
    if( not $coordinates or 0 ){
        croak( "No coordinate found in coordInfoItem\n" . $coord_elem->toString );
    }

    my %loc_params = 
        map { $_ => $elem->getAttribute( $_ ) }
        grep { $elem->hasAttribute( $_ ) }
        qw/name locality distance id/;
    $loc_params{coordinates} = $coordinates;

    my $loc = WWW::EFA::Location->new( %loc_params );
    
    return $loc;
}


=head2 location_from_itdPoint

Returns a L<WWW::EFA::Location> object

  my $location = $factory->location_from_itdPoint( $doc->findnodes( 'itdPoint' ) );

Expects an XML::LibXML::Element of XML like this:

  
<itdPoint stopID="64" area="20" platform="18H19" name="Barthstraße" 
    nameWO="Barthstraße" platformName="" usage="departure"
    x="11529096.00000" y="48140348.00000" mapName="WGS84"
    omc="9162000" placeID="1" locality="München">
</itdPoint>

=cut
sub location_from_itdPoint {
    my $self = shift;
    my $elem = shift;


    my %mapping = (
        stopID      => 'id',
        platform    => 'platform',
        name        => 'name',
        usage       => 'usage',
        mapName     => 'mapName',
        );
         
    my %loc_params = 
        map { $mapping{ $_ } => $elem->getAttribute( $_ ) }
        grep { $elem->hasAttribute( $_ ) }
        keys( %mapping );
    
    my $coordinates = $self->coord_factory->coordinates_from_XY( $elem );
    $loc_params{coordinates} = $coordinates if( $coordinates );

    my $location = WWW::EFA::Location->new( %loc_params );

    return $location;
}

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>


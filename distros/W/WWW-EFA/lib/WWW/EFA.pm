package WWW::EFA;
use Moose;
use MooseX::Params::Validate;

# CPAN modules
use LWP::UserAgent;
use YAML;
use Carp;
use Try::Tiny;
use File::Spec::Functions;
use XML::LibXML;
use Class::Date qw/now/;

### Local modules
# Objects
use WWW::EFA::Departure;
use WWW::EFA::Line;
use WWW::EFA::Location;
use WWW::EFA::Place;
use WWW::EFA::Station;
use WWW::EFA::ResultHeader;

# Factories
use WWW::EFA::DepartureFactory;
use WWW::EFA::LineFactory;
use WWW::EFA::LocationFactory;
use WWW::EFA::PlaceFactory;
use WWW::EFA::HeaderFactory;
use WWW::EFA::RouteFactory;

use WWW::EFA::Request;
use WWW::EFA::DeparturesResult;
use WWW::EFA::ConnectionsResult;


=head1 NAME

WWW::EFA - Interface to EFA sites (Elektronische Fahrplanauskunft)

=head1 VERSION

    Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Get location of public transport stops and connection details.

    use WWW::EFA;

    my $efa = WWW::EFA->new();
    ...

=head1 PARAMS/ACCESSORS

TODO: RCL 2012-01-22 document params/accessors

=cut

has 'base_url'      => ( is => 'ro', isa => 'Str', required => 1,   );
has 'cache_dir'     => ( is => 'ro', isa => 'Str',                  );

has 'agent' => (
    is          => 'ro',
    isa         => 'LWP::UserAgent',
    required    => 1,
    lazy        => 1,
    default     => sub{ LWP::UserAgent->new() },
);


has 'place_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::PlaceFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::PlaceFactory->new() },
    );

has 'line_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::LineFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::LineFactory->new() },
    );

has 'location_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::LocationFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::LocationFactory->new() },
    );

has 'departure_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::DepartureFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::DepartureFactory->new() },
    );

has 'route_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::RouteFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::RouteFactory->new() },
    );

has 'header_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::HeaderFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::HeaderFactory->new() },
    );

# Requests per minute
has 'sleep_between_requests' => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

has 'last_request_time' => (
    is          => 'rw',
    isa         => 'Int',
);

=head1 METHODS

=head2 departures

Queries the XSLT_DM_REQUEST method from the EFA server.

=head3 Params

=over 4

=item location => L<WWW::EFA::Location> (which must have the id (stopID) defined)

=back

=cut
sub departures {
    my ( $self, %params ) = validated_hash(
        \@_,
        location => { isa => 'WWW::EFA::Location'    },
        equivs   => { isa => 'Bool', default  => '0' },
        limit    => { isa => 'Int' , optional => 1   },
    );
    if( not $params{location}->id ){
        croak( "Need a location with an id (stopID) to get departures" );
    }

    # Build the request for the stopfinder request
    # The suffix '_sf' in many arguments is for the 'stop finder' requst
    my $req = WWW::EFA::Request->new(
        base_url        => $self->base_url,
        service         => 'XSLT_DM_REQUEST'
    );

    $req->set_argument( 'type_dm'                       , 'stop'                  );
    $req->set_argument( 'useRealtime'                   , 1                       );
    $req->set_argument( 'mode'                          , 'direct'                );
    $req->set_argument( 'name_dm'                       , $params{location}->id   );
    $req->set_argument( 'deleteAssignedStops_dm'        , $params{equivs}         );
    $req->set_argument( 'limit'                         , $params{limit}          ) if $params{limit};

    # Get the reader
    my $doc = $self->_get_doc( request => $req );

    # Move into the itdDepartureMonitorRequest element
    ( $doc ) = $doc->findnodes( 'itdDepartureMonitorRequest' );
    
    # Sanity checks
    my( $odv_elem ) = $doc->findnodes( "itdOdv" );
    if( not $odv_elem or $odv_elem->getAttribute( 'usage' ) ne 'dm' ){
        croak( "Could not find itdOdv/attribute::usage = 'dm'" );
    }

    # This is the result we will return
    my $result = WWW::EFA::DeparturesResult->new();

    my( $name_elem ) = $odv_elem->findnodes( 'itdOdvName' );
    if( not $name_elem or not $name_elem->hasAttribute( 'state' ) or $name_elem->getAttribute( 'state' ) ne 'identified' ){
        # TODO: RCL 2011-11-14 Deal with list or other error options better
        return $result;
    }

    my $departure_location = $self->location_factory->location_from_odvNameElem( $odv_elem->findnodes( 'itdOdvName/odvNameElem' ) );
    if( not $departure_location ){
        return $result;
    }

    # If the Location does not have a name, get it from the place
    if( not $departure_location->name ){
        my $place = $self->place_factory->place_from_itdOdvPlace( $odv_elem->findnodes( 'itdOdvPlace' ) );
        $departure_location->name( $place->name );
    }
    
    $result->add_departure_station( WWW::EFA::Station->new( location => $departure_location ) );

    # Alternative (further away) departure stations
    foreach my $alt_station_element ( $odv_elem->findnodes( 'itdOdvAssignedStops/itdOdvAssignedStop' ) ){
        # TODO: RCL 2011-11-06 This hasn't been tested yet - I have never seen an example with more stops...
        my $location = $self->location_factory->location_from_itdOdvAssignedStop( $alt_station_element );
        $result->add_departure_station( WWW::EFA::Station->new( location => $location ) );
    }

    # Get the lines
    foreach my $line_elem ( $doc->findnodes( 'itdServingLines/itdServingLine' ) ) {
        my $line = $self->line_factory->line_from_itdServingLine( $line_elem );
        $result->add_line( $line );
    }

    # Get the departures
    foreach my $dep_elem ( $doc->findnodes( 'itdDepartureList/itdDeparture' ) ){
        my $departure = $self->departure_factory->departure_from_itdDeparture( $dep_elem );
        $result->add_departure( $departure );
    }
    
    return $result;
}

=head2 trips

Queries the XSLT_TRIP_REQUEST2 method from the EFA server.

=head3 Required Params

=over 4

=item I<from> => L<WWW::EFA::Location>

=item I<to> => L<WWW::EFA::Location>

=item I<date> => L<Class::Date> of the time to be searched

=back

=head3 Optional Params

=over 4

=item I<via> => L<WWW::EFA::Location> (default undef)

=item I<is_departure> => $boolean (set to true if the date is the departure time)
  
=item I<language> => $string (language to return results in. Default 'de')

=item I<walk_speed> => $number (override default walk speed.)
    TODO: RCL 2011-08-23 What is walk speed? km/h? m/s?

=back

=cut
sub trips {
    my ( $self, %params ) = validated_hash(
        \@_,
        from         => { isa => 'WWW::EFA::Location'                     },
        via          => { isa => 'WWW::EFA::Location' , optional => 1     },
        to           => { isa => 'WWW::EFA::Location'                     },
        date         => { isa => 'Class::Date'        , default  => now() },
        is_departure => { isa => 'Bool'               , default  => 1     },
        language     => { isa => 'Str'                , default  => 'de'  },
        walk_speed   => { isa => 'Num',               , optional => 1     },
        products     => { isa => 'ArrayRef'           , optional => 1     },
    );

    # Build the request for the stopfinder request
    # The suffix '_sf' in many arguments is for the 'stop finder' requst
    my $req = WWW::EFA::Request->new(
        base_url  => $self->base_url,
        service   => 'XSLT_TRIP_REQUEST2',
    );

    $req->set_argument( 'sessionID'                     , '0'                                   );
    $req->set_argument( 'requestID'                     , '0'                                   );
    $req->set_argument( 'ptOptionsActive'               , '1'                                   );
    $req->set_argument( 'useRealtime'                   , '1'                                   );
    $req->set_argument( 'useProxyFootSearch'            , '1'                                   );
    $req->set_argument( 'language'                      , $params{language}                     );
    $req->set_argument( 'itdTripDateTimeDepArr'         , $params{is_departure} ? 'dep' : 'arr' );
    $req->set_argument( 'changeSpeed'                   , $params{walk_speed}                   ) if $params{walk_speed}; 

    $req->set_argument( 'itdDate'                       , $params{date}->strftime( '%Y%m%d' ) );
    $req->set_argument( 'itdTime'                       , $params{date}->strftime( '%H%M' ) );

    # Add the locations
    $req->add_location( 'origin'        , $params{from} );
    $req->add_location( 'destination'   , $params{to}   );
    $req->add_location( 'via'           , $params{via}  ) if( $params{via} );

    # TODO: RCL 2011-11-10 make mapping homogeneous with DepartureFactory for mot_type
    if ( $params{products} ){
        $req->set_argument( 'includedMeans'             , 'checkbox'    );
        
        my %products = 
            map{ $_ => 1 }
            @{ $params{products} };

	if ( $products{I} or $products{R} ){
            $req->set_argument( 'inclMOT_0',    'on' );
        }
	if( $products{S} ){
	    $req->set_argument( 'inclMOT_1',    'on' );
        }
        if( $products{U} ){
            $req->set_argument( 'inclMOT_2',    'on' );
        }
        if( $products{T} ){
            $req->set_argument( 'inclMOT_3',    'on' );
            $req->set_argument( 'inclMOT_4',    'on' );
        }
        if( $products{B} ){
            $req->set_argument( 'inclMOT_5',    'on' );
            $req->set_argument( 'inclMOT_6',    'on' );
            $req->set_argement( 'inclMOT_7',    'on' );
        }
        if( $products{P} ){
	    $req->set_argument( 'inclMOT_10',   'on' );
        }

	if( $products{F} ){
	    $req->set_argument( 'inclMOT_9',    'on' );
        }
        if( $products{C} ){
            $req->set_argument( 'inclMOT_8',    'on' );
        }

	$req->set_argument( 'inclMOT_11',   'on' ); # 11 == 'others'. Always on for now

	# workaround for highspeed trains: fails when you want highspeed, but not regional
	if ( $products{I} ){
	    $req->set_argument( 'lineRestriction',  403 ); # means: all but ice
	}
    }

    # Get the data
    my $doc = $self->_get_doc( request => $req );
    my $header = $self->header_factory->header_from_result( $doc );
    
    my $result = WWW::EFA::ConnectionsResult->new(
        request     => $req,
        );

    # Sanity checks
    # Valid date?
    # TODO: RCL 2011-11-11 Check for valid date
    # my( $date_elem ) = $doc->findnodes( 'itdTripdateTime/itdDateTime/itdDate/itdMessage' );

    # Get the requestID
    my( $request_elem ) = $doc->findnodes( 'itdTripRequest' );
    if( $request_elem and $request_elem->hasAttribute( 'requestID' ) ){
        $result->request_id( $request_elem->getAttribute( 'requestID' ) );
    }

    # Get the to/from/via/...
    STOP:
    foreach my $stop_elem ( $request_elem->findnodes( 'itdOdv' ) ){
        my $usage = $stop_elem->getAttribute( 'usage' );
        my( $state_elem ) = $stop_elem->findnodes( 'itdOdvPlace' );
        if( not $state_elem or not $state_elem->hasAttribute( 'state' ) 
            or $state_elem->getAttribute( 'state' ) ne 'identified' ){
            # TODO: RCL 2011-11-11 Deal with ambiguous (not identified) results here.
            next STOP;
        }

        my( $name_elem ) = $stop_elem->findnodes( 'itdOdvName/odvNameElem' );
        if( not $name_elem ){
            #carp( "No odvNameElem inside itdOdv:\n" . $stop_elem->toString( 2 ) );
            next STOP;
        }
        my $location = $self->location_factory->location_from_odvNameElem( $name_elem );
        
        # If there was no location (e.g. no via), then just jump to next STOP
        if( not $location ){
            #carp( "Could not get a location from:\n" . $name_elem->toString( 2 ) );
            next STOP;
        }
        
        my $location_attribute = $usage . '_location';
        
        $result->$location_attribute( $location );
    }

    foreach my $route_elem( $request_elem->findnodes( 'itdItinerary/itdRouteList/itdRoute' ) ){
        my $route = $self->route_factory->route_from_itdRoute( $route_elem );
        $result->add_route( $route );
    }

    return $result;
}

=head2 stop_finder

Queries the XML_STOPFINDER_REQUEST method from the EFA server.

Used to get an address from coordinates

Returns an ArrayRef of L<WWW::EFA::Location>.

=head3 Usage

  
my $location = WWW::EFA::Location->new(
    coordinates => WWW::EFA::Coordinates->new(
        lat => 12.12345,
        lon => 48.12345,
    );
  
my( $address ) = $efa->stop_finder(
    location    => $location,
    );


=head3 Params

=over 4

=item location  => L<WWW::EFA::Location>

=back

=cut
sub stop_finder {
    my ( $self, %params ) = validated_hash(
        \@_,
        location => { isa => 'WWW::EFA::Location' },
    );

    # Build the request for the stopfinder request
    # The suffix '_sf' in many arguments is for the 'stop finder' requst
    my $req = WWW::EFA::Request->new(
        base_url        => $self->base_url,
        service         => 'XML_STOPFINDER_REQUEST',
    );

    # 1=place 2=stop 4=street 8=address 16=crossing 32=poi 64=postcode
    $req->set_argument( 'anyObjFilter_sf'                , 126      );

    $req->set_argument( 'reducedAnyPostcodeObjFilter_sf' , 64       );
    $req->set_argument( 'reducedAnyTooManyObjFilter_sf'  , 2        );
    $req->set_argument( 'useHouseNumberList'             , 'true'   );
    $req->set_argument( 'regionID_sf'                    , 1        );
    $req->add_location( 'sf'                             , $params{location} );

    # Get the doc
    my $doc = $self->_get_doc( request => $req );

    # Make sure the state is defined and a known value.
    # if not, then the XML was not the way we expect it...
    my( $place_elem ) = $doc->findnodes( 'itdStopFinderRequest/itdOdv/itdOdvPlace' );
    if( not $place_elem or not $place_elem->hasAttribute( 'state' ) ){
        croak( "state not found in itdOdvPlace" );
    }
    my $state = $place_elem->getAttribute( 'state' );
    if( $state !~ m/^(identified|list|notidentified)$/ ){
        croak( "Unknown state: $state" );
    }

    # If the location could not be identified, return empty arrayref
    return [] if( $state eq 'notidentified' );

    # Usually there will only be one match, but there could be more (see state 'list' above)
    my @locations;
    foreach my $name_elem( $doc->findnodes( 'itdStopFinderRequest/itdOdv/itdOdvName/odvNameElem' ) ){
        my $location = $self->location_factory->location_from_odvNameElem( $name_elem );
        push( @locations, $location ) if $location->id;
    }

    # nearby stops
    foreach my $alt_station_element ( $doc->findnodes( 'itdStopFinderRequest/itdOdv/itdOdvAssignedStops/itdOdvAssignedStop' ) ){
        # TODO: RCL 2011-11-06 This hasn't been tested yet - I have never seen an example with more stops...
        my $location = $self->location_factory->location_from_itdOdvAssignedStop( $alt_station_element );
        push( @locations, $location );
    }

    # TODO: RCL 2011-11-10 This request also returns a list of itdOdvAssignedStops - it is also suitable
    # for finding the closest stop.  What is the difference to coord request? Maybe this method is
    # superfluous legacy?

    return @locations;
}

=head2 coord_request

Queries the XML_COORD_REQUEST method from the EFA server.
Returns an array reference of L<WWW::EFA::Location> objects.


=head3 Params

=over 4

=item I<location> => L<WWW::EFA::Location>
Must have either id or lon/lat defined

=item I<max_results> => $integer
Maximum number of results to return

=item I<max_distance> => $integer
Maximum distance (meters) around the given location to search

=back

=cut
sub coord_request {
    my ( $self, %params ) = validated_hash(
        \@_,
        location      => { isa => 'WWW::EFA::Location'   },
        max_results   => { isa => 'Int', default => 50   },
        max_distance  => { isa => 'Int', default => 1320 },
    );

    # Build the request
    my $req = WWW::EFA::Request->new(
        base_url        => $self->base_url,
        service         => 'XML_COORD_REQUEST',
    );

    $req->set_argument( 'coordListOutputFormat' , 'STRING'              );
    $req->set_argument( 'type_1'                , 'STOP'                );
    $req->set_argument( 'inclFilter'            , 1                     );
    $req->set_argument( 'max'                   , $params{max_results}  );
    $req->set_argument( 'radius_1'              , $params{max_distance} );
    # Cannot use the $req->add_location method here because it would add the location by id
    $req->set_argument( 'coord'                 , sprintf( "%.6f:%.6f:WGS84", 
            $params{location}->coordinates->longitude,
            $params{location}->coordinates->latitude,
            ) );
    my $doc = $self->_get_doc( request => $req );

    # Move into the itdDepartureMonitorRequest element
    ( $doc ) = $doc->findnodes( 'itdCoordInfoRequest' );
    
    my @locations;
    foreach my $coord_elem( $doc->findnodes( 'itdCoordInfo/coordInfoItemList/coordInfoItem' ) ){
        my $location = $self->location_factory->location_from_coordInfoItem( $coord_elem );
        push( @locations, $location );
    }
    return @locations;
}

=head2 complete_location_from_anything

Give any valid combination from which a Location object may be completed (id, lat/lon, latitude/longitude, or location) and it will return a complete L<WWW::EFA::Location>.

This can be handy in some contexts when you don't have a complete location object...

=head3 Params

=over 4

=item I<id> => $integer

=item I<lat> / I<latitude> => $number

=item I<lon> / I<longitude> => $number

=item I<location> => L<WWW::EFA::Location>

=back

=cut
sub complete_location_from_anything {
    my ( $self, %params ) = validated_hash(
        \@_,
        id          => { isa => 'Int', optional => 1 },
        lat         => { isa => 'Num', optional => 1 },
        lon         => { isa => 'Num', optional => 1 },
        latitude    => { isa => 'Num', optional => 1 },
        longitude   => { isa => 'Num', optional => 1 },
        location    => { isa => 'WWW::EFA::Location', optional => 1 },
      );

    if( $params{lat} ){
        $params{latitude} = $params{lat};
        delete( $params{lat} );
    }
    if( $params{lon} ){
        $params{longitude} = $params{lon};
        delete( $params{lon} );
    }

    if( not $params{location} and $params{id} ){
        $params{location} = $self->get_location( $params{id} );
    }

    # We don't have a location, but hopefully lat/lon
    if( not $params{location}  ){
        # Can't go on if no coords
        if( not $params{longitude} or not $params{latitude} ){
            croak( "Cannot set an origin without latitude, longitude or location!\n" );
        }
        $params{location} = WWW::EFA::Location->new(
            coordinates => WWW::EFA::Coordinates->new(
                latitude    => $params{latitude},
                longitude   => $params{longitude},
                ),
            );
    }

    # We have a rough location, without ID - see if we can make it one with an ID
    if( not $params{location}->id or not $params{location}->coordinates ){
        my @stops = $self->stop_finder(
            location    => $params{location},
        );
        if( scalar( @stops ) < 1 ){
            croak( "No stops found near location:\n" . $params{location}->string );
        }
        $params{location} = $stops[0];
    }
    if( not $params{location}->id ){
        croak( "I still don't have an ID for your location, even after searching for it...\n" );
    }
    return $params{location};
}

# Private method to wrap around:
#  * the http request to the EFA server
#  * parse the XML content
#  * error handling if any of the above fail or are unexpected
# Returns the XML as got from the EFA server
sub _get_xml {
    my ( $self, %params ) = validated_hash(
        \@_,
        request      => { isa => 'WWW::EFA::Request'   },
    );


    my $xml;
    # If the XML source is defined, use it rather than a live request
    my $cache_file = ( $self->cache_dir 
        ? catfile( $self->cache_dir, $params{request}->digest ) 
        : undef );

    if( $cache_file and -f $cache_file ){
        # TODO: RCL 2011-11-20 add debug
        # printf "#RCL reading from: %s\n", $cache_file;
        open( my $fh_in, '<:encoding(ISO-8859-1)', $cache_file ) or die( $! );
        while( my $line = readline( $fh_in ) ){
            $xml .= $line;
        }
        close $fh_in;
    }else{
        # Don't hammer the server - sleep if need be...
        if( $self->sleep_between_requests and $self->last_request_time ){
            my $sleep = $self->sleep_between_requests - ( time() - $self->last_request_time );
            if( $sleep > 0 ){
                sleep( $sleep );
            }
        }
        
        # Use post - it is more robust than GET, and we don't have to encode parameters
        my $result = $self->agent->post( $params{request}->url, $params{request}->arguments );
        $self->last_request_time( time() );
        
        # If response code is not 2xx, something went wrong...
        if( not $result->is_success ){
            croak( "Response from posting request for stop_finder was not a success:\n" . Dump( {
                    URL       => $result->request->uri,
                    Status    => $result->code,
                    Content   => $result->decoded_content,
                    } ) );
        }
        $xml = $result->decoded_content;
        
        if( $cache_file ){
            # TODO: RCL 2011-11-13 Do all operators send in ISO-8859-1 encoding?
            open( my $fh_out, '>:encoding(ISO-8859-1)', $cache_file ) or die( $! );
            print $fh_out $xml;
            close $fh_out;
        }
    }

    return $xml;
}

# Private method to wrap around:
#  * get_xml
#  * make L<XML::LibXML> parser
#  * move to the /itdRequest element in the document
# Returns a L<XML::LibXML> document
sub _get_doc {
    my( $self, %params ) = validated_hash(
        \@_,
        request => { isa => 'WWW::EFA::Request' },
        );
    my $xml = $self->_get_xml( %params );

    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_string( $xml, ) or croak( "Could not read XML" );

    # We always want to be in the itdRequest section
    ( $doc ) = $doc->findnodes( '/itdRequest' );

    return $doc;
}



=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-efa at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-EFA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc WWW::EFA


You can also look for information at:

=over 4

=item * Github - this is my preferred path to receive input on the project!

L<https://github.com/robin13/WWW-EFA>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-EFA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-EFA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-EFA>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-EFA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::EFA

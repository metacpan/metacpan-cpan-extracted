package WWW::PTV;

use warnings;
use strict;

use LWP;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Carp qw(croak);
use WWW::PTV::Area;
use WWW::PTV::Stop;
use WWW::PTV::Route;

our $VERSION = '0.07';
our $CACHE;

sub new {
	my ( $class, %args ) = @_;

	my $self 	= bless {}, $class;
	$self->{uri} 	= 'http://' . ( defined $args{uri} ? $args{uri} : 'ptv.vic.gov.au' ) . '/';
	$self->{ua}	= LWP::UserAgent->new;
	$self->{tree}	= HTML::TreeBuilder->new;
	$self->{cache}++ if $args{cache};

	return $self	
}

sub __request {
	my ( $self, $uri ) = @_;

	my $res = ( $uri !~ /^http:/
		? $self->{ua}->get( $self->{uri} . $uri )
		: $self->{ua}->get( $uri ) );

	$res->is_success and return $res->content;

	croak 'Unable to retrieve content: ' . $res->status_line
}

sub __tl_request {
	my ( $self, $tag_id ) =  @_;

	my $r = ( ( $self->{cache} and $CACHE->{timetables}->{master} )
		? $CACHE->{timetables}->{master}
		: $self->__request( 'http://ptv.vic.gov.au/timetables' )
	);

	$CACHE->{timetables}->{master} = $r if $self->{cache};

	my $t 		= HTML::TreeBuilder->new_from_content( $r );
	$t		= $t->look_down( _tag => 'select', id => $tag_id );
	my @routes	= $t->look_down( _tag => 'option' );

	return my %routes = map { $_->attr( 'value' ) => $_->as_text } grep { $_->attr( 'value' ) ne '' } @routes
}

sub cache { $_[0]->{cache}++ }

sub nocache { $_[0]->{cache} = 0 }

sub get_metropolitan_bus_routes {
	return $_[0]->__tl_request( 'RouteForm1_RouteUrl' );
}

sub get_metropolitan_train_routes {
	return $_[0]->__tl_request( 'RouteForm2_RouteUrl' )
}

sub get_metropolitan_tram_routes {
	return $_[0]->__tl_request( 'RouteForm3_RouteUrl' );
}

sub get_vline_bus_routes {
	return $_[0]->__tl_request( 'RouteForm4_RouteUrl' )
}

sub get_vline_train_routes {
	return $_[0]->__tl_request( 'RouteForm5_RouteUrl' )
}

sub get_regional_bus_routes {
	return $_[0]->__tl_request( 'RouteForm6_RouteUrl' )
}

sub get_route_by_id {
	my ( $self, $id ) = @_;

	$id or return "Mandatory parameter id not given";

	return $CACHE->{ROUTE}->{$id} if ( $self->{cache} and $CACHE->{ROUTE}->{$id} );

	my $r 		= $self->__request( "/route/view/$id" );
	my $t		= HTML::TreeBuilder->new_from_content( $r );
	my %route	= (id => $id);
	my $r_link	= $t->look_down( _tag => 'div', id => 'content' );
	$route{name}	= $t->look_down( _tag => 'h1' )->as_text;

	( $route{direction_in}, $route{direction_out} ) 
			= $r_link->look_down( _tag => 'ul' )->look_down( _tag => "a" );

	( $route{direction_in_link}, $route{direction_out_link} ) 
			= map { $_->attr( 'href' ) } $r_link->look_down( _tag => 'ul' )->look_down( _tag => "a" );

	( $route{direction_in}, $route{direction_out} ) 
			= map { $_->as_text } ( $route{direction_in}, $route{direction_out} );

	( $route{description_in}, $route{description_out} ) 
			= map { $_->as_text } $r_link->look_down( _tag => 'p' );

	my $operator 	= $t->look_down( _tag => 'div', class => 'operator' )->as_text;
	$operator 	=~ s/(Contact|Website|:)/,/g;
	$operator 	=~ s/\s//g;
	( $route{operator} ,$route{operator_ph} ) = ( split /,/, $operator )[0,2];
	$route{ua}	= $self->{ua};
	$route{uri}	= $self->{uri};
	my $route 	= WWW::PTV::Route->new( %route );
	$CACHE->{ROUTE}->{$id} = $route if ( $self->{cache} );

	return $route
}



sub get_stop_by_id {
	my ( $self, $id ) = @_;

	$id or return "Mandatory parameter id not given";

	return $CACHE->{STOP}->{$id} if ( $self->{cache} and $CACHE->{STOP}->{$id} );

	my $r				= $self->__request( "/stop/view/$id" );
	my $t				= HTML::TreeBuilder->new_from_content( $r );
	my %stop			= (id => $id );
	my $s_type 			= $t->look_down( _tag => 'img', class => 'stopModeImage' );
	$stop{address}			= $t->look_down( _tag => 'div', id => 'container' )
						->look_down( _tag => 'p' )
						->as_text;

	$stop{transport_type}		= $s_type->attr('src');
	$stop{transport_type}		=~ s|themes/transport-site/images/jp/icons/icon||;
	$stop{transport_type}		=~ s|\.png||;
	( $stop{street}, $stop{locality} ) = ( split /,/, $stop{address} );
	( $stop{postcode} ) = $stop{locality} =~ /\b(\d{4})\b/;
	$stop{municipiality}		= $t->look_down( _tag	=> 'table', class => 'stationSummary' )
						->look_down( _tag => 'a' )
						->as_text;

	( $stop{municipiality_id} )	= $t->look_down( _tag	=> 'table', class => 'stationSummary' )
						->look_down( _tag => 'a' )
						->attr( 'href' );
	( $stop{municipiality_id} )	= $stop{municipiality_id} =~ /\/(\d.*)$/;

	$stop{zone}			= ( $t->look_down( _tag => 'table', class => 'stationSummary' )
						->look_down( _tag => 'td' )
					  )[2]->as_text;

	$stop{map_ref}			= $t->look_down( _tag => 'div', class => 'aside' )
						->look_down( _tag => 'a' )
						->attr( 'href' );

	( $stop{latitude} )		= $stop{map_ref} =~ /=(-?\d.*),/;

	( $stop{longitude} )		= $stop{map_ref} =~ /,(-?\d.*)$/;

	( $stop{phone_feedback}, $stop{phone_station} ) 
					= map {	$_->as_text } $t->look_down( _tag => 'div', class => 'expander phone-numbers' )
								->look_down( _tag => 'dd' );

	$stop{staff_hours}		= $t->look_down( _tag => 'div', 'data-cookie' => 'stop-staff' )
						->look_down( _tag => 'dd' )->as_text;

	( $stop{myki_machines}, $stop{myki_checks}, $stop{vline_bookings} )
					= map { $_->as_text } $t->look_down( _tag => 'div', 'data-cookie' => 'stop-ticketing' )
								->look_down( _tag => 'dd' );

	( $stop{car_parking}, $stop{_bicycles}, $stop{taxi_rank} )
					= map { $_->as_text } $t->look_down( _tag => 'div', 'data-cookie' => 'stop-other-transport-links' )
								->look_down( _tag => 'dd' );

	( $stop{bicycle_racks}, $stop{bicycle_lockers}, $stop{bicycle_cage} )
					= map { s/.*://; $_ } split /,/, $stop{_bicycles};

	( $stop{wheelchair_accessible}, $stop{stairs}, $stop{escalator}, $stop{lift}, $stop{tactile_paths}, $stop{hearing_loop} )
					= map { $_->as_text } $t->look_down( _tag => 'div', 'data-cookie' => 'stop-accessibility' )
								->look_down( _tag => 'dd' );

	( $stop{seating}, $stop{lighting}, $stop{lockers}, $stop{public_phone}, $stop{public_toilet}, $stop{_waiting_area} )
					= map { $_->as_text } $t->look_down( _tag => 'div', 'data-cookie' => 'stop-general-facilities' )
								->look_down( _tag => 'dd' );

	( $stop{waiting_area_indoor}, $stop{waiting_area_sheltered} )
					= map { s/.*://; $_ } split /,/, $stop{_waiting_area};

	foreach my $line ( $t->look_down( _tag => 'div', 'data-cookie' => 'stop-line-timetables' )
			     ->look_down( _tag => 'div', class => 'timetable-row' ) ) {
		my $ref = { id => $line->look_down( _tag => 'a' )->attr( 'href' ) =~ /^.*\/(.*)/ };
		$ref->{ name } = $line->look_down( _tag => 'a' )->as_text;
		$ref->{ type } = _get_line_type( $line->look_down( _tag => 'img' )->attr( 'src' ) );
		push @{ $stop{routes} }, $ref
	}

	$stop{ua} = $self->{ua};

	my $stop = WWW::PTV::Stop->new( %stop );
	$CACHE->{STOP}->{$id} = $stop if ( $self->{cache} );

	return $stop
}

sub get_area_by_id {
	my ( $self, $id ) = @_;

	$id or return "Mandatory parameter id not given";

	return $CACHE->{AREA}->{$id} if ( $self->{cache} and $CACHE->{AREA}->{$id} );

	my $r				= $self->__request( "/location/view/$id" );
	my $t				= HTML::TreeBuilder->new_from_content( $r );
	my %area 			= ( id => $id );
	$area{name}			= $t->look_down( _tag => 'h1' )->as_text;
	@{ $area{suburbs}}		= split /, /, $t->look_down( _tag => 'p' )->as_text;
	my $t_type;

	foreach my $service ( $t->look_down( _tag => 'div', id => 'content' )->look_down( _tag => 'div' ) ) {
		my $type = $service->look_down( _tag => 'h3' );

		if ( $type->as_text ne '' ) { $t_type = $type->as_text }

		@{ $area{service}{names}{$t_type} } 
			= map { $_->as_text } $service->look_down( _tag => 'li' );

		@{ $area{service}{links}{$t_type} } 
			= map { $_->attr( 'href' ) } $service->look_down( _tag => 'a' );
	}

	my $area =  WWW::PTV::Area->new( %area );
	$CACHE->{AREA}->{$id} = $area if ( $self->{cache} );

	return $area
}

sub get_local_areas {
	my $self = shift;

	my $r = $self->__request( '/getting-around/local-areas/' );
	my $t = HTML::TreeBuilder->new_from_content( $r );
	$t = $t->look_down( _tag => 'div', id => 'content' );

	@{ $self->{local_areas}{names} }
		= map { $_->as_text } $t->look_down( _tag => 'li' );

	@{ $self->{local_areas}{links} }
		= map { $_->attr( 'href' ) } $t->look_down( _tag => 'a' );

	my %res;
	@res{ @{ $self->{local_areas}{names} } } = @{ $self->{local_areas}{links} };

	return %res
}

sub _get_line_type {
	my $obj = shift;

	$obj =~ s/^.*\/icon//;
	$obj =~ s/\..*$//;

	return lc $obj
}

1;

__END__

=head1 NAME

WWW::PTV - Perl interface to Public Transport Victoria (PTV) Website.

=head1 SYNOPSIS

    use WWW::PTV;

    my $ptv = WWW::PTV->new( cache => 1 );

    # Return a WWW::PTV::Route object for route ID 1
    my $route = $ptv->get_route_by_id(1);

    # Print the route name and outbound description
    print $route->name .":". $route->description ."\n";

    # Get the route outbound timetable as a WWW::PTV::TimeTable object
    my $tt = $route->get_outbound_tt;

    # Get the route stop names and IDs as a hash in the inbound direction
    my %stops = $route->get_stop_names_and_ids( 'in' );
    
=head1 METHODS

=head2 new ( cache => BOOLEAN )

Constructor method - creates a new WWW::PTV object.  This method accepts an
optional hashref specifying a single valid parameter; I<cache>, which if
set to a true value will enable internal object caching.

The default behaviour is not to implement any caching, however it is strongly
recommended that you enable caching in most implementations.  Caching will
dramatically improve the performance of repeated method invocations and
reduce network utilisation, but will increase memory requirements.

You may also selectively enable or disable the cache after invoking the
constructor via the B<cache> and B<nocache> methods.

See the L<CACHING> section for more information.

=head2 cache

Enables internal object caching.  See the L<CACHING> section for more details.

=head2 nocache

Enables internal object caching.  See the L<CACHING> section for more details.

=head2 get_metropolitan_bus_routes

Returns a hash containing all metropolitan bus routes indexed by the bus route ID.

B<Please note> that the bus route ID is not the same as the bus route ID that may be
used to identify the service by the service operator - the ID used in this module refers
to the unique ID assigned to the route within the context of the PTV website.

	my %routes = $ptv->get_metropolitan_bus_routes;
	map { printf( "%-6s: %-50s\n", $_, $routes{ $_ } } sort keys %routes;

	# Prints a list of all metropolitan bus route IDs and names. e.g.
	# 1000  : 814 - Springvale South - Dandenong via Waverley Gardens Shopping Centre, Springvale
	# 1001  : 815 - Dandenong - Noble Park                      
	# 1003  : 821 - Southland - Clayton via Heatherton 
	# ... etc.

=head2 get_regional_bus_routes

Returns a hash containing all regional bus routes indexed by the bus route ID.

B<Please note> that the bus route ID is the PTV designated ID for the route and not
the service operator ID.

	my %routes = $ptv->get_regional_bus_routes;

	while (( $id, $desc ) = each %routes ) {
		print "$id : $desc\n" if ( $desc =~ /Echuca/ )
	}

	# Prints a list of regional bus routes containing 'Echuca' in the route name - e.g.
	# 1346 : Echuca - Moama (Route 3 - Circular)
	# 1345 : Echuca - Echuca East (Route 2 - Circular)
	# 6649 : Kerang - Echuca via Cohuna (Effective from 18/11/2012)
	# ... etc.

=head2 get_metropolitan_tram_routes

Returns a hash containing all metropolitan tram routes indexed by the route ID.

B<Please note> as per the method above, the route ID is the PTV designated route
and not the service operator ID.

=head2 get_metropolitan_train_routes

Returns a hash containing all metropolitan train routes indexed by the route ID.

B<Please note> as per the method above, the route ID is the PTV designated route
and not the service operator ID.

=head3 get_vline_bus_routes

Returns a hash containing all V/Line bus routes indexed by the route ID.

B<Please note> as per the method above, the route ID is the PTV designated route
and not the service operator ID.

=head3 get_vline_train_routes

Returns a hash containing all V/Line train routes indexed by the route ID.

B<Please note> as per the method above, the route ID is the PTV designated route
and not the service operator ID.

=head2 get_route_by_id

	my $route = $ptv->get_route_by_id( 1 );

	print $route->direction_out."\n".$route_description."\n";
	# Prints the outbound route direction ("To Alamein") and a 
	# description of the outbound route

Returns a L<WWW::PTV::Route> object for the given route ID representing a transit route.

B<Note that> the route ID is not the service operator route ID, but is the PTV route
ID as obtained from one of the other methods in this class.

See the L<WWW::PTV::Route> page for more detail.

=head3 get_stop_by_id ( $ID )

Returns the stop identified by the numerical parameter $ID as a L<WWW::PTV::Stop>
object.  The numerical identifier of a stop is unique.

=head3 get_local_areas

Returns a hash containing the defined "local areas" and a URI to the local area web page.
The hash is indexed by the local area name.

=head3 get_area_by_id ( $ID ) 

Returns the area identified by the numerical parameter $ID as a L<WWW::PTV::Area> object.

=head1 CACHING

It is strongly recommended that you enable caching in the constructor invocation 
using the optional I<cache> argument.  Caching is not enabled by default to 
align with the principle of least surprise, however it is most likely that you 
will want to enable it to improve the performance of your program and to reduce 
the number ofrequests to the PTV website.

If you do not enable caching, then you may wish to consider storing any 
retrieved objects locally (e.g. in a database), or attempting to limit the 
frequency, or number, of methods invocations.

Note that you can also disable the cache for selective method invocations by
invoking the B<no_cache> method prior to method invocation, and then re-enable
the cache (which will also restore the content of the cache prior to the 
invocation of the nocache method) with the B<cache> method.

	# Disable cache
	$ptv->nocache;

	$ptv->get_stop_by_id( $id );

	# Re-enable cache
	$ptv->cache;


=head1 SEE ALSO

L<WWW::PTV::Area>
L<WWW::PTV::Route>
L<WWW::PTV::Stop>
L<WWW::PTV::TimeTable>
L<WWW::PTV::TimeTable::Schedule>

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ptv at rt.cpan.org>, or 
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PTV>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PTV


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PTV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PTV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PTV>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PTV/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

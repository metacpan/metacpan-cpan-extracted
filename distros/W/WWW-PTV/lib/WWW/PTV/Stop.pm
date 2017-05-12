package WWW::PTV::Stop;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(		
address 
bicycle_cage 
bicycle_lockers 
bicycle_racks 
car_parking 
escalator 
hearing_loop 
id 
latitude 
lift 
lighting 
lines 
locality 
lockers 
longitude 
map_ref 
municipiality 
municipiality_id 
myki_checks 
myki_machines 
phone_feedback 
phone_station 
postcode 
public_phone 
public_toilet 
routes 
seating 
staff_hours 
stairs 
street 
tactile_paths 
taxi_rank 
transport_type 
vline_bookings 
waiting_area_indoor 
waiting_area_sheltered 
wheelchair_accessible 
zone 
);

foreach my $attr ( @ATTR ) {
	no strict 'refs';

	*{ __PACKAGE__ .'::'. $attr } = sub {
		my( $self, $val ) = @_;
		$self->{$attr} = $val if $val;
		return $self->{$attr}
	}
}

sub new {
	my( $class, %args ) = @_;

	my $self = bless {}, $class;
	$args{ id } 
		or croak 'Constructor failed: mandatory id argument not supplied';

	foreach my $attr ( @ATTR ) { 
		$self->{$attr} = $args{$attr} 
	}

	return $self
}

sub get_route_names {
	map { $_->{name} } @{ $_[0]->{routes} }
}

sub get_route_ids {
	map { $_->{id} } @{ $_[0]->{routes} }
}

sub get_routes {
	my $self = shift;

	return wantarray 
		? @{ $self->{routes} }
		: $self->{routes}
}

1;

__END__

=pod

=head1 NAME

WWW::PTV::Stop - Class for operations with Public Transport Victoria (PTV) stops

=cut

=head1 SYNOPSIS

	# Get a WWW::PTV::Stop object representative of stop ID 30801
	my $stop = $ptv->get_stop_by_id(30801);

	# Print the stop address, type and map reference.
	print "Stop: " . $stop->address . " - Type: " .
	$stop->type . " - Map: " . $stop->map_ref . "\n";

=head1 METHODS

=head3 address

Returns the stop address as a freeform text value.

=head3 bicycle_cage 

Returns a value indicating if the stop has bicycle cage facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 bicycle_lockers

Returns a value indicating if the stop has bicycle locker facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 bicycle_racks 

Returns a value indicating if the stop has bicycle rack facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 car_parking 

Returns a value indicating if the stop has car parking rack facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 escalator 

Returns a value indicating if the stop has escalator facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 hearing_loop 

Returns a value indicating if the stop has hearing loop facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 id 

Returns the numerical ID of the stop.

=head3 latitude

Returns the latitude of the stop as a floating point value.

=head3 lift

Returns a value indicating if the stop has lift facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 lighting 

Returns a value indicating if the stop has lighting facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 lines 

Returns a value indicating if the stop has lines - this 
typically has a value of either 'Yes' or 'No'.

=head3 locality 

Returns the stop locality typically in the format of a locality or
suburb name, and postpode. e.g. "Belmont 3216".

=head3 lockers 

Returns a value indicating if the stop has lines - this 
typically has a value of either 'Yes' or 'No'.

=head3 longitude 

Returns the latitude of the stop as a floating point value.

=head3 map_ref 

Returns a Google Maps URL for the stop location.

=head3 municipiality 

Returns the municipiality of which the stop is located in as free-form
text.  e.g. "Greater Geelong".

=head3 municipiality_id

Returns the numerical identifier of the stop municipiality.

=head3 myki_checks 

Returns a value indicating if the stop has Myki check facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 myki_machines 

Returns a value indicating if the stop has Myki machine facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 phone_feedback 

Returns a value indicating if the stop has phone feedback facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 phone_station 

Returns the stop phone number (if any).

=head3 postcode

Returns the postcode in which the stop is located.

=head3 public_phone 

Returns a value indicating if the stop has public phone facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 public_toilet 

Returns a value indicating if the stop has public toilet facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 get_routes

Returns the routes servicing this stop as an array of hashes, where each
hash contains three key/value pairs;

=over 4

=item *

id - the route numerical identifier.

=item *

name - a descriptive name of the route.

=item *

type - the type of transport (e.g. bus, train).

=back

=head3 get_route_ids

Returns an array containing the route IDs that service this stop.

Please note that these route IDs are the PTV defined route IDs and
not the collaquial IDs that may be assigned to the service.
e.g. "The number 19 bus".

=head3 get_route_names

Returns an array containing the route names that service this stop.

These names often contain teh collaquial route ID of the service in
a free text format. 
e.g. "235 - City - Fishermans Bend via Lorimer Street".

=head3 seating 

Returns a value indicating if the stop has seating facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 staff_hours 

Returns the staffing hours for the selected stop - note that this is free-form
text that may make use of symbolic or shorthand notation - e.g. 'N'.

=head3 stairs

Returns a value indicating if the stop has stairs - this 
typically has a value of either 'Yes' or 'No'.

=head3 street

Returns the street on which the stop is located.

=head3 tactile_paths 

Returns a value indicating if the stop has tactile paths - this 
typically has a value of either 'Yes' or 'No'.

=head3 taxi_rank 

Returns a value indicating if the stop has taxi rank facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 transport_type

Returns the stop transport type - e.g. "bus", "train", etc.

=head3 vline_bookings

Returns a value indicating if the stop has VLine booking facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 waiting_area_indoor 

Returns a value indicating if the stop has an indoor waiting area - this
typically has a value of either 'Yes' or 'No'.

=head3 waiting_area_sheltered 

Returns a value indicating if the stop has sheltered indoor waiting area
- this typically has a value of either 'Yes' or 'No'.

=head3 wheelchair_accessible 

Returns a value indicating if the stop has wheelchair facilities - this 
typically has a value of either 'Yes' or 'No'.

=head3 zone

Returns the stop zone (per the PTV zoning system) as a comma-seperated 
zone name and zone numerical identifier - e.g. "Regional, 4".

=head1 SEE ALSO

L<WWW::PTV>, L<WWW::PTV::Area>, L<WWW::PTV::Route>, L<WWW::PTV::TimeTable>,
L<WWW::PTV::TimeTable::Schedule>.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ptv-stop at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PTV-Stop>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PTV::Stop


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PTV-Stop>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PTV-Stop>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PTV-Stop>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PTV-Stop/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

package WWW::PTV::Area;

use strict;
use warnings;

sub new {
	my ( $class, %args ) = @_;

	my $self	 = bless {}, $class;
	$self->{id}	 = $args{id};
	$self->{name}	 = $args{name};
	$self->{suburbs} = $args{suburbs};
	$self->{service} = $args{service};

	return $self
}

sub id {
	return $_[0]->{ id }
}

sub name {
	return $_[0]->{ name }
}

sub suburbs {
	return $_[0]->{ suburbs }
}

sub towns {
	$_[0]->suburbs
}

sub service_types {
	return keys %{ $_[0]->{ service }{ names } }
}

sub service_names {
	return $_[0]->{ service }{ names }
}

sub service_links {
	return $_[0]->{ service }{ links }
}

sub services {
	my $self = shift;

	my @res;
	my $service_names = $self->service_names;
	my $service_links = $self->service_links;

	# { name => 'Name', link => 'link', type => 'Type' }
	foreach my $type ( $self->service_types ) {
		my $c = 0;
		my $r;

		foreach my $service ( @{ $service_names->{$type} } ) {
			my $r = { type => $type,
				  name => @{ $service_names->{ $type } }[ $c ],
				  link => @{ $service_links->{ $type } }[ $c ] };
			push @res, $r;
			$c++;
		}
	}

	return @res;
}

sub services_like {
	my ( $self, %args ) = @_;

	$args{type} or return grep { $_->{name} =~ /$args{name}/i } $self->services;

	$args{name} or return grep { $_->{type} =~ /$args{type}/i } $self->services;

	return grep {  	  
			$_->{type} =~ /$args{type}/i
			and $_->{name} =~ /$args{name}/i
	       } $self->services
}

1;

__END__

=pod

=head1 NAME WWW::PTV::Area - a utility class for working with Public Transport Victoria (PTV) areas.

=head1 SYNOPSIS

	my $ptv = WWW::PTV->new;
	my $area = $ptv->get_area_by_id(30);

	print "\n\nThe ". $area->name ." area encapsulates the following suburbs and towns:\n - ";
	print join "\n - ", @{ $area->suburbs };

	print "\n\nServices in this area include:\n";
	my @service_types = $area->service_types;
	my $service_names = $area->service_names;
	my $service_links = $area->service_links;

	foreach my $type ( @service_types ) {
		print "\n - $type\n";

		foreach my $name ( @{ $service_names->{ $type } } ) {
			print "\t\t - $name\n"
		}
	}

=head1 METHODS

=head3 id ()

Returns the area numerical identifier.

=head3 name ()

Returns the area name.

=head3 suburbs ()

Returns a list of the suburbs and towns encompassed by this area - the suburb
and town names are typically free-form text and are common names for suburbs 
or towns e.g. Carlton, South Wharf, Echuca, etc.

=head3 towns ()

This method is a synonym for the B<suburbs()> method.

=head3 service_types ()

Returns a list of the service types operating within this area - the service
names are free-form text describing the service e.g. Train Stations, 
Metropolitan Trams, etc.

=head3 service_names ()

Returns a hash containing the service names servicing the area as lists 
indexed by the service type;

	'Metropolitan Trains' => [
				  'Alamein Line',
				  'Belgrave Line',
				  'Craigieburn Line',
				  ...
				 ],
	'Metropolitan Trams' => [
				 '200 - Bulleen',
				 ...
				],
	...

=head3 service_links ()

Returns a hash containing URLs for the routes and stops servicing the area -
these lists positionally correspond to the items in the lists returned for
service names as returned by the B<service_names()> method.

	'Metropolitan Trains' => [
				  'http://ptv.vic.gov.au/route/view/1', # Alamein Line
				  'http://ptv.vic.gov.au/route/view/2', # Belgrave Line
				  'http://ptv.vic.gov.au/route/view/3', # Craigieburn Line
				  ...
				 ],
	'Metropolitan Trams' => [
				 'http://ptv.vic.gov.au/route/view/7520', # Route 200 - Bulleen
				 ...
				],
	...

So with minimal effort, it is possible to reliably retrieve the route name and
route URL by doing something like;

	print "<a href=\"@{ $service_links->{'Metropolitan Trains'} }[0]\">"
	    . "@{ $service_names->{'Metropolitan Trains'} }[0]</a>\n";

=head3 services

Returns all services for the area as a list of anonymous hashes having the 
structure:

	{ 
	  name => 'Service Name',
	  type => 'Service Type',
	  link => 'URI to service link'
	}

=head3 services_like ( { name => $name, type => $type } )

Returns a list of anonymous hashes having the structure described in the 
B<services> method above matching the search criteria defined by %args.

The two valid search criteria accepted are I<name> and I<type>, and any 
services matching these criteria will be returned.  If both criteria are
provided, then only services matching both criteria are returned.

	# Return only services having a description like "University"
	my @services = $area->services_like( name => 'university' );

	# Return only services having a description like "University"
	# and being of a 'bus' service type.
	my @services = $area->services_like( name => 'university',
					     type => 'bus' );

Note that matching is case-insensitive.

=head1 SEE ALSO

L<WWW::PTV>, L<WWW::PTV::Route>, L<WWW::PTV::Stop>, L<WWW::PTV::TimeTable>, 
L<WWW::PTV::TimeTable::Schedule>

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ptv-area at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PTV-Area>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PTV::Area


    You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PTV-Area>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PTV-Area>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PTV-Area>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PTV-Area/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

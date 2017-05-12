package WWW::PTV::TimeTable;

use strict;
use warnings;

use WWW::PTV::TimeTable::Schedule;
use Carp qw(croak);

our @ATTR = qw( route_id direction direction_desc name );

sub new {
	my ( $class, $stop_names, $stop_ids, $stop_times ) = @_;

	my $self		= bless {}, $class;
	$self->{stop_names} 	= $stop_names;
	$self->{stop_ids}	= $stop_ids;
	$self->{stop_times}	= $stop_times;
	@{ $self->{map} }{ @{ $self->{stop_ids} } } = @{ $self->{stop_times} };

	return $self
}

sub stop_ids {
	return @{ $_[0]->{stop_ids} }
}

sub stop_names {
	return @{ $_[0]->{stop_names} }
}

sub stop_names_and_ids {
	my ( $self, $type ) = @_;

	$type ||= 'array';
	$type = 'array' unless $type =~ /^(array|hash)$/;
	my @n = @{ $self->{stop_names} };
	my @i = @{ $self->{stop_ids} };
	my $c = 0;

	return map { [ $_, $n[$c++] ] } @i
}

sub get_schedule_by_stop_id {
	defined $_[0]->{map}{$_[1]} 
		and return WWW::PTV::TimeTable::Schedule->new( $_[0]->{map}{$_[1]} )
}

sub get_schedule_by_stop_name {
	my ( $self, $stop ) = @_;

	my $c = 0;
	# This is really ugly - but we need to use the index of the matching
	# stop name as a hash key to retrieve the stop times from the map
	map { /$stop/i and return 
		WWW::PTV::TimeTable::Schedule->new(
			$self->{map}{ @{ $self->{stop_ids} }[$c]}
		);
		$c++ 
	} @{ $self->{stop_names} };
}

sub pretty_print {
	my $self= shift;

	my @t	= localtime(time);
	my @d	= qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday 
		     Sunday);
	my @m	= qw(January February March April May June July August September 
		     October November December);
	printf("Current local time and date is: %s %s %s %02d:%02d %s\n",
		$d[$t[6]], $t[3], $m[$t[4]], $t[2], $t[1], ($t[5]+1900));
	my $c = 0;

	foreach my $s ( @{ $self->{stop_times} } ) {
		printf( "| %-50s |", @{ $self->{stop_names} }[$c] );

		map { 
			printf( "%5s|", $_ ) 
		} @{ @{ $self->{ stop_times } }[ $c ] };

		print "\n+";
		my $l = ( 54 + ( 7 * scalar @{ @{ $self->{stop_times} }[$c] } ) ) - 2;
		print "-"x$l;
		print "+\n";
		$c++;
	}
}

1;

__END__

=head1 NAME

WWW::PTV::TimeTable - Class for operations with PTV timetables.

=head1 SYNOPSIS

	use WWW::PTV;
	my $ptv = WWW::PTV->new;
	
	# Get the next outbound departure time for route 1 from stop ID 19849
	my $next = $ptv->get_route_by_id(1)
		       ->get_outbound_tt;
	
	print "The next service is scheduled at @$next\n";
	
	# Get the next five services for route 1 from the same stop.
	my $next = $ptv->get_route_by_id(1)
		       ->get_outbound_tt
		       ->get_schedule_by_stop_id(19849)
		       ->next_five;

=head1 DESCRIPTION

This module implements a utility class providing operations for PTV timetables.

Please note the terminology used for the naming of this module should not imply
relationships between routes, timetables, schedules and other objects.  In brief, 
the relationships between objects defined in the WWW::PTV namespace are:

	       1       *
	route --- has ---> timetables

	           1       *
	timetable --- has ---> schedules

	          1       *
	schedule --- has ---> stops (service times)

That is to say; a route may have one or more timetables (inbound, outbound,
weekend, public holiday, etc.), each of which is composed of one or more
schedules where a schedules is defined as the list of service times for a 
particular stop on that route.

=head2 METHODS

=head3 stop_ids ()

	my @stop_ids = $timetable->stop_ids;
	print "Stops on this route: " . join ", ", @stop_ids . "\n";

Returns a list of in order stop IDs for this route in the selected direction.

=head3 stop_names ()

Returns a list of in order stop IDs for this route in the selected direction.
	
	print "This service will be stopping at : " 
		. join ", ", $timetable->stop_names . "\n";

=head3 stop_names_and_ids ()

Returns a list of lists with each sublist containing the stop ID as the first 
element, and the station name as the second providing an in-order mapping
of stop IDs and names.

=head3 get_schedule_by_stop_id ( $ID )

	# Print a nicely formatted list of service times for
	# the outbound direction of route 1 for stop ID 19849

	$ptv->get_route_by_id( 1 )
		->get_outbound_tt
		->get_schedule_by_stop_id( 19849 )
		->pretty_print;

=head3 get_schedule_by_stop_name ( $NAME )

	# Get a list of service times for route 1 in the
	# outbound direction for the first station having 
	# a name matching /wood/i (this will be stop ID 
	# 19849 - 'Burwood').
	
	$ptv->get_route_by_id( 1 )
		->get_outbound_tt
		->get_schedule_by_stop_name( 'burwood' )
		->as_list;

=head3 pretty_print ()

Prints a formatted version of the complete timetable.
Note that for timetables with a large number of service
times, this method will produce B<very> wide output that
may not be viewable even on large screens.

=head1 SEE ALSO

L<WWW::PTV>, L<WWW::PTV::Area>, L<WWW::PTV::Route>, L<WWW::PTV::Stop>,
L<WWW::PTV::TimeTable::Schedule>.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ptv-timetable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PTV-TimeTable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PTV::TimeTable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PTV-TimeTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PTV-TimeTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PTV-TimeTable>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PTV-TimeTable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

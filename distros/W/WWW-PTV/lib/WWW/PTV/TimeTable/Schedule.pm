package WWW::PTV::TimeTable::Schedule;

use strict;
use warnings;

our $VERSION = '0.06';

sub new {
	my ($class, $schedule) = @_;
	my $self = bless {}, $class;
	$self->{schedule} = $schedule;
	return $self
}

sub as_list {
	return @{ $_[0]->{schedule} };
}

sub next {
	my ($self, $n, $i) = @_;
	$n ||= 1;
	$i ||= 0;
	my(@res,$c,$l);
	my($h,$m) = (localtime(time))[2,1];

	foreach my $t ( @{ $self->{schedule} } ) {
		$l++;
		my($nh,$nm) = split /:/, $t;
		$nm and $nh ne '-' or next;

		if( ($nh > $h) ||
		    ($nh >= $h && $nm >= $m) ) {
			push @res, [$nh,$nm];

			if( $i == 7 ) {
				return $l-1
			}
			if( ++$c == $n ) {
				return ( ~~@res == 1 
					? $res[0]
					: \@res )
			}
		}
	}

	return ( @res ? \@res : 0 )
}

sub index_of_next {
	return $_[0]->next(1,7)
}

sub next_five {
	return $_[0]->next(5)
}

sub pretty_print {
	my $self= shift;
	my @t	= localtime(time);
	my $i	= $self->index_of_next;
	my @s	= $self->as_list;
	my $n	= $s[$i];
	my @d	= qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday 
		     Sunday);
	my @m	= qw(January February March April May June July August September 
		     October November December);
	printf("Current local time and date is: %s %s %s %02d:%02d %s\n",
		$d[$t[6]], $t[3], $m[$t[4]], $t[2], $t[1], ($t[5]+1900));
	@s	= map { sprintf("| %-6s |\n", $_ ) } @s;
	$s[$i]	= "===== Next service =====\n"
		. "        $n\n"
		. "========================\n";
	@s	= grep { /:/ } @s;
	push @s, ""; unshift @s, "";
	print join "+--------+\n", @s;
}

1;

__END__

=head1 NAME

WWW::PTV::TimeTable::Schedule - Class for operations with PTV time table schedules.

=head1 SYNOPSIS

	use WWW::PTV;
	my $ptv = WWW::PTV->new;
	
	# Get the next outbound departure time for route 1 from stop ID 19849
	my $next = $ptv->get_route_by_id(1)
		       ->get_outbound_tt
		       ->get_schedule_by_stop_id(19849)
		       ->next;
	
	print "The next service is scheduled at @$next\n";
	
	# Get the next five services for route 1 from the same stop.
	my $next = $ptv->get_route_by_id(1)
		       ->get_outbound_tt
		       ->get_schedule_by_stop_id(19849)
		       ->next_five;

=head1 DESCRIPTION

This module implements a utility class providing operations for PTV timetable 
schedules.

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

=head3 next ( $INT )

	my $next = $schedule->next;
	print "The next service arrives at $$next[0]:$$next[1]\n";
	# The next service arrives at 18:10

Returns the next chronological service time on the schedule in respect to
the current local time as a list of two values corresponding to the hour
and minute respectively.

This method accepts an integer value as an optional parameter which, if passed
specifies the number of the next n service times to return.

	# Return the next three service times
	my @next_three_trains = $timetable->next(3);

=head3 next_five ()

Returns the chronological next five service times for the schedule
emulating the popular "next five" feature on the PTV website.

The service times are returned as a list of lists of hour, minute
values.  See B<next> for more information.

=head3 index_of_next ()

Returns an integer value which corresponds to the index of the next service
in the array returned by the B<as_list()> method.

	# e.g. The service that I just missed was
	my $previous = ($schedule)->[$schedule->index_of_next - 1];

Note that the invocation in the example above may not return a service
time, but could return a sequence of characters indicating special
service states.

=head3 as_list ()

Returns the complete schedule as an ordered list.  Note that schedule times
may not conform to a standard format (e.g. hh:mm) and may use ASCII or Unicode
characters to indicate special values.

=head3 pretty_print ()

Prints the current date and time and a nicely formatted schedule with the
next service time clearly highlighted.

=head1 SEE ALSO

L<WWW::PTV>, L<WWW::PTV::Area>, L<WWW::PTV::Route>, L<WWW::PTV::Stop>,
L<WWW::PTV::TimeTable>.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ptv-timetable-schedule at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PTV-TimeTable-Schedule>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PTV::TimeTable::Schedule


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PTV-TimeTable-Schedule>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PTV-TimeTable-Schedule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PTV-TimeTable-Schedule>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PTV-TimeTable-Schedule/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

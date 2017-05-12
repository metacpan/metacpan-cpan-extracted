package WWW::PIDS::ScheduledTime;

use strict;
use warnings;

our @ATTR = qw(AirConditioned Destination DisplayAC HasDisruption HasSpecialEvent HeadboardRouteNo InternalRouteNo 
	IsLowFloorTram IsTTAvailable PredictedArrivalDateTime RequestDateTime RouteNo SpecialEventMessage VehicleNo);

{
	no strict 'refs';

	*$_ = sub { shift->{ $_ } } for ( @ATTR );
}

sub new {
	my ( $class, $obj )	= @_;
	my $self		= bless {}, $class;

	for my $a ( @ATTR ) { 
		defined $obj->{ $a } 
			? $self->{ $a } = $obj->{ $a }
			: die "Mandatory parameter $a not supplied in constructor" ;
	}	

	return $self
}

1;

__END__

=head1 NAME 

WWW::PIDS::ScheduledTime - Utility class for representing tramTRACKER PIDS 
scheduled time objects.

=head1 DESCRIPTION

WWW::PIDS::ScheduledTime is a utility class for representing tramTRACKER 
PIDS time objects.

WWW::PIDS::ScheduledTime objects are returned by invocation of the
I<GetNextPredictedRoutesCollection()> method in the L<WWW::PIDS> module.

=head1 METHODS

=head2 AirConditioned

Returns a boolean value ('true' or 'false') indicating if the service is
air-conditioned.

=head2 Destination

Returns a string containing the service destination. e.g. 'Moreland' or
'East Coburg'.

=head2 DisplayAC

Returns a boolean value ('true' or 'false') indicating if the air-conditioned
status is displayed.

=head2 HasDisruption

Returns a boolean value ('true' or 'false') indicating if the service is
currently reporting a disruption.

=head2 HasSpecialEvent

Returns a boolean value ('true' or 'false') indicating if the service is
currently running for a special event.

=head2 HeadboardRouteNo

Returns the service head-board displayed route number.

=head2 InternalRouteNo

Returns the service internal route number.

=head2 IsLowFloorTram

Returns a boolean value ('true' or 'false') indicating if the service is
a low-floor tram.

=head2 IsTTAvailable

Returns a boolean value ('true' or 'false') indicating if time-tabling
information is available for the service.

=head2 PredictedArrivalDateTime

Returns the predicated arrival timestamp of the service using the format:

	YYYY-MM-DDThh:mm:ss+TZhh:TZmm

=head2 RequestDateTime

Returns a timestamp at which the request was issued in the format:

	YYYY-MM-DDThh:mm:ss+TZhh:TZss

=head2 RouteNo

Returns the service route number.

=head2 SpecialEventMessage

Returns the special event message.

=head2 VehicleNo

Returns the vehicle number of tram.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pids at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PIDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PIDS

You can also look for information at:

=over 4

=item * tramTRACKER PIDS Web Service 

L<http://ws.tramtracker.com.au/pidsservice/pids.asmx>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PIDS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PIDS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PIDS>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PIDS/>

=back

=head1 SEE ALSO

L<WWW::PIDS>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

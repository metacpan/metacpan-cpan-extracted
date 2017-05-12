package WWW::PIDS::PredictedTime;

use strict;
use warnings;

use WWW::PIDS::ScheduledTime;

our @ATTR	= qw(TripID PredictionType);
our @OATTR	= qw(Deviation);

{
	no strict 'refs';
	*$_ = sub { shift->{ $_ } } for ( @ATTR, @OATTR );
}

sub new {
	my ( $class, $obj )	= @_;
	my $self		= WWW::PIDS::ScheduledTime->new( $obj ); 
	bless $self, $class;

	for my $a ( @ATTR ) { 
		defined $obj->{ $a }
			? $self->{ $a } = $obj->{ $a }
			: die "Mandatory parameter $a not supplied in constructor" ;
	}

	for ( @OATTR ) {
		$self->{ $_ } = ( defined $obj->{ $_ } ? $obj->{ $_ } : '' )
	}

	return $self
}

1;

__END__

=head1 NAME 

WWW::PIDS::PredictedTime - Utility class for representing predicted arrival times
for the PIDS tramTRACKER service.

=head1 DESCRIPTION

WWW::PIDS::PredictedTime is a utility class for representing predicted arrival 
times for the PIDS tramTRACKER service.

=head1 METHODS

=head2 AirConditioned

Returns a boolean value ('true' or 'false') indicating if the service is 
air-conditioned.

=head2 Destination

Returns the end of line destination for the service as a human-readable 
location. e.g. 'East Coburg' or 'Moreland'.

=head2 Deviation

Returns a value indicating the time deviation of the predicated arrival time
from the scheduled arrival time.

=head2 DisplayAC

Returns a boolean value ('true' or 'false') indicating if the service displays
air-conditioned status.

=head2 HasDisruption

Returns a boolean value ('true' or 'false') indicating if the service has a
disruption.

=head2 HasSpecialEvent

Returns a boolean value ('true' or 'false') indicating if the service is 
scheduled for a special event.

=head2 HeadboardRouteNo

Returns the headboard route number.

=head2 InternalRouteNo

Returns the internal route number.

=head2 IsLowFloorTram

Returns a boolean value ('true' or 'false') indicating if the service is a low-
floor service.

=head2 IsTTAvailable

Returns a boolean value ('true' or 'false') indicating if the service has time-
table information available.

=head2 PredictedArrivalDateTime

Returns the predicted arrival timestamp of the service in the format:

	YYYY-MM-DDThh:mm:ss+TZhh:TZmm

=head2 PredictionType

returns the predicted arrival time type.

=head2 RequestDateTime

Returns the client-provided timestamp for the request (i.e. the value of the
I<clientRequestDateTime> parameter in the invocating method) using the format:

	YYYY-MM-DDThh:mm:ss+TZhh:TZmm
	
=head2 RouteNo

Returns the route number of the service.

=head2 SpecialEventMessage

Returns the special event message.

=head2 TripID

Returns the tramTRACKER trip ID.

=head2 VehicleNo

Returns the service vehicle number.

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

L<WWW::PIDS::ScheduledTime>

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

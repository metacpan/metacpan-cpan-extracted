package WWW::PIDS::TramNoRunDetail;

use strict;
use warnings;

our @ATTR = qw(AtLayover Available HasDisruption HasSpecialEvent HeadBoardRouteNo Up VehicleNo RouteNo);

{
	no strict 'refs';
	*$_ = sub { return shift->{ $_ } } for @ATTR;
}

sub new {
	my ( $class, $obj ) = @_;
	my $self = bless {}, $class;
	for my $a ( @ATTR ) {
		defined $obj->{ $a} 
			? $self->{ $a } = $obj->{ $a }
			: die "Mandatory parameter $a not supplied in constructor" ;
	}

	return $self
}

1;

__END__

=head1 NAME 

WWW::PIDS::TramNoRunDetail - Utility class for representing tram service run
details.

=head1 DESCRIPTION

WWW::PIDS::TRAMNoRunDetail is a utility class for representing tram service
run details as returned by invocation of the I<TramNoRunDetailsTable()>
method in the L<WWW::PIDS::PredictedArrivalTimeData> module.

=head1 METHODS

=head2 AtLayover

Returns a boolean ('true' or 'false') indicating if the service is at a layover.

=head2 Available

Returns a boolean ('true' or 'false') indicating if the service is available.

=head2 HasDisruption

Returns a boolean ('true' or 'false') indicating if the service is reporting a
disruption.

=head2 HasSpecialEvent

Returns a boolean ('true' or 'false') indicating if the service has a special 
event.

=head2 HeadBoardRouteNo

returns the headboard route number.

=head2 RouteNo

Returns the service route number.

=head2 Up

Returns a boolean ('true' or 'false') indicating if the service is travveling
in the up direction.

=head2 VehicleNo

Returns the tram vehicle number.

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

L<WWW::PIDS::PredictedArrivalTimeData>

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

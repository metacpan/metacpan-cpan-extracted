package WWW::PIDS::NextPredictedStopsDetailTable;

use strict;
use warnings;

sub new {
	my ( $class, @stops ) = @_;
	my $self = bless {}, $class;
	@{ $self->{ stops } } = @stops;

	return $self
}

sub stops {
	return @{ $_[0]->{ stops } }
}

sub first {
	return @{ $_[0]->{ stops } }[0]
}

sub last {
	return @{ $_[0]->{ stops } }[-1]
}

sub count {
	return scalar @{ $_[0]->{ stops } }
}

1;

__END__

=head1 NAME 

WWW::PIDS::NextPredictedStopsDetailTable - Utility class for representing next
next predicted stops detail collections.

=head1 DESCRIPTION

WWW::PIDS::NextPredictedStopsDetailTable is a utility class for representing
colelctions of next predicted stop information such as those returned as a 
component of a L<WWW::PIDS::PredictedArrivalTimeData> object via an
invocation of the I<GetNextPredictedArrivalTimeAtStopsForTramNo> method in the 
L<WWW::PIDS> module.

Note that a B<WWW::PIDS::NextPredictedStopsDetailTable> object is little more
than an in-order of L<WWW::PIDS::NextPredictedStopDetail> objects.

An B<WWW::PIDS::NextPredictedStopsDetailTable> object is usually contained 
within a L<WWW::PIDS::PredictedArrivalTimeData> object where it is accessible
via invocation of the I<NextPredictedStopsDetailsTable> method in that module.

=head1 METHODS

=head2 stops

Returns all predicted stops as an in-order list of 
L<WWW::PIDS::NextPredictedStopDetail> objects.  The order of the stop represents
the in-order transit of the stops by the service.

=head2 count

Returns the number of L<WWW::PIDS::NextPredictedStopDetail> objects in the table.

=head2 first

Returns the first L<WWW::PIDS::NextPredictedStopDetail> from the table.

=head2 last

Returns the last L<WWW::PIDS::NextPredictedStopDetail> from the table.


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

L<WWW::PIDS::NextPredictedStopDetail>

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

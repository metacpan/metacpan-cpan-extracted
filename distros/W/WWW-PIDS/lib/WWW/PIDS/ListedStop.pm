package WWW::PIDS::ListedStop;

use strict;
use warnings;

our @ATTR = qw(Description Longitude Latitude Name SuburbName TID);

our @OATTR= qw(TurnType TurnMessage);

{
	no strict 'refs';

	for my $attr ( @ATTR, @OATTR ) {
		*{ __PACKAGE__ . "::$attr" } = sub {
			my $self = shift;
			return $self->{ $attr }
		}
	}
}

sub new {
	my ( $class, $obj )	= @_;
	my $self		= bless {} , $class;

	for my $a ( @ATTR ) {
		defined $obj->{ $a }
			? $self->{ $a } = $obj->{ $a }
			: die "Mandatory parameter $a not suppied in constructor" ;
	}

	for my $a ( @OATTR ) {
		# TODO - this class still needs fixing
		defined $obj->{ $a }
			? $self->{ $a } = $obj->{ $a }
			: $self->{ $a } = '' ;
	}

	return $self
}

1;

__END__

=head1 NAME 

WWW::PIDS::ListedStop - Utility class for representing tramTRACKER PIDS listed stops.

=head1 DESCRIPTION

WWW::PIDS::ListedStop is a utility class for representing abstract listed stop objects as
returned by invocation of the I<GetListOfStopsByRouteNoAndDirection> method in
the L<WWW::PIDS> module.

=head1 METHODS

=head2 Description

Returns the listed stop description as a human-readable string representing the 
stop place name or locality. e.g. 'Lincoln Square' or 'RMIT University'.

=head2 Latitude

Returns the stop latitude.

=head2 Longitude

Returns the stop longitude.

=head2 Name

Returns the stop name as a human-readable string representing a street address.
e.g. '3 Lincoln Square' or '7 RMIT University'.

=head2 SuburbName

Returns the suburb name of the stop as a human-readbale string representing the
suburb name. e.e. 'Carlton' or 'Melbourne City'.

=head2 TID

Returns the Tracker Stop ID of the stop.

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

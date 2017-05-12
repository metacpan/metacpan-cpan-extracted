=head1 NAME

Time::TCB - Barycentric Coordinate Time

=head1 SYNOPSIS

	use Time::TCB qw(tcb_instant_to_mjd tcb_mjd_to_instant);

	$mjd = tcb_instant_to_mjd($instant);
	$instant = tcb_mjd_to_instant($mjd);

=head1 DESCRIPTION

Barycentric Coordinate Time (TCB) is a coordinate time scale representing
time in the Sol system.  Specifically, it is the proper time experienced
by a distant clock comoving with the barycentre of the Sol system.

This module represents instants on the TCB time scale as a scalar number
of SI seconds since an epoch.  This is an appropriate form for all manner
of calculations.  TCB is defined with a well-known point at TAI instant
1977-01-01T00:00:00.0 at the Terran geocentre.  This point is assigned the
scalar value -460_080_000, putting the epoch at approximately the date
at which the resolution defining TCB was adopted by the International
Astronomical Union.  This epoch is deliberately very different from
those used for Geocentric Coordinate Time (TCG) in L<Time::TCG> and for
Terrestrial Time (TT) in L<Time::TT>, to avoid confusion between them.

There is also a conventional way to represent TCB instants using day-based
notations associated with planetary rotation `time' scales.  The `day'
of TCB is a nominal period of exactly 86400 SI seconds, which is slightly
shorter than an actual Terran day.  The well-known point at TAI instant
1977-01-01T00:00:00.0 is assigned the label 1977-01-01T00:00:32.184
(MJD 43144.0003725).  Because TCB is not connected to Terran rotation,
and so has no inherent concept of a day, it is somewhat misleading to
use such day-based notations.  Conversion between this notation and
the linear count of seconds is supported by this module.  The day-based
notations for TT, TCG, and TCB instants yield very similar values for
corresponding instants, so care must be taken to avoid confusion.

=cut

package Time::TCB;

{ use 5.006; }
use warnings;
use strict;

use Math::BigRat 0.13;

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(tcb_instant_to_mjd tcb_mjd_to_instant);

=head1 FUNCTIONS

=over

=item tcb_instant_to_mjd(INSTANT)

Converts from a count of seconds to a Modified Julian Date in the manner
conventional for TCB.  The MJD can be further converted to other forms of
day-based date using other modules.  The input must be a C<Math::BigRat>
object, and the result is the same type.

=cut

use constant TCB_EPOCH_MJD => Math::BigRat->new("48469.0003725");

sub tcb_instant_to_mjd($) {
	my($instant) = @_;
	return TCB_EPOCH_MJD + ($instant / 86400);
}

=item tcb_mjd_to_instant(MJD)

Converts from a Modified Julian Date, interpreted in the manner
conventional for TCB, to a count of seconds.  The input must be a
C<Math::BigRat> object, and the result is the same type.

=cut

sub tcb_mjd_to_instant($) {
	my($mjd) = @_;
	return ($mjd - TCB_EPOCH_MJD) * 86400;
}

=back

=head1 SEE ALSO

L<Date::JD>,
L<Time::TCG>,
L<Time::TT>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2010, 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

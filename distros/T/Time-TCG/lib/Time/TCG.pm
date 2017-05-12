=head1 NAME

Time::TCG - Geocentric Coordinate Time and realisations

=head1 SYNOPSIS

	use Time::TCG qw(tcg_instant_to_mjd tcg_mjd_to_instant);

	$mjd = tcg_instant_to_mjd($instant);
	$instant = tcg_mjd_to_instant($mjd);

	use Time::TCG qw(tcg_to_tt tt_to_tcg);

	$tt_instant = tcg_to_tt($tcg_instant);
	$tcg_instant = tt_to_tcg($tt_instant);

	use Time::TCG qw(tcg_realisation);

	$rln = tcg_realisation("bipm05");
	$instant = $rln->from_tcg_tai($tcg_tai_instant);

=head1 DESCRIPTION

Geocentric Coordinate Time (TCG) is a coordinate time scale representing
time in the Terran system.  Specifically, it is the proper time
experienced by a distant clock comoving with the geocentre.  It is
linearly related to Terrestrial Time (TT), which is the proper time scale
underlying timekeeping on the Terran surface.  TT is formally defined
in terms of TCG: TT ticks exactly 0.999_999_999_303_070_986_6 seconds
for each second of TCG.

This module represents instants on the TCG and TT time scales as scalar
numbers of SI seconds since an epoch.  This is an appropriate form for
all manner of calculations.  Both scales are defined with a well-known
point at TAI instant 1977-01-01T00:00:00.0.  This point is used as the
epoch for TCG, having the scalar value zero.  The same instant on the
TT scale is assigned the scalar value 599_616_000 exactly, corresponding
to an epoch near the TAI epoch 1958-01-01T00:00:00.0.  This matches the
convention used by C<Time::TT> for instants on the TT scale.  The use
of very different epochs for the two scales avoids confusion between them.

There is also a conventional way to represent TCG instants using day-based
notations associated with planetary rotation `time' scales.  The `day'
of TCG is a nominal period of exactly 86400 SI seconds, which is slightly
shorter than an actual Terran day.  The well-known point at TAI instant
1977-01-01T00:00:00.0 is assigned the label 1977-01-01T00:00:32.184
(MJD 43144.0003725).  Because TCG is not connected to Terran rotation,
and so has no inherent concept of a day, it is somewhat misleading to use
such day-based notations.  Conversion between this notation and the linear
count of seconds is supported by this module.  The day-based notations for
TT and TCG instants yield very similar values for corresponding instants,
so care must be taken to avoid confusion.

Because TCG is a theoretical time scale, not directly accessible for
practical use, it must be realised using atomic clocks.  In fact, it is TT
that is directly so realised, but the linear relationship between TT and
TCG means that any realisation of TT is effectively also realising TCG.
This module supports conversion of times between different realisations of
TCG, by making use of the facility in C<Time::TT> for realisations of TT.

=cut

package Time::TCG;

{ use 5.006; }
use warnings;
use strict;

use Math::BigRat 0.13;

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(
	tcg_instant_to_mjd tcg_mjd_to_instant
	tcg_to_tt tt_to_tcg
	tcg_realisation
);

=head1 FUNCTIONS

=over

=item tcg_instant_to_mjd(INSTANT)

Converts from a count of seconds to a Modified Julian Date in the manner
conventional for TCG.  The MJD can be further converted to other forms of
day-based date using other modules.  The input must be a C<Math::BigRat>
object, and the result is the same type.

=cut

use constant TCG_EPOCH_MJD => Math::BigRat->new("43144.0003725");

sub tcg_instant_to_mjd($) {
	my($instant) = @_;
	return TCG_EPOCH_MJD + ($instant / 86400);
}

=item tcg_mjd_to_instant(MJD)

Converts from a Modified Julian Date, interpreted in the manner
conventional for TCG, to a count of seconds.  The input must be a
C<Math::BigRat> object, and the result is the same type.

=cut

sub tcg_mjd_to_instant($) {
	my($mjd) = @_;
	return ($mjd - TCG_EPOCH_MJD) * 86400;
}

=item tcg_to_tt(TCG_INSTANT)

Converts from a TCG instant (as a count of seconds from the TCG epoch) to
the corresponding TT instant (as a count of seconds from the TT epoch).
The input must be a C<Math::BigRat> object, and the result is the
same type.

=cut

use constant TCG_EPOCH_TT => Math::BigRat->new(599616000);
use constant TT_TICK_RATE => Math::BigRat->new("0.9999999993030709866");

sub tcg_to_tt($) {
	my($tcg) = @_;
	return TCG_EPOCH_TT + TT_TICK_RATE * $tcg;
}

=item tt_to_tcg(TT_INSTANT)

Converts from a TT instant (as a count of seconds from the TT epoch)
to the corresponding TCG instant (as a count of seconds from the TCG
epoch).  The input must be a C<Math::BigRat> object, and the result is
the same type.

=cut

sub tt_to_tcg($) {
	my($tt) = @_;
	return ($tt - TCG_EPOCH_TT) / TT_TICK_RATE;
}

=item tcg_realisation(NAME)

Looks up and returns an object representing a named realisation of TCG.
The object returned is of the class C<Time::TCG::Realisation>; see the
documentation of that class for its interface.  Each TCG realisation
corresponds precisely to a realisation of TT.  The realisation names
that are understood are exactly the same as those understood by
C<tt_realisation> in L<Time::TT>.

The C<Time::TT> module is required in order to do this.

=cut

sub tcg_realisation($) {
	my($name) = @_;
	require Time::TT;
	require Time::TCG::Realisation;
	return Time::TCG::Realisation->new(Time::TT::tt_realisation($name));
}

=back

=head1 SEE ALSO

L<Date::JD>,
L<Time::TCB>,
L<Time::TCG::Realisation>,
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

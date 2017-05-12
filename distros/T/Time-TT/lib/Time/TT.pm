=head1 NAME

Time::TT - Terrestrial Time and its realisations

=head1 SYNOPSIS

	use Time::TT qw(tt_instant_to_mjd tt_mjd_to_instant);

	$mjd = tt_instant_to_mjd($instant);
	$instant = tt_mjd_to_instant($mjd);

	use Time::TT qw(tt_instant_to_jepoch tt_jepoch_to_instant);

	$jepoch = tt_instant_to_jepoch($instant);
	$instant = tt_jepoch_to_instant($jepoch);

	use Time::TT qw(tt_realisation);

	$rln = tt_realisation("bipm05");
	$instant = $rln->from_tai($tai_instant);

=head1 DESCRIPTION

Terrestrial Time (TT) is a time scale representing time on the surface
of Terra.  Specifically, it is the proper time experienced by a clock
located on the rotating geoid (i.e., at sea level).  It is indirectly the
basis for Terran civil timekeeping, via its realisation International
Atomic Time (TAI).  It is linearly related to (and in fact now defined
in terms of) the astronomical time scale Geocentric Coordinate Time (TCG).

This module represents instants on the TT time scale as a scalar number
of SI seconds since an epoch.  This is an appropriate form for all manner
of calculations.  The TT scale is defined with a well-known point at
TAI instant 1977-01-01T00:00:00.0.  That instant is assigned the scalar
value 599_616_000 exactly, corresponding to an epoch (scalar value zero)
near the TAI epoch 1958-01-01T00:00:00.0.  This matches the convention
used by C<Time::TAI> for instants on the TAI scale.  Because TAI does
not match the rate of TT perfectly, the TT epoch is not precisely equal
to the TAI epoch, but is instead around 600 us earlier than it.

There is also a conventional way to represent TT instants using day-based
notations associated with planetary rotation `time' scales.  The `day'
of TT is a nominal period of exactly 86400 SI seconds, which is slightly
shorter than an actual Terran day.  The well-known point at TAI instant
1977-01-01T00:00:00.0 is assigned the label 1977-01-01T00:00:32.184
(MJD 43144.0003725).  Because TT is not connected to Terran rotation,
and so has no inherent concept of a day, it is somewhat misleading to
use such day-based notations.  Conversion between this notation and the
linear count of seconds is supported by this module.  This notation does
not match the similar day-based notation used for TAI.

There is another conventional way to represent TT instants, using a larger
unit approximating the duration of a Terran year.  The `Julian year'
is a nominal period of exactly 365.25 `days' of exactly 86400 SI seconds
each.  The TT instant 2000-01-01T12:00:00.0 (MJD 51544.5) is labelled as
Julian epoch 2000.0.  Julian epochs are used only with TT, not with any
other time scale.  The Julian epoch numbers correspond approximately to
Gregorian calendar years, for dates within a few kiloyears of the epoch.
Because TT is not connected to the Terran orbit, and so has no inherent
concept of a year, the year-based notation is somewhat misleading.
Conversion between this notation and the linear count of seconds is
supported by this module.

Because TT is a theoretical time scale, not directly accessible for
practical use, it must be realised using atomic clocks.  This is done
by metrological agencies, each with different imperfections.  To achieve
microsecond accuracy it is necessary to take account of these differences.
This module supports conversion of times between different realisations
of TT.

=cut

package Time::TT;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Math::BigRat 0.13;

our $VERSION = "0.005";

use parent "Exporter";
our @EXPORT_OK = qw(
	tt_instant_to_mjd tt_mjd_to_instant
	tt_instant_to_jepoch tt_jepoch_to_instant
	tt_realisation
);

=head1 FUNCTIONS

=over

=item tt_instant_to_mjd(INSTANT)

Converts from a count of seconds to a Modified Julian Date in the manner
conventional for TT.  The MJD can be further converted to other forms of
day-based date using other modules.  The input must be a C<Math::BigRat>
object, and the result is the same type.

=cut

use constant TT_EPOCH_MJD => Math::BigRat->new("36204.0003725");

sub tt_instant_to_mjd($) {
	my($tt) = @_;
	return TT_EPOCH_MJD + ($tt / 86400);
}

=item tt_mjd_to_instant(MJD)

Converts from a Modified Julian Date, interpreted in the manner
conventional for TT, to a count of seconds.  The input must be a
C<Math::BigRat> object, and the result is the same type.

=cut

sub tt_mjd_to_instant($) {
	my($mjd) = @_;
	return ($mjd - TT_EPOCH_MJD) * 86400;
}

=item tt_instant_to_jepoch(INSTANT)

Converts from a count of seconds to a Julian epoch.  The input must be
a C<Math::BigRat> object, and the result is the same type.

=cut

use constant TT_EPOCH_JEPOCH => 1958 + Math::BigRat->new("0.0003725/365.25");

sub tt_instant_to_jepoch($) {
	my($tt) = @_;
	return TT_EPOCH_JEPOCH + ($tt / 31557600);
}

=item tt_jepoch_to_instant(JEPOCH)

Converts from a Julian epoch to a count of seconds.  The input must be
a C<Math::BigRat> object, and the result is the same type.

=cut

sub tt_jepoch_to_instant($) {
	my($jepoch) = @_;
	return ($jepoch - TT_EPOCH_JEPOCH) * 31557600;
}

=item tt_realisation(NAME)

Looks up and returns an object representing a named realisation of TT.
The object returned is of the class C<Time::TT::Realisation>; see the
documentation of that class for its interface.

The name, recognised case-insensitively, may be of these forms:

=over

=item B<bipm05>

Retrospective best estimate of TT, published by the BIPM.  TT(BIPM05)
was published in 2005, and other versions were (and will be) published
in other years, with the digits in the name varying accordingly.
These time scales are currently based on reanalysis of the TAI data.
They are defined by isolated data points, so conversions in general
involve interpolation; the process is by its nature inexact.

=item B<eal>

TT(EAL) is derived from the Free Atomic Scale (EAL).  EAL is the
weighted average of the time ticked by the clocks contributing to TAI,
with no gravitational correction applied.  TAI is generated by applying
a frequency shift to EAL to correct for gravitational time dilation.
The relationship between EAL and TAI is precisely defined, so conversions
are exact.

=item B<tai>

TT(TAI) is the principal realisation of TT, derived directly from
International Atomic Time (TAI).  This is defined monthly in retrospect
and then never revised.

=item B<tai/npl>

TT(TAI) based on TAI(NPL), the real-time estimate of TAI supplied by
the National Physical Laboratory in the UK.  Other real-time estimates
of TAI are named similarly using an abbreviation of the name of the
supplying agency.  See the C<tai_realisation> function in L<Time::TAI>
for more discussion, or L<Time::TT::Agencies> for a list of agencies.

=back

Other names may be recognised in the future, as more TT(k) time scales
are defined.

In order to use any of the TAI-based realisations the C<Time::TAI>
module is required.

=cut

#
# general
#

sub _get_bipm_file($) {
	my($fn) = @_;
	require Net::FTP::Tiny;
	Net::FTP::Tiny->VERSION(0.001);
	return Net::FTP::Tiny::ftp_get("ftp://ftp2.bipm.fr/pub/tai/$fn");
}

#
# TT(BIPMnn)
#

use constant TT_SYNCH_TIME => Math::BigRat->new(599616000);
use constant TT_SYNCH_MJD => 43144;

my %tt_bipmnn;

sub _tt_bipmnn($) {
	my($yr) = @_;
	my $r = $tt_bipmnn{$yr};
	return $r if defined $r;
	my $content = _get_bipm_file("scale/ttbipm.$yr");
	$content =~ /\A[\ \t\n]*TT\(BIPM[0-9]{2,4}\)\ is\ a\ realization/
		or die "doesn't look like a TT(BIPMnn) file\n";
	require Time::TT::OffsetKnot;
	Time::TT::OffsetKnot->VERSION(0.005);
	my @data;
	my $last_mjd = 0;
	while($content =~ /^\ *([0-9]+)\.(?:[-+]|\ +[-+]?)[0-9]+(?:\.[0-9]+)?
			   ([-+]|\ +[-+]?)([0-9]+(?:\.[0-9]+)?)\ *[\r\n]/xmg) {
		my($mjd, $sign, $offset_us) = ($1, $2, $3);
		die "data out of order at mjd=$mjd" unless $mjd > $last_mjd;
		if($last_mjd < TT_SYNCH_MJD && $mjd >= TT_SYNCH_MJD) {
			require Math::Interpolator::Knot;
			Math::Interpolator::Knot->VERSION(0.003);
			push @data, Math::Interpolator::Knot
					->new(TT_SYNCH_TIME, TT_SYNCH_TIME);
		}
		$offset_us = "-$offset_us" unless $sign =~ /-\z/;
		push @data, Time::TT::OffsetKnot->new($mjd, $offset_us, 6);
		$last_mjd = $mjd;
	}
	require Math::Interpolator::Robust;
	Math::Interpolator::Robust->VERSION(0.003);
	require Time::TT::InterpolatingRealisation;
	Time::TT::InterpolatingRealisation->VERSION(0.005);
	$r = Time::TT::InterpolatingRealisation->new(
		Math::Interpolator::Robust->new(@data));
	return $tt_bipmnn{$yr} = $r;
}

#
# TT(EAL)
#

my $tt_eal;

sub _tt_eal() {
	return $tt_eal if defined $tt_eal;
	my $content = _get_bipm_file("scale/ealtai04.ar");
	$content =~ /\A[\ \t\n]*[^\n]*differences between the normalized/i
		or die "doesn't look like an EAL file\n";
	require Math::Interpolator::Knot;
	Math::Interpolator::Knot->VERSION(0.003);
	my @data;
	my $tai = Math::BigRat->new(-94694400);   # 1955-01-01
	push @data, Math::Interpolator::Knot->new($tai, $tai);
	$tai = Math::BigRat->new(599616000);   # 1977-01-01
	push @data, Math::Interpolator::Knot->new($tai, $tai);
	my $mjd = Math::BigRat->new(43144);
	my $eal = $tai;
	my $fdiff_scale = Math::BigRat->new("0.0000000000001");
	while($content =~ /^\ *[0-9]+\ +[A-Za-z]+\ +[0-9]+\ +-
			    \ +[0-9]+\ +[A-Za-z]+\ +[0-9]+
			    \ +([0-9]+)\ +-\ +([0-9]+)
			    \ +([0-9]+(?:\.[0-9]+)?)[\ \t\n]/xmg) {
		my($old_mjd, $new_mjd, $fdiff) = ($1, $2, $3);
		$old_mjd = Math::BigRat->new($old_mjd);
		die "data not contiguous at mjd=$mjd" unless $old_mjd == $mjd;
		$new_mjd = Math::BigRat->new($new_mjd);
		$fdiff = Math::BigRat->new($fdiff) * $fdiff_scale;
		my $tai_s = ($new_mjd - $mjd) * 86400;
		my $eal_s = $tai_s * (1 + $fdiff);
		$mjd = $new_mjd;
		$tai += $tai_s;
		$eal += $eal_s;
		push @data, Math::Interpolator::Knot->new($tai, $eal);
	}
	$tai += 1000000;
	$eal += 1000000;
	require Math::Interpolator::Source;
	Math::Interpolator::Source->VERSION(0.003);
	push @data, Math::Interpolator::Source->new(
			sub () { croak "later data for TT(EAL) is missing"; },
			$tai, $eal);
	require Math::Interpolator::Linear;
	Math::Interpolator::Linear->VERSION(0.003);
	require Time::TT::InterpolatingRealisation;
	Time::TT::InterpolatingRealisation->VERSION(0.005);
	$tt_eal = Time::TT::InterpolatingRealisation->new(
			Math::Interpolator::Linear->new(@data));
	return $tt_eal;
}

#
# invocation of realisations
#

sub tt_realisation($) {
	my($k) = @_;
	if($k =~ m#\Atai(?:/(.+))?\z#si) {
		require Time::TAI;
		return Time::TAI::tai_realisation(defined($1) ? $1 : "");
	} elsif($k =~ m#\Abipm([0-9][0-9])\z#i) {
		my $yr = $1;
		return _tt_bipmnn($yr);
	} elsif($k =~ m#\Aeal\z#i) {
		return _tt_eal();
	} else {
		croak "no realisation TT(".uc($k).") known";
	}
}

=back

=head1 BUGS

The data for EAL only goes forward to mid-2005.  There is no
machine-readable source of subsequent data.

=head1 SEE ALSO

L<Date::JD>,
L<Time::TAI>,
L<Time::TCG>,
L<Time::TT::Agencies>,
L<Time::TT::Realisation>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

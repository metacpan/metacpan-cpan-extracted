=head1 NAME

Time::GPS - Global Positioning System time

=head1 SYNOPSIS

	use Time::GPS qw(gps_instant_to_mjd gps_mjd_to_instant);

	$mjd = gps_instant_to_mjd($instant);
	$instant = gps_mjd_to_instant($mjd);

	use Time::GPS qw(gps_realisation);

	$rln = gps_realisation("");
	$instant = $rln->to_tai($gps_instant);

=head1 DESCRIPTION

The Global Positioning System (GPS) includes as an integral feature the
dissemination of a very precise time scale.  This time scale is produced
by atomic clocks on the satellites, and is steered to keep in step with
International Atomic Time (TAI).  The GPS time scale is thus indirectly
a realisation of Terrestrial Time (TT).  GPS time is one of the most
accurate and the most accessible realisations of TAI.

This module represents instants on the TAI time scale as a scalar
number of TAI seconds since an epoch.  This is an appropriate form
for all manner of calculations.  The epoch used is that of TAI, at
UT2 instant 1958-01-01T00:00:00.0 as calculated by the United States
Naval Observatory, even though GPS did not exist then.  This matches
the convention used by C<Time::TAI> for instants on the TAI scale and
by C<Time::TT> for instants on the TT scale.

There is also a conventional way to represent GPS time instants using
day-based notations associated with planetary rotation `time' scales.
The `day' of GPS is a nominal period of exactly 86400 GPS seconds,
which is slightly shorter than an actual Terran day.  The start of
the GPS time scale, at UTC instant 1980-01-06T00:00:00.0 (TAI instant
1980-01-06T00:00:19.0) is assigned the label 1980-01-06T00:00:00.0
(MJD 44244.0).  Because GPS time is not connected to Terran rotation,
and so has no inherent concept of a day, it is somewhat misleading to
use such day-based notations.  Conversion between this notation and the
linear count of seconds is supported by this module.  This notation does
not match the similar day-based notations used for TAI and TT.

=cut

package Time::GPS;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Math::BigRat 0.03;

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(gps_instant_to_mjd gps_mjd_to_instant gps_realisation);

=head1 FUNCTIONS

=over

=item gps_instant_to_mjd(INSTANT)

Converts from a count of seconds to a Modified Julian Date in the
manner conventional for GPS time.  The MJD can be further converted to
other forms of day-based date using other modules.  The input must be
a C<Math::BigRat> object, and the result is the same type.

=cut

use constant GPS_EPOCH_MJD => Math::BigRat->new((36204*86400-19)."/86400");

sub gps_instant_to_mjd($) {
	my($gps) = @_;
	return GPS_EPOCH_MJD + ($gps / 86400);
}

=item gps_mjd_to_instant(MJD)

Converts from a Modified Julian Date, interpreted in the manner
conventional for GPS time, to a count of seconds.  The input must be a
C<Math::BigRat> object, and the result is the same type.

=cut

sub gps_mjd_to_instant($) {
	my($mjd) = @_;
	return ($mjd - GPS_EPOCH_MJD) * 86400;
}

=item gps_realisation(NAME)

Looks up and returns an object representing a named realisation of
GPS time.  The object returned is of the class C<Time::TT::Realisation>;
see the documentation of that class for its interface.

Presently the only name recognised is the empty string, representing
GPS time itself.  Other names may be recognised in the future.

The C<Time::TAI> module is required in order to do this.

=cut

sub gps_realisation($) {
	my($k) = @_;
	if($k eq "") {
		require Time::TAI;
		return Time::TAI::tai_realisation("gps");
	} else {
		croak "no realisation TT(TAI(GPS(".uc($k)."))) known";
	}
}

=back

=head1 SEE ALSO

L<Date::JD>,
L<Time::TAI>,
L<Time::TT>,
L<Time::TT::Realisation>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

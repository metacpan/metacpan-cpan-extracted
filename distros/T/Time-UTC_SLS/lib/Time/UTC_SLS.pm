=head1 NAME

Time::UTC_SLS - UTC with Smoothed Leap Seconds

=head1 SYNOPSIS

    use Time::UTC_SLS qw(utc_to_utcsls utcsls_to_utc);

    $mjd = utc_to_utcsls($day, $secs);
    ($day, $secs) = utcsls_to_day($mjd);

    use Time::UTC_SLS qw(
	utc_day_to_mjdn utc_mjdn_to_day
	utc_day_to_cjdn utc_cjdn_to_day);

    $mjdn = utc_day_to_mjdn($day);
    $day = utc_mjdn_to_day($mjdn);

    $cjdn = utc_day_to_cjdn($day);
    $day = utc_cjdn_to_day($cjdn);

=head1 DESCRIPTION

Coordinated Universal Time (UTC) is a time scale with days of unequal
lengths, due to leap seconds, in order to keep in step with both Terran
rotation (Universal Time, UT) and International Atomic Time (TAI).
Some applications that wish to use a time scale that maintains both of
these relations can't cope with unequal day lengths, and so cannot use
UTC properly.  UTC with Smoothed Leap Seconds (UTC-SLS) is another option
in such cases.  UTC-SLS is a time scale that usually matches UTC exactly
but changes rate in the time leading up to a leap second in order to
make every day appear to be exactly the same length.

On a normal UTC day, of length 86400 UTC seconds, UTC and UTC-SLS
behave identically.  On a day with a leap second, thus having 86401 or
(theoretically) 86399 UTC seconds, UTC and UTC-SLS behave identically
for most of the day, but the last 1000 UTC seconds correspond to 999 or
(theoretically) 1001 UTC-SLS seconds.  Thus every UTC-SLS day has exactly
86400 UTC-SLS seconds.  UTC and UTC-SLS are equal on every half hour,
and in particular the day boundaries (at midnight) are in the same place
on both time scales.  See L<http://www.cl.cam.ac.uk/~mgk25/time/utc-sls/>
for further explanation.

UTC-SLS is defined for the post-1972 form of UTC, using leap seconds.
The prior form, from 1961, using `rubber seconds' as well as leaps,
could be treated in a similar manner, but the exact algorithm has not
been defined.  The rubber seconds system was itself trying to achieve
part of what UTC-SLS does.

This module represents instants on the UTC scale by the combination of
a day number and a number of seconds since midnight within the day.
In this module the day number is the integral number of days since
1958-01-01, which is the epoch of TAI.  This is the convention used by
the C<Time::UTC> module.  Instants on the UTC-SLS scale are represented
by a Modified Julian Date, which is a fractional count of days since
1858-11-17T00Z.  The MJD is a suitable interchange format between
date-manipulation modules.

All numbers in this API are C<Math::BigRat> objects.  All numeric function
arguments must be C<Math::BigRat>s, and all numeric values returned are
likewise C<Math::BigRat>s.

=cut

package Time::UTC_SLS;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Math::BigRat 0.04;
use Time::UTC 0.007 qw(
	utc_day_seconds
	utc_day_to_mjdn utc_mjdn_to_day
	utc_day_to_cjdn utc_cjdn_to_day
);

our $VERSION = "0.005";

use parent "Exporter";
our @EXPORT_OK = qw(
	utc_to_utcsls utcsls_to_utc
	utc_day_to_mjdn utc_mjdn_to_day
	utc_day_to_cjdn utc_cjdn_to_day
);

=head1 FUNCTIONS

=over

=item utc_to_utcsls(DAY, SECS)

Converts from UTC to UTC-SLS.  The input is a UTC instant expressed as a
day number and a number of seconds since midnight, both as C<Math::BigRat>
objects.  Returns the corresponding UTC-SLS instant expressed as a
Modified Julian Date, as a C<Math::BigRat> object.

=cut

use constant UTCSLS_START_DAY => Math::BigRat->new(5113);
use constant TAI_EPOCH_MJD => Math::BigRat->new(36204);

sub utc_to_utcsls($$) {
	my($day, $secs) = @_;
	croak "day $day precedes the start of UTC-SLS"
		unless $day >= UTCSLS_START_DAY;
	unless($secs >= 0 && $secs <= 85399) {
		my $day_len = utc_day_seconds($day);
		croak "$secs seconds is out of range for a $day_len second day"
			if $secs < 0 || $secs >= $day_len;
		if($day_len != 86400) {
			croak "UTC-SLS is not defined for a $day_len ".
					"second day"
				unless $day_len == 86399 || $day_len == 86401;
			my $slew_from = $day_len - 1000;
			$secs = $slew_from + (86400 - $slew_from) *
					     ($secs - $slew_from)/1000
				if $secs > $slew_from;
		}
	}
	return utc_day_to_mjdn($day) + $secs/86400;
}

=item utcsls_to_utc(MJD)

Converts from UTC-SLS to UTC.  The input is a UTC-SLS instant expressed
as a Modified Julian Date, as a C<Math::BigRat> object.  Returns a list of
two values, giving the corresponding UTC instant expressed as a day number
and a number of seconds since midnight, both as C<Math::BigRat> objects.

=cut

sub utcsls_to_utc($) {
	my($mjd) = @_;
	my $mjdn = $mjd->copy->bfloor;
	my $secs = ($mjd - $mjdn) * 86400;
	my $day = $mjdn - TAI_EPOCH_MJD;
	croak "day $day precedes the start of UTC-SLS"
		unless $day >= UTCSLS_START_DAY;
	unless($secs <= 85399) {
		my $day_len = utc_day_seconds($day);
		if($day_len != 86400) {
			croak "UTC-SLS is not defined for a $day_len ".
					"second day"
				unless $day_len == 86399 || $day_len == 86401;
			my $slew_from = $day_len - 1000;
			$secs = $slew_from + 1000 * ($secs - $slew_from)/
						    (86400 - $slew_from)
				if $secs > $slew_from;
		}
	}
	return ($day, $secs);
}

=item utc_day_to_mjdn(DAY)

Takes a day number (days since the TAI epoch), as a C<Math::BigRat>
object, and returns the corresponding Modified Julian Day Number
(a number of days since 1858-11-17 UT), as a C<Math::BigRat> object.
MJDN is a standard numbering for days in Universal Time.  There is no
bound on the permissible day numbers; the function is not limited to
days for which UTC-SLS is defined.

=item utc_mjdn_to_day(MJDN)

This performs the reverse of the translation that C<utc_day_to_mjdn> does.
It takes a Modified Julian Day Number, as a C<Math::BigRat> object,
and returns the number of days since the TAI epoch, as a C<Math::BigRat>
object.  It does not impose any limit on the range.

=item utc_day_to_cjdn(DAY)

Takes a day number (days since the TAI epoch), as a C<Math::BigRat>
object, and returns the corresponding Chronological Julian Day Number
(a number of days since -4713-11-24), as a C<Math::BigRat> object.
CJDN is a standard day numbering that is useful as an interchange format
between implementations of different calendars.  There is no bound on
the permissible day numbers; the function is not limited to days for
which UTC-SLS is defined.

=item utc_cjdn_to_day(CJDN)

This performs the reverse of the translation that C<utc_day_to_cjdn> does.
It takes a Chronological Julian Day Number, as a C<Math::BigRat> object,
and returns the number of days since the TAI epoch, as a C<Math::BigRat>
object.  It does not impose any limit on the range.

=back

=head1 SEE ALSO

L<Date::JD>,
L<Time::UTC>,
L<http://www.cl.cam.ac.uk/~mgk25/time/utc-sls/>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2010, 2012, 2017
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

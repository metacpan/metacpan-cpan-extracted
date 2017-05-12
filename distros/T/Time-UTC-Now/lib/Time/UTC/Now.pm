=head1 NAME

Time::UTC::Now - determine current time in UTC correctly

=head1 SYNOPSIS

	use Time::UTC::Now
		qw(now_utc_rat now_utc_sna now_utc_flt now_utc_dec);

	($day, $secs, $bound) = now_utc_rat;
	($day, $secs, $bound) = now_utc_rat(1);
	($day, $secs, $bound) = now_utc_sna;
	($day, $secs, $bound) = now_utc_sna(1);
	($day, $secs, $bound) = now_utc_flt;
	($day, $secs, $bound) = now_utc_flt(1);
	($day, $secs, $bound) = now_utc_dec;
	($day, $secs, $bound) = now_utc_dec(1);

	use Time::UTC::Now qw(utc_day_to_mjdn utc_day_to_cjdn);

	$mjdn = utc_day_to_mjdn($day);
	$cjdn = utc_day_to_cjdn($day);

=head1 DESCRIPTION

This module is one answer to the question "what time is it?".
It determines the current time on the UTC scale, handling leap seconds
correctly, and puts a bound on how inaccurate it could be.  It is the
rigorously correct approach to determining civil time.  It is designed to
interoperate with L<Time::UTC>, which knows all about the UTC time scale.

UTC (Coordinated Universal Time) is a time scale derived from
International Atomic Time (TAI).  UTC divides time up into days, and
each day into seconds.  The seconds are atomically-realised SI seconds,
of uniform length.  Most UTC days are exactly 86400 seconds long,
but occasionally there is a day of length 86401 s or (theoretically)
86399 s.  These leap seconds are used to keep the UTC day approximately
synchronised with the non-uniform rotation of the Earth.  (Prior to 1972
a different mechanism was used for UTC, but that's not an issue here.)

Because UTC days have differing lengths, instants on the UTC scale
are identified here by the combination of a day number and a number
of seconds since midnight within the day.  In this module the day
number is the integral number of days since 1958-01-01, which is the
epoch of the TAI scale which underlies UTC.  This is the convention
used by the C<Time::UTC> module.  That module has some functions to
format these numbers for display.  For a more general solution, use
the C<utc_day_to_mjdn> function to translate to a standard Modified
Julian Day Number or the C<utc_day_to_cjdn> function to translate to a
standard Chronological Julian Day Number, which can be used as input to
a calendar module.

=cut

package Time::UTC::Now;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.010";

use parent "Exporter";
our @EXPORT_OK = qw(
	now_utc_rat now_utc_sna now_utc_flt now_utc_dec
	utc_day_to_mjdn utc_day_to_cjdn
);

require XSLoader;
XSLoader::load("Time::UTC::Now", $VERSION);

=head1 FUNCTIONS

=head2 Time determination

Each of these functions determines the current UTC time and returns it.
They vary in the form in which the time is returned.  In each case, the
function returns a list of three values.  The first two values identify
a current UTC instant, in the form of a day number (number of days since
the TAI epoch) and a number of seconds since midnight within the day.
The third value is an inaccuracy bound, as a number of seconds, or
C<undef> if no accurate answer could be determined.

If an inaccuracy bound is returned then the function is claiming to have
answered correctly, to within the specified margin.  That is, some instant
during the execution of the function is within the specified margin of
the instant identified.  (This semantic differs from older current-time
interfaces that are content to return an instant that has already passed.)
The inaccuracy bound describes the actual time represented in the return
values, not some internal value that was rounded to generate the return
values.

The inaccuracy bound is measured in UTC seconds; that is, in SI seconds
on the Terran geoid as realised by atomic clocks.  This differs from SI
seconds at the computer's location, but the difference is only apparent
if the computer hardware is significantly time dilated with respect to
the geoid.

If C<undef> is returned instead of an inaccuracy bound then the function
could not find a trustable answer.  Either the clock available was not
properly synchronised or its accuracy could not be established.  Whatever
time could be found is returned, but the function makes no claim that it
is accurate.  It should be treated with suspicion.  In practice, clocks
of this nature are especially likely to misbehave around leap seconds.

Each function will C<die> if it can't find a plausible time at all.
If the I<DEMAND_ACCURACY> parameter is supplied and true then it will
also die if it could not find an accurate answer, instead of returning
with C<undef> for the inaccuracy bound.

=over

=item now_utc_rat([DEMAND_ACCURACY])

All three return values are in the form of C<Math::BigRat> objects.

This retains full resolution, is future-proof, and is easy to manipulate,
but beware that C<Math::BigRat> is currently rather slow.  If performance
is a problem then consider using one of the functions below that return
the results in other formats.

=item now_utc_sna([DEMAND_ACCURACY])

The day number is returned as a Perl integer.  The time since midnight
and the inaccuracy bound (if present) are each returned in the form of
a three-element array, giving a high-resolution fixed-point number of
seconds.  The first element is the integral number of whole seconds, the
second is an integral number of nanoseconds in the range [0, 1000000000),
and the third is an integral number of attoseconds in the same range.

This form of return value is fairly efficient.  It is convenient for
decimal output, but awkward to do arithmetic with.  Its resolution is
adequate for the foreseeable future, but could in principle be obsoleted
some day.

It is presumed that native integer formats will grow fast enough to always
represent the day number fully; if not, 31 bits will overflow late in
the sixth megayear of the Common Era.  (Average day length by then is
projected to be around 86520 s, posing more serious problems for UTC.)

=item now_utc_flt([DEMAND_ACCURACY])

All the results are returned as native Perl numbers.  The day number is
returned as a Perl integer, with the same caveat as for C<now_utc_sna>.
The other two items are floating point numbers.

This form of return value is very efficient and easy to manipulate.
However, its resolution is limited, rendering it obsolete in the near
future unless floating point number formats get bigger.

=item now_utc_dec([DEMAND_ACCURACY])

Each of the results is returned in the form of a string expressing a
number as a decimal fraction.  These strings are of the type processed
by L<Math::Decimal>, and are always returned in L<Math::Decimal>'s
canonical form.

This form of return value is fairly efficient and easy to manipulate.
It is convenient both for decimal output and (via implicit coercion to
floating point) for low-precision arithmetic.  L<Math::Decimal> can be
used for high-precision arithmetic.  Its resolution is unlimited.

=back

=head2 Day count conversion

=over

=item utc_day_to_mjdn(DAY)

This function takes a number of days since the TAI epoch and returns
the corresponding Modified Julian Day Number (a number of days since
1858-11-17 UT).  MJDN is a standard numbering for days in Universal Time.
There is no bound on the permissible day numbers.

=cut

use constant _TAI_EPOCH_MJDN => 36204;

sub utc_day_to_mjdn($) {
	my($day) = @_;
	return _TAI_EPOCH_MJDN + $day;
}

=item utc_day_to_cjdn(DAY)

This function takes a number of days since the TAI epoch and returns
the corresponding Chronological Julian Day Number (a number of days
since -4713-11-24).  CJDN is a standard day numbering that is useful as
an interchange format between implementations of different calendars.
There is no bound on the permissible day numbers.

=cut

use constant _TAI_EPOCH_CJDN => 2436205;

sub utc_day_to_cjdn($) {
	my($day) = @_;
	return _TAI_EPOCH_CJDN + $day;
}

=back

=head1 TECHNIQUES

There are several interfaces available to determine the time on a
computer, and most of them suck.  This module will attempt to use the
best interface available when it runs.  It knows about the following:

=over

=item ntp_adjtime(), ntp_gettime()

These interfaces were devised for Unix systems using the Mills timekeeping
model, which is intended for clocks that are synchronised via NTP
(the Network Time Protocol).  The timekeeping model is detailed in
L<http://www.eecis.udel.edu/~mills/database/memos/memo96b.ps>.

These interfaces gives some leap second indications, and an inaccuracy
bound on the time returned.  Both are faulty in their raw form, but they
are corrected by this module.  (Those interested in the gory details are
invited to read the source.)  Resolution 1 us, or on some systems 1 ns.

=item GetSystemTimeAsFileTime()

This is part of the Win32 API of Microsoft Windows.

Misbehaves around leap seconds, and does not give an inaccuracy bound.
Resolution of the interface is 100 ns.

=item gettimeofday()

This is a long-standing Unix interface, so named because it was the
interface to the "time-of-day clock".

Misbehaves around leap seconds, and does not give an inaccuracy bound.
Resolution 1 us.

=item Time::Unix::time()

This is derived from the original Unix C<time()> function, which was
also adopted by the C library standard and by Perl.  Various systems
have different epochs and resolutions for the C<time()> function, so
it is not usable by this module on its own.  The C<Time::Unix> module
corrects for the varying epochs across OSes.

Misbehaves around leap seconds, and does not give an inaccuracy bound.
Resolution 1 s.

=back

The author would welcome patches to this module to make use of
high-precision interfaces, along the lines of C<ntp_adjtime()>, on
non-Unix operating systems.

=head1 OS-SPECIFIC NOTES

The author would appreciate reports of experiences with this module
under OSes not listed in this section.

=head2 Cygwin

Uses gettimeofday(), which gives resolution 1 us but no uncertainty
bound and is discontinuous at leap seconds.  There is no interface that
supplies an uncertainty bound or correct leap second handling.

=head2 FreeBSD

Experimental code (new in version 0.005) uses the FreeBSD variation of
ntp_gettime(), which gives resolution 1 us or 1 ns (depending on system
configuration) and uncertainty bound.  Please report experiences with
this code to the author.

=head2 Linux

Uses ntp_adjtime(), which gives resolution 1 us and uncertainty bound.

=head2 Solaris

Uses ntp_gettime(), which gives resolution 1 us and uncertainty bound.

=head2 Windows

Experimental code (new in version 0.007) uses the native
GetSystemTimeAsFileTime().  Observed clock resolution is 10 ms, but
lower-order digits are supplied (filled with noise) down to the API
resolution of 100 ns.  There is no uncertainty bound, and there are
discontinuities at leap seconds.  There is no interface that supplies
an uncertainty bound or correct leap second handling.

=head1 SEE ALSO

L<Time::TAI::Now>,
L<Time::UTC>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

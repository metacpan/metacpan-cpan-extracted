=head1 NAME

Time::UTC - manipulation of UTC in terms of TAI

=head1 SYNOPSIS

	use Time::UTC qw(
		utc_start_segment
		foreach_utc_segment_when_complete
		utc_start_tai_instant utc_start_utc_day
		utc_segment_of_tai_instant utc_segment_of_utc_day
	);

	$seg = utc_start_segment;
	foreach_utc_segment_when_complete { ... $_[0] ... };

	$instant = utc_start_tai_instant;
	$day = utc_start_utc_day;

	$seg = utc_segment_of_tai_instant($instant);
	$seg = utc_segment_of_utc_day($day);

	use Time::UTC qw(
		utc_day_leap_seconds utc_day_seconds
		utc_check_instant
	);

	$secs = utc_day_leap_seconds($day);
	$secs = utc_day_seconds($day);
	utc_check_instant($day, $secs);

	use Time::UTC qw(tai_to_utc utc_to_tai);

	($day, $secs) = tai_to_utc($instant);
	$instant = utc_to_tai($day, $secs);

	use Time::UTC qw(
		utc_secs_to_hms utc_hms_to_secs
		utc_day_to_ymd utc_ymd_to_day
		utc_instant_to_ymdhms utc_ymdhms_to_instant
	);

	($hr, $mi, $sc) = utc_secs_to_hms($secs);
	$secs = utc_hms_to_secs($hr, $mi, $sc);

	($yr, $mo, $dy) = utc_day_to_ymd($day);
	$day = utc_ymd_to_day($yr, $mo, $dy);

	($yr, $mo, $dy, $hr, $mi, $sc) =
		utc_instant_to_ymdhms($day, $secs);
	($day, $secs) = utc_ymdhms_to_instant(
				$yr, $mo, $dy, $hr, $mi, $sc);

	use Time::UTC qw(
		utc_day_to_mjdn utc_mjdn_to_day
		utc_day_to_cjdn utc_cjdn_to_day
	);

	$mjdn = utc_day_to_mjdn($day);
	$day = utc_mjdn_to_day($mjdn);

	$cjdn = utc_day_to_cjdn($day);
	$day = utc_cjdn_to_day($cjdn);

=head1 DESCRIPTION

This module encapsulates knowledge about the structure of the UTC time
scale, including the leap seconds of the current incarnation.  This
information is useful in manipulating times stored in a UTC-based format,
or in converting between UTC and TAI (the underlying atomic time scale).
It automatically downloads new UTC data as required to keep up to date.
This is a low-level module, intended for use by other modules that need
to know about UTC.  This module aims to be comprehensive and rigorous.

=head1 HISTORY OF UTC

Until the middle of the twentieth century, the passage of time was
measured primarily against the astronomical motions of the Earth and
other bodies.  These motions are very regular, and indeed were the
most temporally regular phenomena available to pre-industrial society.
After the invention of the caesium-based atomic clock, a gradual
transition from astronomic to atomic timekeeping began.  The hyperfine
transition of caesium is more regular than the Earth's motion, and so
makes a better time standard.  Unfortunately, this means that during the
transition phase there are two disagreeing time standards in use, and we
must jump through hoops to accommodate both.  UTC is one of these hoops.

=head2 Solar timekeeping

Each revolution of the Earth relative to the Sun (i.e., each day) has
traditionally been divided into units of hours, minutes, and seconds.
These are defined such that there are exactly 86400 seconds in a day.
Since these units are measuring the rotation of the Earth, rather than
the passage of time per se, it makes more sense to view these as measures
of I<angle> than of time.  Thus, the hour refers to a rotation of exactly
15 degrees, regardless of how much time that rotation takes, and so on.

Because the Earth's rotation is non-uniform, each day is a slightly
different length, and so the duration of the second, as defined above,
also varies over time.  This is not good in a time standard.  In order
to make the time as stable as possible, the non-uniformities of the
Earth's rotation need to be accounted for.  The use of I<mean solar
time> rather than I<apparent solar time> smooths out variation in the
apparent daily motion of the Sun over the course of the year that are
due to the non-circularity of the Earth's orbit.  The mean solar time
at Greenwich is known as I<Universal Time>, and specifically as I<UT1>.
I<UT2>, I<UT1R>, and I<UT2R> are smoothed versions of Universal Time,
removing periodic seasonal and tidal variations.

But however smoothed these scales get, they remain fundamentally measures
of angle rather than time.  They are not uniform over time.

=head2 Atomic timekeeping

It has been long recognised that the Earth's rotation is non-uniform,
and so that the scales based on the Earth's rotation are not stable
measures of time.  Scientists have therefore defined units of time that
are unrelated to the Earth's current motions.  Confusingly, the unit
so defined is called the "second", and is arranged to have a duration
similar to that of the traditional angle-based second, despite being
fundamentally different in intent.

The second in this sense was originally defined as 1/86400 of the mean
duration of a solar day.  In 1956 the second was redefined in terms of the
length of the tropical year 1900 (the "ephemeris second"), in recognition
of the non-uniformity of the Earth's rotation.  This definition was
superseded in 1967 by a definition based on the hyperfine transition
of caesium, following a decade of experience with early caesium clocks.
That definition was refined in 1997, and further refinements may happen
in the future.

The important aspects of atomic timekeeping, for our purposes, are that
it is more stable than the Earth's spin; it is independent of the Earth's
current spin; and it confusingly uses much of the same terminology as
measurement of the Earth's spin.

=head2 TAI

Time started to be measured using atomic clocks in 1955, and the first
formal atomic time scale started at the beginning of 1958.  In 1961
an international effort constructed a new time scale, synchronised
with the first one, which eventually (in 1971) came to be known as
I<International Atomic Time> or I<TAI>.  TAI is strictly a measure of
time as determined by atomic clocks, and is entirely independent of
the Earth's daily revolutions.  However, it uses the terminology and
superficial appearance of the time scales that went before it, which is
to say the angle scales.  Thus a point on the TAI scale is conventionally
referred to by specifying a date and a time of day, the latter composed
of hours, minutes, and seconds.

Like the pure measures of rotation, TAI has exactly 86400 seconds per day.
Completely unlike those measures, TAI's seconds are, as far as possible,
of identical duration, the duration with which the second was defined
in 1967.  TAI, through its predecessor atomic time scale, was initially
synchronised with Universal Time, so that TAI and UT2 describe the same
instant as 1958-01-01T00:00:00.0 (at least, according to the United States
Naval Observatory's determination of UT2).  TAI now runs independently
of UT, and at the time of writing (early 2005) TAI is about 32.5 seconds
ahead of UT1.

=head2 UTC

Over the long term, the world is switching from basing civil time on UT1
(i.e., the revolution of the Earth) to basing civil time on TAI (i.e.,
atomic clocks).  In the short term, however, a clean switch is not such
a popular idea.  There is a demand for a hybrid system which is based
on atomic clocks but which also maintains synchronisation with the
Earth's spin.  UTC is that system.

UTC is defined in terms of TAI, and is in that sense an atomic time
standard.  However, the relation between UTC and TAI is determined only
a few months in advance.  The relation changes over time, so that UTC
remains an approximation of UT1.

This concept behind UTC originates with the WWV radio time signal station
in the USA.  Up until 1956 it had, like all time signal stations at
the time, transmitted the closest achievable approximation of UT1.
In 1956, with atomic clocks now available, the National Bureau of
Standards started to base WWV's signals on atomic frequency standards.
Rather than continuously adjust the frequency to track UT1, as had been
previously done, they set the frequency once to match the rate of UT1
and then let it diverge by accurately maintaining the same frequency.
When the divergence grew too large, the time signals were stepped by 20
ms at a time to keep the magnitude of the difference within chosen limits.

This new system, deliberately accepting a visible difference between
signalled time and astronomical time, was initially controversial, but
soon caught on.  Other time signal stations operated by other bodies,
such as the National Physical Laboratory in the UK, started to use the
same type of scheme.  This raised the problem of keeping the time signals
synchronised, so international agreement became necessary.

In 1960, with the frequency of the caesium hyperfine transition now
established (though it did not become the SI standard until 1967),
a frequency offset for time signals was internationally agreed,
chosen to match the then-current rate of UT2.  It was decided that
the International Time Bureau (BIH, Bureau International de l'Heure)
would henceforth determine what frequency offset to use, changing it if
necessary at each year end, and also coordinate the necessary time steps
to closely approximate UT2.  Thus was international synchronisation of
time signals achieved.

From the beginning of 1961 this system was formalised as Coordinated
Universal Time (UTC).  Time steps, both forward and backward, were always
introduced at midnight, achieved by making a UTC day have a length other
than 86400 UTC seconds.  The time steps of 20 ms having been found to be
inconveniently frequent, it was decided to use steps of 50 ms instead.
This was soon increased to 100 ms.  This arrangement lasted until the
end of 1971.

The frequency offsets, which when correctly chosen avoided the need for
many time steps, were found to be inconvenient.  Radio time signals
commonly provided per-second pulses that were phase-locked to the
carrier signal, and maintaining that relation meant that the frequency
offset to make atomic time match UT2 had to be applied to the carrier
frequency also.  This made the carrier unreliable as a frequency standard,
which was a secondary use made of it.

To maintain the utility of time signals as frequency standards, from
the beginning of 1972 the frequency offset was permanently set to zero.
Henceforth the UTC second is identical in duration to the TAI second.
The size of the time steps was increased again, to one second, to make the
steps less frequent and to avoid phase shifts in per-second pulse signals.
An irregular time step was used to bring UTC to an integral number of
seconds offset from TAI, where it henceforth remains.

Because of the zero frequency offset, the new form of UTC has only had
backward jumps (by having an 86401 s UTC day).  Forward jumps are also
theoretically possible, but unlikely to ever occur.

Notice that the new form of UTC is more similar to TAI than the old
form was.  This appears to be part of the gradual switch from solar
time to atomic time.  It has been proposed (controversially) that in
the near future the system of irregularities in UTC will terminate,
resulting in a purely atomic time scale.

=head1 STRUCTURE OF UTC

UTC is a time scale derived from TAI.  UTC divides time up into days,
and each day into seconds.  Most UTC days are exactly 86400 UTC seconds
long, but they can be up to a second shorter or longer.  The UTC second
is in general slightly different from the TAI second; it stays stable
most of the time, occasionally undergoing an instantaneous change.
Since 1972 the UTC second has been equal to the TAI second, and it will
remain so in the future.

The details of the day lengths, and until 1972 the length of the UTC
second, are published by the International Earth Rotation and Reference
Systems Service (IERS).  They are announced only a few months in advance,
so it is not possible to convert between TAI and UTC for times more than
a few months ahead.

UTC is not defined for dates prior to 1961.

=cut

package Time::UTC;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Math::BigRat 0.08;
use Time::UTC::Segment 0.007;

our $VERSION = "0.008";

use parent "Exporter";
our @EXPORT_OK = qw(
	utc_start_segment foreach_utc_segment_when_complete
	utc_start_tai_instant utc_start_utc_day
	utc_segment_of_utc_day utc_segment_of_tai_instant
	utc_day_leap_seconds utc_day_seconds utc_check_instant
	tai_to_utc utc_to_tai
	utc_secs_to_hms utc_hms_to_secs utc_day_to_ymd utc_ymd_to_day
	utc_instant_to_ymdhms utc_ymdhms_to_instant
	utc_day_to_mjdn utc_mjdn_to_day
	utc_day_to_cjdn utc_cjdn_to_day
);

=head1 FUNCTIONS

Because UTC is defined purely in terms of TAI, these interfaces make
frequent use of the TAI epoch, 1958-01-01T00:00:00.0.  Instants on the
TAI scale are identified by a scalar number of TAI seconds since the TAI
epoch; this is a perfectly linear scale with no discontinuities.  The TAI
seconds count can be trivially split into the conventional units of days,
hours, minutes, and seconds for display (TAI days contain exactly 86400
TAI seconds each).

Because UTC days have differing lengths, instants on the UTC scale are
identified by the combination of an integral number of days since the
TAI epoch and a number of UTC seconds since midnight within the day.
In some interfaces the day number is used alone.  The conversion of
the number of seconds within a day into hours, minutes, and seconds for
display is idiosyncratic; the function C<utc_secs_to_hms> handles this.

All numbers in this API are C<Math::BigRat> objects.  All numeric function
arguments must be C<Math::BigRat>s, and all numeric values returned are
likewise C<Math::BigRat>s.

=head2 Description of UTC

This module contains a machine-manipulable description of the relation
between UTC and TAI.  Most users of this module do not need to examine
this directly, and will be better served by the higher-level functions
described later.  However, users with unusual requirements have access
to the description if necessary.  The functions in this section deal
with this.

The internal description is composed of C<Time::UTC::Segment> objects.
Each segment object describes a period of time over which the relation
between UTC and TAI is stable.  See L<Time::UTC::Segment> for details of
how to use these objects.  More segments can appear during the course
of a program's execution: updated UTC data is automatically downloaded
as required.

=over

=item utc_start_segment

Returns the first segment of the UTC description.  The later segments can
be accessed from the first one.  This function is intended for programs
that will walk through the entire description.

=cut

sub utc_start_segment() { Time::UTC::Segment->start }

=item foreach_utc_segment_when_complete(WHAT)

=item foreach_utc_segment_when_complete BLOCK

I<WHAT> must be a reference to a function which takes one argument;
it may be specified as a bare BLOCK in the function call.  The function
is called for each segment of the UTC description in turn, passing the
segment as an argument to the function.  This call takes place, for each
segment, when it is complete, as described in L<Time::UTC::Segment>.
The function is immediately called for already-complete segments.

To do this for only one segment, see the C<when_complete> method on
C<Time::UTC::Segment>.

=cut

sub foreach_utc_segment_when_complete(&) {
	my($what) = @_;
	my $setup_for_segment;
	$setup_for_segment = sub($) {
		my($seg) = @_;
		$seg->when_complete(sub() {
			eval { local $SIG{__DIE__}; $what->($seg); };
			$setup_for_segment->($seg->next);
		});
	};
	$setup_for_segment->(utc_start_segment());
}

my @segments = (utc_start_segment());
foreach_utc_segment_when_complete {
	push @segments, $_[0]->next;
};

=item utc_start_tai_instant

Identifies the instant at which the UTC service started.  This instant
was the start of the first UTC day.

=cut

sub utc_start_tai_instant() { $segments[0]->start_tai_instant }

=item utc_start_utc_day

Identifies the first day of UTC service.

=cut

sub utc_start_utc_day() { $segments[0]->start_utc_day }

=item utc_segment_of_tai_instant(INSTANT)

Returns the segment of the UTC description that pertains to the specified
TAI instant.  C<die>s if the specified instant precedes the start of
UTC or if the relevant segment hasn't been defined yet.

=cut

sub utc_segment_of_tai_instant($) {
	my($instant) = @_;
	my $min = 0;
	TRY_AGAIN:
	my $final = @segments - 1;
	my $max = $final;
	while($max > $min + 1) {
		use integer;
		my $try = ($min + $max) / 2;
		if($instant >= $segments[$try]->start_tai_instant) {
			$min = $try;
		} else {
			$max = $try;
		}
	}
	if($min == 0 && $instant < $segments[0]->start_tai_instant) {
		croak "instant $instant precedes the start of UTC";
	}
	if($max == $final &&
			$instant >= $segments[$final]->start_tai_instant) {
		eval { local $SIG{__DIE__}; $segments[$final]->next; };
		goto TRY_AGAIN if @segments != $final + 1;
		croak "instant $instant has no UTC definition yet";
	}
	return $segments[$min];
}

=item utc_segment_of_utc_day(DAY)

Returns the segment of the UTC description that pertains to the specified
day number.  C<die>s if the specified day precedes the start of UTC or
if the relevant segment hasn't been defined yet.

=cut

sub utc_segment_of_utc_day($) {
	my($day) = @_;
	croak "non-integer day $day is invalid" unless $day->is_int;
	my $min = 0;
	TRY_AGAIN:
	my $final = @segments - 1;
	my $max = $final;
	while($max > $min + 1) {
		use integer;
		my $try = ($min + $max) / 2;
		if($day >= $segments[$try]->start_utc_day) {
			$min = $try;
		} else {
			$max = $try;
		}
	}
	if($min == 0 && $day < $segments[0]->start_utc_day) {
		croak "day $day precedes the start of UTC";
	}
	if($max == $final && $day >= $segments[$final]->start_utc_day) {
		eval { local $SIG{__DIE__}; $segments[$final]->next; };
		goto TRY_AGAIN if @segments != $final + 1;
		croak "day $day has no UTC definition yet";
	}
	return $segments[$min];
}

=back

=head2 Shape of UTC

=over

=item utc_day_leap_seconds(DAY)

Returns the number of extra UTC seconds inserted at the end of the day
specified by number.  The number is returned as a C<Math::BigRat> and
may be negative.  C<die>s if the specified day precedes the start of
UTC or if UTC for the day has not yet been defined.

=item utc_day_seconds(DAY)

Returns the length, in UTC seconds, of the day specified by number.
The number is returned as a C<Math::BigRat>.  C<die>s if the specified day
precedes the start of UTC or if UTC for the day has not yet been defined.

=cut

{
	my $bigrat_0 = Math::BigRat->new(0);
	my $bigrat_86400 = Math::BigRat->new(86400);
	my $end_day = $segments[0]->start_utc_day;
	my(%day_leap_seconds, %day_seconds);
	foreach_utc_segment_when_complete {
		my($seg) = @_;
		my $day = $seg->last_utc_day;
		$day = "$day";
		my $ls = $seg->leap_utc_seconds;
		$day_leap_seconds{$day} = $ls;
		$day_seconds{$day} = $bigrat_86400 + $ls;
		$end_day = $seg->end_utc_day;
	};
	sub _utc_day_value($$$) {
		my($day, $hash, $default) = @_;
		croak "non-integer day $day is invalid" unless $day->is_int;
		croak "day $day precedes the start of UTC"
			if $day < $segments[0]->start_utc_day;
		if($day >= $end_day) {
			eval { local $SIG{__DIE__}; $segments[-1]->next; };
			if($day >= $end_day) {
				croak "day $day has no UTC definition yet";
			}
		}
		my $val = $hash->{$day};
		return defined($val) ? $val : $default;
	}
	sub utc_day_leap_seconds($) {
		my($day) = @_;
		return _utc_day_value($day, \%day_leap_seconds, $bigrat_0);
	}
	sub utc_day_seconds($) {
		my($day) = @_;
		return _utc_day_value($day, \%day_seconds, $bigrat_86400);
	}
}

=item utc_check_instant(DAY, SECS)

Checks that a day/seconds combination is valid.  C<die>s if UTC is not
defined for the specified day or if the number of seconds is out of
range for that day.

=cut

sub utc_check_instant($$) {
	my($day, $secs) = @_;
	my $day_len = utc_day_seconds($day);
	croak "$secs seconds is out of range for a $day_len second day"
		if $secs->is_negative || $secs >= $day_len;
}

=back

=head2 Conversion between UTC and TAI

=over

=item tai_to_utc(INSTANT)

Translates a TAI instant into UTC.  The function returns a list of two
values: the integral number of days since the TAI epoch and the number
of UTC seconds within the day.  C<die>s if the specified instant precedes
the start of UTC or if UTC is not yet defined for the instant.

=cut

sub tai_to_utc($) {
	my($instant) = @_;
	my $seg = utc_segment_of_tai_instant($instant);
	my $tai_offset = $instant - $seg->start_tai_instant;
	my $utc_offset = $tai_offset / $seg->utc_second_length;
	my $day_offset = ($utc_offset / 86400)->bfloor;
	my $secs = $utc_offset % 86400;
	my $day = $seg->start_utc_day + $day_offset;
	if($day == $seg->end_utc_day) {
		$day--;
		$secs += 86400;
	}
	return ($day, $secs);
}

=item utc_to_tai(DAY, SECS)

Translates a UTC instant into TAI.  C<die>s if the specified instant
precedes the start of UTC or if UTC is not yet defined for the instant,
or if the number of seconds is out of range for the day.

=cut

sub utc_to_tai($$) {
	my($day, $secs) = @_;
	my $seg = utc_segment_of_utc_day($day);
	my $day_len = $day == $seg->last_utc_day ?
			$seg->last_day_utc_seconds : 86400;
	croak "$secs seconds is out of range for a $day_len second day"
		if $secs->is_negative || $secs >= $day_len;
	my $utc_offset = ($day - $seg->start_utc_day) * 86400 + $secs;
	my $tai_offset = $utc_offset * $seg->utc_second_length;
	return $seg->start_tai_instant + $tai_offset;
}

=back

=head2 Display formatting

=over

=item utc_secs_to_hms(SECS)

When a UTC day is longer than 86400 seconds, it is divided into hours
and minutes in an idiosyncratic manner.  Rather than times more than
86400 seconds after midnight being displayed as 24 hours and a fraction
of a second, they are displayed as 23 hours, 59 minutes, and more than
60 seconds.  This means that each UTC day contains the usual 1440 minutes;
where leap seconds occur, the last minute of the day has a non-standard
length.  This arrangement is essential to make timezones work with UTC.

This function takes a number of seconds since midnight and returns a list
of hours, minutes, and seconds values, in the UTC manner.  It C<die>s
if given a negative number of seconds.  It places no upper limit on the
number of seconds, because the length of UTC days varies.

=cut

{
	my $bigrat_23 = Math::BigRat->new(23);
	my $bigrat_59 = Math::BigRat->new(59);

	sub utc_secs_to_hms($) {
		my($secs) = @_;
		croak "can't have negative seconds in a day"
			if $secs->is_negative;
		if($secs >= 86400-60) {
			return ($bigrat_23, $bigrat_59, $secs - (86400-60));
		} else {
			return (($secs / 3600)->bfloor,
				(($secs % 3600) / 60)->bfloor,
				$secs % 60);
		}
	}
}

=item utc_hms_to_secs(HR, MI, SC)

This performs the reverse of the translation that C<utc_secs_to_hms> does.
It takes numbers of hours, minutes, and seconds, and returns the number of
seconds since midnight.  It C<die>s if the numbers provided are invalid.
It does not impose an upper limit on the time that may be specified,
because the length of UTC days varies.

=cut

sub utc_hms_to_secs($$$) {
	my($hr, $mi, $sc) = @_;
	croak "invalid hour number $hr"
		unless $hr->is_int && !$hr->is_negative && $hr < 24;
	croak "invalid minute number $mi"
		unless $mi->is_int && !$mi->is_negative && $mi < 60;
	croak "invalid second number $sc"
		unless !$sc->is_negative &&
			(($hr == 23 && $mi == 59) || $sc < 60);
	return 3600*$hr + 60*$mi + $sc;
}

=item utc_day_to_ymd(DAY)

Although UTC is compatible with any means of labelling days, and the
scalar day numbering used in this API can be readily converted into
whatever form is required, it is conventional to label UTC days using the
Gregorian calendar.  Even when using some other calendar, the Gregorian
calendar may be a convenient intermediate form, because of its prevalence.

This function takes a number of days since the TAI epoch and returns a
list of a year, month, and day, in the Gregorian calendar.  It places no
bounds on the permissible day numbers; it is not limited to days for which
UTC is defined.  All year numbers generated are in the Common Era, and
may be zero or negative if a sufficiently negative day number is supplied.

=cut

{
	my @nonleap_monthstarts =
		(0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365);
	my @leap_monthstarts =
		(0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366);
	sub _monthstarts($) {
		my($yr) = @_;
		my $isleap = $yr % 4 == 0 ? $yr % 100 == 0 ?
				$yr % 400 == 0 ? 1 : 0 : 1 : 0;
		return $isleap ? \@leap_monthstarts : \@nonleap_monthstarts;
	}
}

sub utc_day_to_ymd($) {
	my($day) = @_;
	croak "non-integer day $day is invalid" unless $day->is_int;
	$day += 365*358 + 87;
	my $qcents = ($day / (365*400 + 97))->bfloor;
	$day -= $qcents * (365*400 + 97);
	my $yr = ($day / 366)->bfloor;
	my $leaps = (($yr + 3) / 4)->bfloor;
	$leaps -= (($leaps - 1) / 25)->bfloor unless $leaps->is_zero;
	$day -= 365 * $yr + $leaps;
	my $monthstarts = _monthstarts($yr);
	if($day >= $monthstarts->[12]) {
		$day -= $monthstarts->[12];
		$yr++;
		$monthstarts = _monthstarts($yr);
	}
	my $mo = 1;
	while($day >= $monthstarts->[$mo]) {
		$mo++;
	}
	my $dy = Math::BigRat->new(1 + $day - $monthstarts->[$mo - 1]);
	return (1600 + $qcents * 400 + $yr, Math::BigRat->new($mo), $dy);
}

=item utc_ymd_to_day(YR, MO, DY)

This performs the reverse of the translation that C<utc_day_to_ymd> does.
It takes year, month, and day numbers, and returns the number of days
since the TAI epoch.  It C<die>s if the numbers provided are invalid.
It does not impose any limit on the range of years.

=cut

sub utc_ymd_to_day($$$) {
	my($yr, $mo, $dy) = @_;
	croak "invalid year number $yr"
		unless $yr->is_int;
	croak "invalid month number $mo"
		unless $mo->is_int && $mo >= 1 && $mo <= 12;
	$mo = $mo->numify;
	my $monthstarts = _monthstarts($yr);
	croak "invalid day number $dy"
		unless $dy->is_int && $dy >= 1 &&
			$dy <= $monthstarts->[$mo] - $monthstarts->[$mo - 1];
	$yr -= 1600;
	my $qcents = ($yr / 400)->bfloor;
	my $day = Math::BigRat->new(-(365*358 + 87)) +
			$qcents * (365*400 + 97);
	$yr -= $qcents * 400;
	$day += 365 * $yr;
	my $leaps = (($yr + 3) / 4)->bfloor;
	$leaps -= (($leaps - 1) / 25)->bfloor unless $leaps->is_zero;
	$day += $leaps;
	$day += $monthstarts->[$mo - 1];
	$day += $dy - 1;
	return $day;
}

=item utc_instant_to_ymdhms(DAY, SECS)

=item utc_ymdhms_to_instant(YR, MO, DY, HR, MI, SC)

As a convenience, these two functions package together the corresponding
pairs of display formatting functions described above.  They do nothing
extra that the underlying functions do not; they do not check that the
instant specified is actually a valid UTC time.

=cut

sub utc_instant_to_ymdhms($$) {
	my($day, $secs) = @_;
	return (utc_day_to_ymd($day), utc_secs_to_hms($secs));
}

sub utc_ymdhms_to_instant($$$$$$) {
	my($yr, $mo, $dy, $hr, $mi, $sc) = @_;
	return (utc_ymd_to_day($yr, $mo, $dy), utc_hms_to_secs($hr, $mi, $sc));
}

=back

=head2 Calendar conversion

=over

=item utc_day_to_mjdn(DAY)

This function takes a number of days since the TAI epoch and returns
the corresponding Modified Julian Day Number (a number of days since
1858-11-17 UT).  MJDN is a standard numbering for days in Universal Time.
There is no bound on the permissible day numbers; the function is not
limited to days for which UTC is defined.

=cut

use constant _TAI_EPOCH_MJDN => Math::BigRat->new(36204);

sub utc_day_to_mjdn($) {
	my($day) = @_;
	croak "non-integer day $day is invalid" unless $day->is_int;
	return _TAI_EPOCH_MJDN + $day;
}

=item utc_mjdn_to_day(MJDN)

This performs the reverse of the translation that C<utc_day_to_mjdn> does.
It takes a Modified Julian Day Number and returns the number of days
since the TAI epoch.  It does not impose any limit on the range.

=cut

sub utc_mjdn_to_day($) {
	my($mjdn) = @_;
	croak "invalid MJDN $mjdn" unless $mjdn->is_int;
	return $mjdn - _TAI_EPOCH_MJDN;
}

=item utc_day_to_cjdn(DAY)

This function takes a number of days since the TAI epoch and returns
the corresponding Chronological Julian Day Number (a number of days
since -4713-11-24).  CJDN is a standard day numbering that is useful as
an interchange format between implementations of different calendars.
There is no bound on the permissible day numbers; the function is not
limited to days for which UTC is defined.

=cut

use constant _TAI_EPOCH_CJDN => Math::BigRat->new(2436205);

sub utc_day_to_cjdn($) {
	my($day) = @_;
	croak "non-integer day $day is invalid" unless $day->is_int;
	return _TAI_EPOCH_CJDN + $day;
}

=item utc_cjdn_to_day(CJDN)

This performs the reverse of the translation that C<utc_day_to_cjdn> does.
It takes a Chronological Julian Day Number and returns the number of
days since the TAI epoch.  It does not impose any limit on the range.

=cut

sub utc_cjdn_to_day($) {
	my($cjdn) = @_;
	croak "invalid CJDN $cjdn" unless $cjdn->is_int;
	return $cjdn - _TAI_EPOCH_CJDN;
}

=back

=head1 SEE ALSO

L<Date::ISO8601>,
L<Date::JD>,
L<DateTime>,
L<Time::UTC::Now>,
L<Time::UTC::Segment>,
L<Time::TAI>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2005, 2006, 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

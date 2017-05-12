=head1 NAME

Time::TAI::Now - determine current time in TAI

=head1 SYNOPSIS

	use Time::TAI::Now qw(now_tai_rat now_tai_gsna now_tai_flt);

	($instant, $bound) = now_tai_rat;
	($instant, $bound) = now_tai_rat(1);
	($instant, $bound) = now_tai_gsna;
	($instant, $bound) = now_tai_gsna(1);
	($instant, $bound) = now_tai_flt;
	($instant, $bound) = now_tai_flt(1);

=head1 DESCRIPTION

This module is one answer to the question "what time is it?".
It determines the current time on the TAI scale, and puts a bound on how
inaccurate it could be.  It is designed to interoperate with L<Time::TAI>,
which knows all about the TAI time scale.

TAI (International Atomic Time) is a time scale produced by an ensemble of
atomic clocks around Terra.  It attempts to tick at the rate of proper
time on the Terran geoid (i.e., at sea level).  It is the frequency
standard underlying Coordinated Universal Time (UTC).

TAI is not connected to planetary rotation, and so has no inherent
concept of a "day" or of "time of day".  (There is nevertheless a
convention for how to represent TAI times using day-based notations,
for which see L<Time::TAI>.)  This module represents instants on the
TAI time scale as a scalar number of TAI seconds since its epoch, which
was at 1958-01-01T00:00:00.0 UT2 as calculated by the United States
Naval Observatory.  This matches the convention used by C<Time::TAI>.

=cut

package Time::TAI::Now;

{ use 5.006; }
use warnings;
use strict;

use Data::Float 0.008 qw(significand_step float_parts mult_pow2);
use Math::BigRat 0.10;
use Time::UTC 0.005 qw(utc_to_tai);
use Time::UTC::Now 0.007 qw(now_utc_rat now_utc_sna now_utc_flt);

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(now_tai_rat now_tai_gsna now_tai_flt);

use constant BIGRAT_ZERO => Math::BigRat->new(0);

=head1 FUNCTIONS

=over

=item now_tai_rat([DEMAND_ACCURACY])

Returns a list of two values.  The first value identifies a current TAI
instant, in the form of a number of seconds since the epoch.  The second
value is an inaccuracy bound, as a number of seconds, or C<undef> if no
accurate answer could be determined.

If an inaccuracy bound is returned then this function is claiming to have
answered correctly, to within the specified margin.  That is, some instant
during the execution of C<now_tai_rat> is within the specified margin of
the instant identified.  (This semantic differs from older current-time
interfaces that are content to return an instant that has already passed.)

The inaccuracy bound is measured in TAI seconds; that is, in SI seconds
on the Terran geoid as realised by atomic clocks.  This differs from SI
seconds at the computer's location, but the difference is only apparent
if the computer hardware is significantly time dilated with respect to
the geoid.

If C<undef> is returned instead of an inaccuracy bound then this function
could not find a trustable answer.  Either the clock available was
not properly synchronised or its accuracy could not be established.
Whatever time could be found is returned, but this function makes
no claim that it is accurate.  It should be treated with suspicion.
In practice, clocks of this nature are especially likely to misbehave
around UTC leap seconds.

The function C<die>s if it could not find a plausible time at all.
If DEMAND_ACCURACY is supplied and true then it will also die if it
could not find an accurate answer, instead of returning with C<undef>
for the inaccuracy bound.

Both return values are in the form of C<Math::BigRat> objects.  This
retains full resolution, is future-proof, and is easy to manipulate,
but beware that C<Math::BigRat> is currently rather slow.  If performance
is a problem then consider using one of the functions below that return
the results in other formats.

=cut

my $rat_last_dayno = BIGRAT_ZERO;
my $rat_mn_s = BIGRAT_ZERO;

sub now_tai_rat(;$) {
	my($dayno, $secs, $bound) = now_utc_rat($_[0]);
	if($dayno != $rat_last_dayno) {
		$rat_mn_s = utc_to_tai($dayno, BIGRAT_ZERO);
		$rat_last_dayno = $dayno;
	}
	return ($rat_mn_s + $secs, $bound);
}

=item now_tai_gsna([DEMAND_ACCURACY])

This performs exactly the same operation as C<now_tai_rat>, but
returns the results in a different form.  The time since the epoch
and the inaccuracy bound (if present) are each returned in the form
of a four-element array, giving a high-resolution fixed-point number
of seconds.  The first element is the integral number of gigaseconds,
the second is an integral number of seconds in the range [0, 1000000000),
the third is an integral number of nanoseconds in the same range, and
the fourth is an integral number of attoseconds in the same range.

This form of return value is fairly efficient.  It is convenient for
decimal output, but awkward to do arithmetic with.  Its resolution is
adequate for the foreseeable future, but could in principle be obsoleted
some day.

The number of gigaseconds will exceed 1000000000, thus violating
the intent of the number format, one exasecond after the epoch,
when the universe is around three times the age it had at the epoch.
Terra (and thus TAI) might still exist then, depending on how much
its orbital radius increases before Sol enters its red giant phase.
In that situation the number of gigaseconds will simply continue to
increase, ultimately overflowing if native integer formats don't grow,
though it's a good bet that they will.

The inaccuracy bound describes the actual time represented in the
return value, not an internal value that was rounded to generate the
return value.

=cut

my $gsna_last_dayno = 0;
my($gsna_mn_g, $gsna_mn_s) = (0, 0);

sub now_tai_gsna(;$) {
	my($dayno, $secs, $bound) = now_utc_sna($_[0]);
	if($dayno != $gsna_last_dayno) {
		my $midnight = utc_to_tai(Math::BigRat->new($dayno),
					  BIGRAT_ZERO);
		$gsna_mn_g = ($midnight / 1000000000)->bfloor->numify;
		$gsna_mn_s = ($midnight % 1000000000)->numify;
		$gsna_last_dayno = $dayno;
	}
	my($g, $s) = ($gsna_mn_g, $gsna_mn_s);
	$s += $secs->[0];
	if($s >= 1000000000) {
		$g++;
		$s -= 1000000000;
	}
	$bound = [ 0, @$bound ] if defined $bound;
	return ([ $g, $s, @{$secs}[1, 2] ], $bound);
}

=item now_tai_flt([DEMAND_ACCURACY])

This performs exactly the same operation as C<now_tai_rat>, but returns
the results as Perl floating point numbers.  This form of return value
is very efficient and easy to manipulate.  However, its resolution is
limited, rendering it already obsolete for high-precision applications
at the time of writing.

The inaccuracy bound describes the actual time represented in the
return value, not an internal value that was rounded to generate the
return value.

=cut

my $flt_last_dayno = 0;
my $flt_mn_s = 0;
my $flt_add_bound = 0;

sub now_tai_flt(;$) {
	my($dayno, $secs, $bound) = now_utc_flt($_[0]);
	if($dayno != $flt_last_dayno) {
		$flt_mn_s = utc_to_tai(Math::BigRat->new($dayno), BIGRAT_ZERO)
				->numify;
		# Part of the precision of the number of seconds within
		# the day will be lost due to it being moved down the
		# significand to line up with the seconds derived from
		# the day number.  Not trusting floating-point rounding,
		# presume the maximum possible additional error to be 1
		# ulp of the final value.  That's 1 ulp of ($flt_mn_s +
		# 86400) at the end of the day; possibly 0.5 ulp of that
		# at the start of the day (if $flt_mn_s is just below an
		# exponent boundary), but using the larger value all day
		# will be fine.
		my(undef, $mn_exp, undef) = float_parts($flt_mn_s + 86400.0);
		$flt_add_bound = mult_pow2(significand_step, $mn_exp);
		$flt_last_dayno = $dayno;
	}
	$bound += $flt_add_bound if defined $bound;
	return ($flt_mn_s + $secs, $bound);
}

=back

=head1 SEE ALSO

L<Time::TAI>,
L<Time::UTC::Now>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2009, 2010 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

package Time::Precise;

require Exporter;
use Carp;
use Config;
use strict;
use Time::HiRes;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $PRECISION );
use subs qw(localtime gmtime time sleep );
$VERSION   = '1.0012';

@ISA    = qw(Exporter);
@EXPORT = qw(time localtime gmtime sleep timegm timelocal is_valid_date is_leap_year time_hashref gmtime_hashref get_time_from get_gmtime_from localtime_ts gmtime_ts);

$PRECISION = 7;
my @MonthDays = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
my $month_duration = {
	1	=> 31,
	2	=> 28,
	3	=> 31,
	4	=> 30,
	5	=> 31,
	6	=> 30,
	7	=> 31,
	8	=> 31,
	9	=> 30,
	10	=> 31,
	11	=> 30,
	12	=> 31,
};

# Determine breakpoint for rolling century
#my $ThisYear    = ( localtime() )[5];
#my $Breakpoint  = ( $ThisYear + 50 ) % 100;
#my $NextCentury = $ThisYear - $ThisYear % 100;
#$NextCentury += 100 if $Breakpoint < 50;
#my $Century = $NextCentury - 100;
my $SecOff  = 0;

my ( %Options, %Cheat );

use constant SECS_PER_MINUTE => 60;
use constant SECS_PER_HOUR   => 3600;
use constant SECS_PER_DAY    => 86400;

my $MaxDay;
if ($] < 5.012000) {
    my $MaxInt;
    if ( $^O eq 'MacOS' ) {
        # time_t is unsigned...
        $MaxInt = ( 1 << ( 8 * $Config{ivsize} ) ) - 1;
    }
    else {
        $MaxInt = ( ( 1 << ( 8 * $Config{ivsize} - 2 ) ) - 1 ) * 2 + 1;
    }

    $MaxDay = int( ( $MaxInt - ( SECS_PER_DAY / 2 ) ) / SECS_PER_DAY ) - 1;
}
else {
    # recent localtime()'s limit is the year 2**31
    $MaxDay = 365 * (2**47); # Supported at least on 5.014 x64
}

# Determine the EPOC day for this machine
my $Epoc = 0;
if ( $^O eq 'vos' ) {
    # work around posix-977 -- VOS doesn't handle dates in the range
    # 1970-1980.
    $Epoc = _daygm( 0, 0, 0, 1, 0, 70, 4, 0 );
}
elsif ( $^O eq 'MacOS' ) {
    $MaxDay *=2 if $^O eq 'MacOS';  # time_t unsigned ... quick hack?
    # MacOS time() is seconds since 1 Jan 1904, localtime
    # so we need to calculate an offset to apply later
    $Epoc = 693901;
    $SecOff = timelocal( localtime(0)) - timelocal( gmtime(0) ) ;
    $Epoc += _daygm( gmtime(0) );
}
else {
    $Epoc = _daygm( gmtime(0) );
}

%Cheat = ();    # clear the cache as epoc has changed

sub time () {
	sprintf '%0.'.$PRECISION.'f', Time::HiRes::time();
}

sub _localtime {
	my $gm = shift;
	my $arg = $_[0];
	if ($arg < 0) {
		croak "Negative seconds require a Perl version >= 5.012" unless $] >= 5.012;
	}
	$arg = time unless defined $arg;
	$arg = sprintf '%.'.$PRECISION.'f', $arg;
	my ($seconds, $microseconds) = split /\./, $arg;
	if (wantarray) {
		my @lt = $gm ? CORE::gmtime($arg) : CORE::localtime($arg);
		$lt[0] .= ".$microseconds" if $PRECISION;
		$lt[5] += 1900;
		return @lt;
	} else {
		my $str = $gm ? scalar CORE::gmtime($arg) : scalar CORE::localtime($arg);
		$str = 0 unless defined $str;
		$str =~ s/(\d{2}:\d{2}:\d{2}) (\d{4})/$PRECISION ? "$1.$microseconds $2" : "$1 $2"/e;
		$str;
	}
}

sub localtime (;$) { # Precise localtime: always use full year format.
	unshift @_, 0;
	goto &_localtime;
}

sub gmtime (;$) { # Precise localtime: always use full year format.
	unshift @_, 1;
	goto &_localtime;
}

sub sleep {
	my $t = shift;
	Time::HiRes::sleep($t);
}

sub _daygm {

    # This is written in such a byzantine way in order to avoid
    # lexical variables and sub calls, for speed
	return $_[3] + (
        $Cheat{ pack( 'ss', @_[ 4, 5 ] ) } ||= do {
			my $month = ( $_[4] + 10 ) % 12;
            my $year  = $_[5] - int($month / 10);
			( 
				( 365 * $year )
				+ int( $year / 4 )
				- int( $year / 100 )
				+ int( $year / 400 )
				+ int( ( ( $month * 306 ) + 5 ) / 10 )
			) - $Epoc;
        }
    );
}

sub _timegm {
    my $sec =
        $SecOff + $_[0] + ( SECS_PER_MINUTE * $_[1] ) + ( SECS_PER_HOUR * $_[2] );

    return $sec + ( SECS_PER_DAY * &_daygm );
}

sub timegm {
    my ( $sec, $min, $hour, $mday, $month, $year ) = @_;
	($sec, my $microsec) = split /\./, sprintf '%.'.$PRECISION.'f', $sec;
   unless ( $Options{no_range_check} ) {
        croak "Month '$month' out of range 0..11"
            if $month > 11
            or $month < 0;

	my $md = $MonthDays[$month];
        ++$md
            if $month == 1 && _is_leap_year( $year );

        croak "Day '$mday' out of range 1..$md"  if $mday > $md or $mday < 1;
        croak "Hour '$hour' out of range 0..23"  if $hour > 23  or $hour < 0;
        croak "Minute '$min' out of range 0..59" if $min > 59   or $min < 0;
        croak "Second '$sec' out of range 0..59" if $sec > 59   or $sec < 0;
    }

    my $days = _daygm( undef, undef, undef, $mday, $month, $year );

    unless ($Options{no_range_check} or abs($days) < $MaxDay) {
        my $msg = '';
        $msg .= "Day too big - $days > $MaxDay\n" if $days > $MaxDay;

        $msg .=  "Cannot handle date ($sec, $min, $hour, $mday, $month, $year)";

	croak $msg;
    }

    my $fix = 0;
	$fix -= 60*60*24 if ($year < 0 and not _is_leap_year($year));
	return ($sec
           + $SecOff
           + ( SECS_PER_MINUTE * $min )
           + ( SECS_PER_HOUR * $hour )
           + ( SECS_PER_DAY * $days )
		   + $fix).".$microsec";
}

sub _is_leap_year {
    return 0 if $_[0] % 4;
    return 1 if $_[0] % 100;
    return 0 if $_[0] % 400;
    return 1;
}

sub timegm_nocheck {
    local $Options{no_range_check} = 1;
    return &timegm;
}

sub timelocal {
    my ($ref_t, $microsec) = split /\./, &timegm;
	$ref_t += 60*60*24 if ($_[5] < 0 and not _is_leap_year($_[5]));
    my $loc_for_ref_t = _timegm( localtime($ref_t) );

    my $zone_off = $loc_for_ref_t - $ref_t
        or return "$loc_for_ref_t.$microsec";

    # Adjust for timezone
    my $loc_t = $ref_t - $zone_off;

    # Are we close to a DST change or are we done
    my $dst_off = $ref_t - _timegm( localtime($loc_t) );

    # If this evaluates to true, it means that the value in $loc_t is
    # the _second_ hour after a DST change where the local time moves
    # backward.
    if ( ! $dst_off &&
         ( ( $ref_t - SECS_PER_HOUR ) - _timegm( localtime( $loc_t - SECS_PER_HOUR ) ) < 0 )
       ) {
        return ''.($loc_t - SECS_PER_HOUR).".$microsec";
    }

    # Adjust for DST change
    $loc_t += $dst_off;

    return "$loc_t.$microsec" if $dst_off > 0;

    # If the original date was a non-extent gap in a forward DST jump,
    # we should now have the wrong answer - undo the DST adjustment
    my ( $s, $m, $h ) = localtime($loc_t);
    $loc_t -= $dst_off if $s != $_[0] || $m != $_[1] || $h != $_[2];

    return "$loc_t.$microsec";
}

sub timelocal_nocheck {
    local $Options{no_range_check} = 1;
    return &timelocal;
}

sub is_valid_date {
	my ($year, $month, $day) = @_;
	return 0 unless ($year =~ /^\d+$/ and $month =~ /^\d+$/ and $day =~ /^\d+$/);
	$year += 0;
	$month += 0;
	$day += 0;
	return 0 unless $year;
	return 0 if ($month < 1 or $month > 12);
	return 0 if $day < 1;
	if ($month == 2) {
		if (is_leap_year($year)) {
			return 0 if $day > 29;
		} else {
			return 0 if $day > 28;
		}
	} else {
		return 0 if $day > $month_duration->{$month};
	}
	return 1;
}

sub is_leap_year {
	_is_leap_year(shift);
}

sub time_hashref (;$) {
	_time_hashref(shift);
}

sub gmtime_hashref (;$) {
	_time_hashref(shift, 1);
}

sub localtime_ts (;$) {
	my $t = _time_hashref(shift);
  "$t->{year}-$t->{month}-$t->{day} $t->{hour}:$t->{minute}:$t->{second}";
}

sub gmtime_ts (;$) {
	my $t = _time_hashref(shift, 1);
  "$t->{year}-$t->{month}-$t->{day} $t->{hour}:$t->{minute}:$t->{second}";
}

sub _time_hashref {
	my $time = shift;
	my $gmt = shift;
	$time = time() unless defined $time;
	my @lt = $gmt ? gmtime(int $time) : localtime(int $time);
	(my $microseconds = sprintf '%0.'.$PRECISION.'f', ($time - int $time)) =~ s/^.+\.//;
	return {
		second			=> sprintf("%02d.$microseconds", $lt[0]),
		minute			=> sprintf("%02d", $lt[1]),
		hour			=> sprintf("%02d", $lt[2]),
		day				=> sprintf("%02d", $lt[3]),
		month			=> sprintf("%02d", ($lt[4] + 1)),
		year			=> sprintf("%04d", $lt[5]),
		wday			=> $lt[6],
		yday			=> $lt[7],
		isdst			=> $lt[8],
		is_leap_year	=> is_leap_year($lt[5]),
	};
}

sub get_time_from {
	_get_time_from('', @_);
}

sub get_gmtime_from {
	_get_time_from(1, @_);
}

sub _get_time_from {
	my @call = caller;
	my $gm = shift;
	die("get_time_from expects name => value optional parameters (day, month, year, hour, minute, second) at $call[1] line $call[2]\n") if @_ % 2;
	my $time = $gm ? gmtime_hashref : time_hashref;
	my $p = {
		day => $time->{day},
		month => $time->{month},
		year => $time->{year},
		minute => 0,
		hour => 0,
		second => 0,
		@_,
	};
	for my $i (qw(day month year minute hour second)) {
		die("Parameter $i must be numeric at $call[1] line $call[2]\n") unless $p->{$i} =~ /^(-){0,1}\d+(\.\d+){0,1}$/;
	}
	die("Invalid parameter month, out of range 1..12 at $call[1] line $call[2]\n") if ($p->{month} < 1 or $p->{month} > 12);
	for my $i (qw(minute hour second)) {
		die("Invalid parameter $i, out of range '>= 0' and '< 60' at $call[1] line $call[2]\n") unless $p->{$i} >= 0 and $p->{$i} < 60;
	}
	my $max_day = $month_duration->{int $p->{month}} + ((int($p->{month}) == 2) ? is_leap_year($p->{year}) ? 1 : 0 : 0);
	die("Invalid parameter day, out of range 1-$max_day at $call[1] line $call[2]\n") unless $p->{day} >= 1 and $p->{day} <= $max_day;
	$gm ? timegm($p->{second}, $p->{minute}, $p->{hour}, $p->{day}, $p->{month}-1, $p->{year}) : timelocal($p->{second}, $p->{minute}, $p->{hour}, $p->{day}, $p->{month}-1, $p->{year});
}

1;

__END__

=pod

=head1 NAME

Time::Precise - Extending standard time related functions to always include nanoseconds and always use full year.

=head1 SYNOPSIS

This module extends standard functions C<time>, C<localtime>, C<gmtime> and C<sleep> to include nanoseconds as a decimal part of the seconds element.
It also implements and includes functions forked from L<Time::Local> to work with nanoseconds too, altering its functions
C<timelocal> and C<timegm>. It also includes a few extra helper functions described bellow.

B<Note that this module won't affect any other code or modules, it will only affect the standard functions where it is explicitly C<use>d.>

  use Time::Precise;
  
  # ...or, if you don't want anything exported by default:
  use Time::Precise ();
  
  # ...or, to import only a certain function:
  use Time::Precise qw(time localtime);
  
  # Time in seconds, but includes nanoseconds. (e.g. 1444217081.0396979)
  my $time = time;
  
  # Localtime includes nanoseconds too. (e.g. Wed Oct  7 06:25:44.0032990 2015)
  my $localtime = localtime;
  
  # Same applies here accordingly:
  my @localtime = localtime;
  
  # Sleep for a second and a half:
  sleep 1.5;
  
  # Use functions from Time::Local as normal, but they will work with nanoseconds:
  my $seconds = timelocal @localtime;

=head1 EXPORT

Functions exported by default: C<time>, C<localtime>, C<gmtime>, C<sleep>, C<timegm>, C<timelocal>, C<is_valid_date>,
C<is_leap_year>, C<time_hashref>, C<gmtime_hashref>, C<get_time_from>, C<get_gmtime_from>, C<localtime_ts>, C<gmtime_ts>.

=head1 $Time::Precise::PRECISION

$Time::Precise::PRECISION is set by default to 7 and it refers to the number of decimals used for nanoseconds. You
can set it to anything else if you want, but generally speaking, setting it to more than 7 will most likely just add
zeros to the right (at least in all systems where I've tried it).

This is currently a global setting, so be careful not to alter it if that can cause other packages using this module
to expect a different number of decimals. A solution to this when you only need to change the precision in a certain
place is to localize it:

  use Time::Precise;
  
  my $time = time; # Will have 7 decimals
  {
    local $Time::Precise::PRECISION = 3;
    my $short = time; # Will have 3 decimals
  }
  $time = time; # Will have 7 decimals again

=head1 Functions

=head2 time, localtime, gmtime

Work just like the regular CORE functions, but specify full year in the response and include nanoseconds as decimals.

=head2 localtime_ts, gmtime_ts

Work just like the regular CORE C<localtime> and C<gmtime> functions, except they will return a timestamp SQL style (e.g. C<2024-11-27 20:25:30.8543219>).

=head2 sleep

Works just like the regular CORE sleep, except it accepts fractions of seconds too, including sleeping for less than a second.

=head2 timegm, timelocal

Work like the corresponding functions from L<Time::Local>, but they are nanoseconds and full-year enabled for both arguments and response.

=head2 is_valid_date($year, $month, $day)

This will return 1 or 0 depending on the date passed being valid.

=head2 is_leap_year($year)

This will return 1 or 0 depending on the year passed being a leap year.

=head2 time_hashref(<$seconds>), gmtime_hashref(<$gmt_seconds>)

This is a variation of C<localtime> and C<gmtime> respectively. It takes an optional C<$seconds> argument or uses the current time if no
argument is passed. It will return a hashref containing the corresponding elements for it. Example:

  {
    day          => "07",
    hour         => "06",
    is_leap_year => 0,
    isdst        => 1,
    minute       => 45,
    month        => 10,
    second       => 34.61739,
    wday         => 3,
    yday         => 279,
    year         => 2015,
  }

=head2 get_time_from(year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second)

=head2 get_gmtime_from(year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second)

This function helps you get the corresponding time in seconds for the specified named arguments. All arguments are optional,
but if you don't specify anything at all, then it will default to the current date at 0:00 hours. Month is 1..12 based.

Example:

  my $time = get_time_from (
    year    => 1975,
    month   => 9,
    day     => 3,
    hour    => 8,
    minute  => 33,
    second  => 12.0067514,
  );
  
  # $time is now 178983192.0067514
  
  my $date = localtime $time;
  
  # $date is now Wed Sep  3 08:33:12.0067514 1975

=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-precise at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Precise>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Time::Precise

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Precise>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Time-Precise>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Time-Precise>

=item * Search CPAN

L<http://search.cpan.org/dist/Time-Precise/>

=back

=head1 SEE ALSO

L<Time::Local>, from which several lines of code have been taken.


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2024 Francisco Zarabozo. Parts taken from L<Time::Local>.

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


require 5.000;

# JulianDay is a package that manipulates dates as day's since 
# some time a long time ago.  It's easy to add and subtract time
# using julian days...  
#
# Usage:
#
#	use Time::JulianDay
#
#	$jd 			  = julian_day($year, $month_1_to_12, $day)
#	($year, $month, $day) 	  = inverse_julian_day($jd)
#	$dow 			  = day_of_week($jd) 
#
#	print (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[$dow];
#
#	$seconds_since_jan_1_1970 = jd_seconds($jd, $hour, $min, $sec)
#	$seconds_since_jan_1_1970 = jd_timelocal($sec,$min,$hours,$mday,$month_0_to_11,$year)
#	$seconds_since_jan_1_1970 = jd_timegm($sec,$min,$hours,$mday,$month_0_to_11,$year)
#
# David Muir Sharnoff <muir@idiom.com>
#
# This based on postings from:
#
# Kurt Jaeger aka PI <zrzr0111@helpdesk.rus.uni-stuttgart.de>
# 	based on postings from: Ian Miller <ian_m@cix.compulink.co.uk>
# Gary Puckering <garyp%cognos.uucp@uunet.uu.net>
#	based on Collected Algorithms of the ACM ?
# jd_timelocal() and jd_timegm() were ripped off from Time::Local, 
#	author unkown by me.
#

package JulianDay;

use Carp;
use Timezone;

@ISA = qw(Exporter);
@EXPORT = qw(julian_day inverse_julian_day day_of_week 
	jd_seconds jd_timelocal jd_timegm);
@EXPORT_OK = qw($brit_jd);

# calculate the julian day, given $year, $month and $day
sub julian_day
{
    my($year, $month, $day) = @_;
    my($tmp);

    $tmp = $day - 32075
      + int(
            1461*($year + 4800 - int(
                                     (
                                      14 - $month
                                     )/12
                                    )
                 )/4
           )
      + int(
            367*($month -2 + int(
                                 (14 - $month
                                 )/12
                                )*12
                )/12
           )
      - int(
            3*(
               (
                $year + 4900 - (
                                14 - $month
                               )/12
               )/100
              )/4
           )
      ;

    return($tmp);

}

sub day_of_week
{
	my ($jd) = @_;
        return (($jd + 1) % 7);       # calculate weekday (0=Sun,6=Sat)
}


# The following defines the first day that the Gregorian calendar was used
# in the British Empire (Sep 14, 1752).  The previous day was Sep 2, 1752
# by the Julian Calendar.  The year began at March 25th before this date.

$brit_jd = 2361222;

# Usage:  ($year,$month,$day) = &inverse_julian_day($julian_day)
sub inverse_julian_day
{
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        carp("warning: julian date $jd pre-dates British use of Gregorian calendar\n")
                if ($jd < $brit_jd);

        $jdate_tmp = $jd - 1721119;
        $y = int((4 * $jdate_tmp - 1)/146097);
        $jdate_tmp = 4 * $jdate_tmp - 1 - 146097 * $y;
        $d = int($jdate_tmp/4);
        $jdate_tmp = int((4 * $d + 3)/1461);
        $d = 4 * $d + 3 - 1461 * $jdate_tmp;
        $d = int(($d + 4)/4);
        $m = int((5 * $d - 3)/153);
        $d = 5 * $d - 3 - 153 * $m;
        $d = int(($d + 5) / 5);
        $y = 100 * $y + $jdate_tmp;
        if($m < 10) {
                $m += 3;
        } else {
                $m -= 9;
                ++$y;
        }
        return ($y, $m, $d);
}

$jd_1970_1_1 = 2440588;

sub jd_seconds
{
	my($jd, $hr, $min, $sec) = @_;

	return ($jd - 2440588) * 86400 + $hr * 3600 + $min * 60 + $sec;
}

# this uses a 0-11 month to correctly reverse localtime()
sub jd_timelocal
{
	my ($sec,$min,$hours,$mday,$mon,$year) = @_;
	$year += 100 if $year < 70;
	$year += 1900 if $year < 1900;
	my $jd = julian_day($year, $mon+1, $mday);
	return jd_seconds($jd, $hours, $min, $sec) - tz_local_offset();
}

# this uses a 0-11 month to correctly reverse gmtime()
sub jd_timegm
{
	my ($sec,$min,$hours,$mday,$mon,$year) = @_;
	$year += 100 if $year < 70;
	$year += 1900 if $year < 1900;
	my $jd = julian_day($year, $mon+1, $mday);
	return jd_seconds($jd, $hours, $min, $sec);
}

1;

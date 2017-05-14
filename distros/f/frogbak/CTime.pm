require 5.000;

# Time::CTime.pm
#
#	Routines to format dates.  They correspond to the libc 
#	routines.
# 
# Usage:
#
#	use Time::CTime
# 	print ctime(time);
#	print asctime(time);
#	print strftime(template, localtime(time)); 
#
# strftime supports a pretty good set of conversions.  
#

#
# David Muir Sharnoff <muir@idiom.com>
#
# the starting point for this package was a 
# posting by Paul Foley <paul@ascent.com> 
#

package CTime;

use Timezone;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ctime asctime strftime);
@EXPORT_OK = qw(asctime_n);

CONFIG: {
    @DoW = 	   qw(Sun Mon Tue Wed Thu Fri Sat);
    @DayOfWeek =   qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    @MoY = 	   qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    @MonthOfYear = qw(January February March April May June 
		      July August September October November December);
  
    $TZ = tz2zone();

    %strftime_conversion = (split("\t",<<''));
	must have leading tab for split
	%	'%'
	a	$DoW[$wday]
	A	$DayOfWeek[$wday]
	b	$MoY[$mon]
	B	$MonthOfYear[$mon]
	c	asctime_n($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst, "")
	d	$mday
	D	sprintf("%02d/%02d/%02d", $mon+1, $mday, $year%100)
	e	sprintf("%2d", $mday);
	h	$MoY[$mon]
	H	sprintf("%02d", $hour)
	I	sprintf("%02d", $hour % 12 || 12)
	j	sprintf("%03d", $yday + 1)
	k	sprintf("%2d", $hour);
	l	sprintf("%2d", $hour % 12 || 12)
	m	$mon+1
	M	sprintf("%02d", $min)
	n	"\n"
	p	$hour > 11 ? "PM" : "AM"
	r	sprintf("%02d:%02d:%02d %s", $hour % 12 || 12, $min, $sec, $hour > 11 ? 'PM' : 'AM')
	R	sprintf("%02d:%02d", $hour, $min)
	S	sprintf("%02d", $sec)
	t	"\t"
	T	sprintf("%02d:%02d:%02d", $hour, $min, $sec)
	U	wkyr(0, $wday, $yday)
	w	$wday
	W	wkyr(1, $wday, $yday)
	y	$year%100
	Y	$year%100 + ( $year%100<70 ? 2000 : 1900)
	Z	$TZ
	x	sprintf("%02d/%02d/%02d", $mon + 1, $mday, $year%100)
	X	sprintf("%02d:%02d:%02d", $hour, $min, $sec)


}

sub asctime_n {
    my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst, $TZname) = @_;
    $year += ($year < 70) ? 2000 : 1900;
    $TZname .= ' ' 
	if $TZname;
    sprintf("%s %s %2d %2d:%02d:%02d %s%4d",
	  $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $TZname, $year);
}

sub asctime
{
    return asctime_n(@_)."\n";
}

# is this formula right?
sub wkyr {
    my($wstart, $wday, $yday) = @_;
    $wday = ($wday + 7 - $wstart) % 7;
    return int(($yday - $wday + 13) / 7 - 1);
}

# ctime($time)

sub ctime {
    my($time) = @_;
    asctime(($TZ eq 'GMT') ? gmtime($time) : localtime($time), $TZ);
}

# strftime($template, @time_struct)
#
# Does not support locales

sub strftime {			
    local($template, $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = @_;

    $template =~ s/%([%aAbBcdDehHIjklmMnprRStTUwWxXyYZ])/$CTime::strftime_conversion{$1}/eeg;
    return $template;
}

1;

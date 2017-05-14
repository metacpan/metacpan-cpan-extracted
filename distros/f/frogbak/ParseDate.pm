
# This routine understands dates/times in the following formats:
#
#   Special forms:
#	Dow Mon dd hh:mm:ss GMT+offset yyyy
#	Dow Mon dd hh:mm:ss yyyy
#	yy/mm/dd.hh:mm
#   Mix'n'match forms:
#	Month day{st,nd,th}, year
#	Mon dd yyyy
#	yyyy/mm/dd
#	yyyy/mm
#	mm/dd/yy
#	mm/yy
#	yy/mm (only if year > 12)
#	yy/mm/dd (only if year > 12)
#	hh:mm:ss 
#	hh:mm 
#	noon
#	midnight
#	hh:mm[AP]M
#	hh[AP]M
#
# Example: 
#
#	($year, $month_1_to_12, $day, $hour, $min, $sec, $offset) 
#		= parse_date("12/11/94 2pm")
#	$seconds_since_epoch = parse2seconds("Mon Jan  2 04:24:27 1995");
#	

require 5.000;

package ParseDate;
use JulianDay;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(parse_date parse2seconds);

CONFIG:	{
	%mtable = qw(
		Jan 1
		January 1
		Feb 2
		Febuary 2
		Mar 3
		March 3
		Apr 4
		April 4
		May 5
		Jun 6
		June 6
		Jul 7
		July 7
		Aug 8
		August 8
		Sep 9
		September 9
		Oct 10
		October 10
		Nov 11
		November 11
		Dec 12
		December 12
	);
}

# returns (year, mon (1-12), day, hour, min, sec, tzoffset(if known))
sub parse_date
{
	my ($t) = @_;

	if ($t =~ m#^(?x)
		    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
		    \s+
		    (\d\d?)
		    \s+
		    (\d\d) : (\d\d) : (\d\d)
		    \s+
		    (\d\d\d\d)
		    #) {
		# Mon dd hh:mm:ss yyyy
		return ($6, $mtable{$1}, $2, $3, $4, $5, undef);
	} elsif ($t =~ m#(?x)
			    (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun)
			    \s+
			    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) 
			    \s+
			    (\d\d?)
			    \s+
			    (\d\d) : (\d\d) : (\d\d)
			    \s+
			    (?:
				GMT\+
				( \d+ ) 
				\s+
			    )?
			    (\d\d\d\d)
			#) {	
		# Dow Mon dd hh:mm:ss [GMT+n] yyyy
		return($7, $mtable{$1}, $2, $3, $4, $5, $6);
	} elsif ($t =~ m#(\d\d)/(\d\d)/(\d\d)\.(\d\d)\:(\d\d)#) {
		# yy/mm/dd.hh:mm
		my $y = $1;
		$y += 100 if ($1 < 70);
		return (1900+$y, $2, $3, $4, $5, 0, undef);
	} 

	my $y, $m, $d;
	my $H, $M, $S;
	if (&parse_date_only(\$t, \$y, \$m, \$d)) {
		&parse_time_only(\$t, \$H, \$M, \$S);
	} elsif (&parse_time_only(\$t, \$H, \$M, \$S)) {
		&parse_date_only(\$t, \$y, \$m, \$d);
	} else {
		return undef;
	}

	$y += 100 if $y < 70;
	$y += 1900 if $y < 1900;

	return ($y, $m, $d, $H, $M, $S, undef);
}

sub parse_date_only
{
	my ($tr, $yr, $mr, $dr) = @_;

	if ($$tr =~ s#^(\d\d\d\d)/(\d\d?)/(\d\d?)\s*##) {
		# yyyy/mm/dd

		($$yr, $$mr, $$dr) = ($1, $2, $3);
		return 1;
	} elsif ($$tr =~ s#^(\d\d\d\d)/(\d\d?)\s+##) {
		# yyyy/mm

		($$yr, $$mr, $$dr) = ($1, $2, 1);
		return 1;
	} elsif ($$tr =~ s#^(?x)
			(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
			\s+
			(\d\d?)
			\s+
			(\d\d\d\d)
			\s*
			##) {
		# Mon dd yyyy
		($$yr, $$mr, $$dr) = ($3, $mtable{$1}, $2);
		return 1;
	} elsif ($$tr =~ s#^(?x)
			(January|Febuary|March|April|May|June|July|
			August|September|October|November|December)
			\s+
			(\d+)
			(?:st|nd|th)
			\,
			\s+
			(\d\d\d\d)
			\s*
			##) {
		# Month day{st,nd,th}, year
		($$yr, $$mr, $$dr) = ($3, $mtable{$1}, $2);
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)/(\d\d?)/(\d\d?)\s*##) {
		if ($1 > 12) {
			# yy/mm/dd
			($$yr, $$mr, $$dr) = ($1, $2, $3);
		} else {
			# mm/dd/yy
			($$yr, $$mr, $$dr) = ($3, $1, $2);
		}
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)/(\d\d?)\s*##) {
		if ($1 > 12) {
			# yy/mm
			($$yr, $$mr, $$dr) = ($1, $2, 1);
		} else {
			# mm/yy
			($$yr, $$mr, $$dr) = ($2, $1, 1);
		}
		return 1;
	} elsif ($$tr =~ s#^today\s*##i) {
	}
	return 0;
}

sub parse_time_only
{
	($tr, $hr, $mr, $sr) = @_;

	if ($$tr =~ s#^(\d\d)\:(\d\d):(\d\d)\s*##) {
		# hh:mm:ss
		($$hr, $$mr, $$sr) = ($1, $2, $3);
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)\:(\d\d)\s*([ap])m\s*##i) {
		# hh:mm[AP]M
		if ("\U$3" eq "P") {
			($$hr, $$mr, $$sr) = ($1 + 12, $2, 0);
		} else {
			($$hr, $$mr, $$sr) = ($1, $2, 0);
		}
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)\:(\d\d)\s*##) {
		# hh:mm
		($$hr, $$mr, $$sr) = ($1, $2, 0);
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)\s*([ap])m\s*##i) {
		# hh:mm[AP]M
		if ("\U$2" eq "P") {
			($$hr, $$mr, $$sr) = ($1 + 12, 0, 0);
		} else {
			($$hr, $$mr, $$sr) = ($1, 0, 0);
		}
		return 1;
	} elsif ($$tr =~ s#noon\s*##i) {
		# noon
		($$hr, $$mr, $$sr) = (12, 0, 0);
		return 1;
	} elsif ($$tr =~ s#midnight\s*##i) {
		# midnight
		($$hr, $$mr, $$sr) = (0, 0, 0);
		return 1;
	} 
	return 0;
}

sub parse2seconds
{
        my ($dt) = @_;
	my ($year, $mon_1_to_12, $day, $hour, $min, $sec, $off) = 
		&parse_date($dt);


	my $thisyear = (gmtime(time))[5];

	$thisyear += 100 if $thisyear < 70;
	$thisyear += 1900 if $thisyear < 1900;

	if ($year != $thisyear && $year != $thisyear + 1) {
		# date is not reasonable
		return undef;
	}
	if ($off) {
		my $gm = jd_timegm($sec,$min,$hours,$mday,$mon-1,$year);
		return undef if ! defined($gm);
		$gm -= $off * 3600;
		return $gm;
	} else {
		return jd_timelocal($sec,$min,$hours,$mday,$mon-1,$year);
	}
}

1;

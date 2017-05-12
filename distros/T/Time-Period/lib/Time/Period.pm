=head1 NAME

Time::Period - A Perl module to deal with time periods.

=head1 SYNOPSIS

C<use Time::Period;>

C<$result = inPeriod($time, $period);>

=head1 DESCRIPTION

The B<inPeriod> function determines if a given time falls within a given
period.  B<inPeriod> returns B<1> if the time does fall within the given
period, B<0> if not, and B<-1> if B<inPeriod> detects a malformed time or
period.

The time is specified as per the C<time()> function, which is assumed to
be the number of non-leap seconds since January 1, 1970.

The period is specified as a string which adheres to the format

	sub-period[, sub-period...]

or the string "none" or whitespace.  The string "none" is not case
sensitive.

If the period is blank, then any time period is assumed because the time
period has not been restricted.  In that case, B<inPeriod> returns 1.  If
the period is "none", then no time period applies and B<inPeriod> returns
0.

A sub-period is of the form

	scale {range [range ...]} [scale {range [range ...]}]

Scale must be one of nine different scales (or their equivalent codes):

	Scale  | Scale | Valid Range Values
	       | Code  |
	*******|*******|************************************************
	year   |  yr   | n     where n is an integer 0<=n<=99 or n>=1970
	month  |  mo   | 1-12  or  jan, feb, mar, apr, may, jun, jul,
	       |       |           aug, sep, oct, nov, dec
	week   |  wk   | 1-6
	yday   |  yd   | 1-366
	mday   |  md   | 1-31
	wday   |  wd   | 1-7   or  su, mo, tu, we, th, fr, sa
	hour   |  hr   | 0-23  or  12am 1am-11am 12noon 12pm 1pm-11pm
	minute |  min  | 0-59
	second |  sec  | 0-59

The same scale type may be specified multiple times.  Additional scales
simply extend the range defined by previous scales of the same type.

The range for a given scale must be a valid value in the form of

	v

or

	v-v

For the range specification v-v, if the first value is larger than the second
value (e.g. "min {20-10}"), the range wraps around unless the scale
specification is year.

Year does not wrap because the year is never really reset, it just
increments.  Ignoring that fact has lead to the dreaded year 2000
nightmare.  When the year rolls over from 99 to 00, it has really rolled
over a century, not gone back a century.  B<inPeriod> supports the
dangerous two digit year notation because it is so rampant.  However,
B<inPeriod> converts the two digit notation to four digits by prepending
the first two digits from the current year.  In the case of 99-1972, the
99 is translated to whatever current century it is (probably 20th), and
then range 99-1972 is treated as 1972-1999.  If it were the 21st century,
then the range would be 1972-2099.

Anyway, if v-v is 9-2 and the scale is month, September, October,
November, December, January, and February are the months that the range
specifies.  If v-v is 2-9, then the valid months are February, March,
April, May, Jun, July, August, and September.  9-2 is the same as Sep-Feb.

v isn't a point in time.  In the context of the hour scale, 9 specifies
the time period from 9:00:00 am to 9:59:59 am.  This is what most people
would call 9-10.  In other words, v is discrete in its time scale.
9 changes to 10 when 9:59:59 changes to 10:00:00, but it is 9 from
9:00:00 to 9:59:59.  Just before 9:00:00, v was 8.

Note that whitespace can be anywhere and case is not important.  Note
also that scales must be specified either in long form (year, month,
week, etc.) or in code form (yr, mo, wk, etc.).  Scale forms may be
mixed in a period statement.

Furthermore, when using letters to specify ranges, only the first two
for week days or the first three for months are significant.  January
is a valid specification for jan, and Sunday is a valid specification
for su.  Sun is also valid for su.

=head2 PERIOD EXAMPLES

To specify a time period from Monday through Friday, 9am to 5pm, use a
period such as

	wd {Mon-Fri} hr {9am-4pm}

When specifing a range by using -, it is best to think of - as meaning
through.  It is 9am through 4pm, which is just before 5pm.

To specify a time period from Monday through Friday, 9am to 5pm on
Monday, Wednesday, and Friday, and 9am to 3pm on Tuesday and Thursday,
use a period such as

	wd {Mon Wed Fri} hr {9am-4pm}, wd{Tue Thu} hr {9am-2pm}

To specify a time period that extends Mon-Fri 9am-5pm, but alternates
weeks in a month, use a period such as

	wk {1 3 5} wd {Mon Wed Fri} hr {9am-4pm}

Or how about a period that specifies winter?

	mo {Nov-Feb}

This is equivalent to the previous example:

	mo {Jan-Feb Nov-Dec}

As is

	mo {jan feb nov dec}

And this is too:

	mo {Jan Feb}, mo {Nov Dec}

Wait!  So is this:

	mo {Jan Feb} mo {Nov Dec}

To specify a period that describes every other half-hour, use something
like

	minute { 0-29 }

To specify the morning, use

	hour { 12am-11am }

Remember, 11am is not 11:00:00am, but rather 11:00:00am - 11:59:59am.

Hmmmm, 5 second blocks could be a fun period...

	sec {0-4 10-14 20-24 30-34 40-44 50-54}

To specify every first half-hour on alternating week days, and the second
half-hour the rest of the week, use the period

	wd {1 3 5 7} min {0-29}, wd {2 4 6} min {30-59}

=head1 VERSION

1.25

=head1 HISTORY

        Version 1.25
        ------------
                - Fixed a bug with matching week on Sundays
                (https://rt.cpan.org/Public/Bug/Display.html?id=100850)

        Version 1.24
        ------------
                - Minor doc update.

        Version 1.23
        ------------
                - Bug fixes:
                    - Validate min and max for right side of hour ranges (e.g.
                      hr { 20-25 } now correctly returns -1)
                    - Range for yd is now 1 to 366
                    - Years are no longer considered to be 365 days long for
                      calculating a 4-digit year.

        Version 1.22
        ------------
                - Fixed tests

        Version 1.21
        ------------
                - Bug fix: Stopped using $' and $`.

	Version 1.20
	------------
		- Added the ability to specify no time period.

	Version 1.13
	------------
		- Cleaned up the error checking code.

	Version 1.12
	------------
		- Updated email and web space information.

	Version 1.11
	------------
		- Minor bug fix in 1.10.

	Version 1.10
	------------
		- Released.

=head1 AUTHOR

Patrick Ryan <perl@pryan.org> wrote it.

Paul Boyd <pboyd@cpan.org> fixed a few bugs.

=head1 COPYRIGHT

Copyright (c) 1997 Patrick Ryan.  All rights reserved.  This Perl module
uses the conditions given by Perl.  This module may only be distributed
and or modified under the conditions given by Perl.

=cut

package Time::Period;

require 5.001;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(inPeriod);

$VERSION = "1.25";

sub inPeriod {

  my($time, $period) = @_[0,1];
  my(%scaleCode, %scaleCodeV, $result, $i, $lb, $rb, @subPeriods, $subPeriod,
     @scales, %scaleResults, $rangeData, @ranges, $range, $v1, $v2);
  local($scale, $yr, $mo, $wk, $yd, $md, $wd, $hr, $min, $sec);

  # $scale, $yr, $mo, $wk, $yd, $md, $wd, $hr, $min, and $sec are declared
  # with local() because they are referenced symbolically.


  # Test $period and $time for validity.  Return -1 if $time contains
  # non-numbers or is null.  Return 1 if $time is numeric but $period is all
  # whitespace.  No period means all times are within the period because
  # period is not restricted.  Return 0 if $period is "none".  Also make
  # $period all lowercase.

  $time =~ s/^\s*(.*)/$1/;
  $time =~ s/\s*$//;
  return -1 if ( ($time =~ /\D/) || ($time eq "") );

  return 1 if (!defined($period));
  $period =~ s/^\s*(.*)/$1/;
  $period =~ s/\s*$//;
  $period = lc($period);
  return 1 if ($period eq "");

  return 0 if ($period eq "none");

  # Thise two associative arrays are used to map and validate scales.

  %scaleCode = ('year' => 'yr', 'month' => 'mo', 'week' => 'wk', 'mday' => 'md',
                'wday' => 'wd', 'yday' => 'yd', 'hour' => 'hr',
                'minute' => 'min', 'second' => 'sec');
  %scaleCodeV = ('yr' => 1, 'mo' => 1, 'wk' => 1, 'md' => 1, 'wd' => 1,
                 'yd' => 1, 'hr' => 1, 'min' => 1, 'sec' => 1);


  # The names of these variables must correlate with the scale codes.

  ($yr, $mo, $wk, $yd, $md, $wd, $hr, $min, $sec) = getTimeVars($time);


  # The first step is to break $period up into all its sub periods.

  @subPeriods = split(/\s*,\s*/, $period);

  # Evaluate each sub-period to see if $time falls within it.  If it does
  # then return 1, if $time does not fall within any of the sub-periods,
  # return 0.

  foreach $subPeriod (@subPeriods) {

    # Do a validity check for braces.  Make sure the number of {s equals the
    # number of }s.  If there aren't any, return -1 as well.

    $lb = $subPeriod =~ tr/{//;
    $rb = $subPeriod =~ tr/}//;
    return -1 if ( ($lb != $rb) || ($lb == 0) );


    @scales = split(/}\s*/, $subPeriod);

    # Make sure that the number of {s are equal to the number of scales
    # found.  If it is not, return -1.

    return -1 if ($lb != @scales);


    # Evaluate each scale, one by one, in the sub-period.  Once this
    # completes, there will be a hash called %scaleResults which will contain
    # boolean values.  The key to this hash will be the code version of
    # each scale in @scales, if it was a valid scale.  If an invalid string
    # is found, -1 will be returned.  The boolean value will indicate
    # whether $time falls within the particular scale in question.

    foreach $scale (@scales) {
      return -1 if ($scale !~ /^([a-z]*)\s*{\s*(.*)/);
      $scale = $1;
      $rangeData = $2;

      # Check to see if $scale is a valid scale.  If it is, make sure
      # it is in code form.

      # Is it possibly the long form?
      if (length($scale) > 3) {
        # If it doesn't map to a code...
        return -1 if (!defined($scaleCode{$scale}));
        $scale = $scaleCode{$scale};
      # Okay, it's not longer than 3 characters, is it 2 or 3 characters long?
      } elsif (length($scale) > 1) {
        # Is it an invalid code?
        return -1 if (!defined($scaleCodeV{$scale}));
      # It must be zero or one character long, which is an invalid scale.
      } else {
        return -1;
      }

      # $scale is a valid scale and it is now in code form.

      # Erase any whitespace between any "v - v"s so that they become "v-v".
      $rangeData =~ s/(\w+)\s*-\s*(\w+)/$1-$2/g;

      @ranges = split(/\s+/, $rangeData);

      $scaleResults{$scale} = 0 if (!defined($scaleResults{$scale}));

      # Alright, $range is one of the ranges (could be the only one) for
      # $scale.  If $range is valid within the context of $scale and $time,
      # set $scaleResults{$scale} to 1.

      foreach $range (@ranges) {

        if ($range =~ /(.*)-(.*)/) {
          $v1 = $1;
          $v2 = $2;
          return -1 if ($v1 !~ /\w/ || $v2 !~ /\w/);
        } else {
          return -1 if ($range !~ /\w/);
        }

        # This line calls the function named by $scale and feeds it the
        # variable $range and the variable named by $scale.

        $result = &$scale($range, $$scale);

        return -1 if ($result == -1);
        $scaleResults{$scale} = 1 if ($result == 1);
      }
    }

    # Now, there is a boolean value associated with each scale.  If every
    # scale is 1, then $time falls within this sub-period, which means $time
    # falls within the period, so return 1.  If that condition isn't met,
    # then the loop will test other sub-periods, if they exist, and return 0
    # if none of them cover $time.

    $i = 1;
    foreach $scale (keys %scaleResults) {
      $i = 0 if ($scaleResults{$scale} == 0);
    }

    # This is a sub-period where the time falls into all of the scales
    # specified.
    return 1 if ($i == 1);

    # Reset scale for a new sub-period.
    %scaleResults = ();
  }

  # $time didn't fall into any of the sub-periods.  :(

  return 0;
}

sub getTimeVars {
  # This function takes $time (seconds past 0000 Jan 1, 1970) and returns
  # it in component form.  Specifically, this function returns
  # ($year, $month, $week, $yday, $mday, $wday, $hour, $minute, $second).

  my($time) = $_[0];
  my($sec, $min, $hr, $md, $mo, $yr, $wd, $yd, @pwd, @wd, $wk, $i);


  # Now, break $time into $yr, $mo, $wk, $md, $wd, $yd, $hr, $min, and $sec.

  ($sec, $min, $hr, $md, $mo, $yr, $wd, $yd) = localtime($time);

  # The assumption for the ranges from localtime are
  #   Year      ($yr)  = 0-99
  #   Month     ($mo)  = 0-11
  #   Year Day  ($yd)  = 0-365
  #   Month Day ($md)  = 1-31
  #   Week Day  ($wd)  = 0-6
  #   Hour      ($hr)  = 0-23
  #   Minute    ($min) = 0-59
  #   Second    ($sec) = 0-59

  # Calculate the full year (yyyy).
  $yr += 1900;

  # Figure out which week $time is in ($wk) so that $wk goes from 0-5.

  # Set up an array where a week day maps to the previous week day.
  @pwd = (6, 0, 1, 2, 3, 4, 5);

  # Define an array @wd from 1 to $md that maps $md to its corresponding
  # day of the week.

  $wd[$md] = $wd;
  for ($i = $md - 1; $i >= 0; $i--) {
    $wd[$i] = $pwd[$wd[$i+1]];
  }


  # Calculate which week it is.

  $wk = 0;

  for ($i = 1; $i <= $md; $i++) {
    # Itterate $i from 1 to $md.  If $i happens to land on a Sunday,
    # increment $wk unless $i is also 1, which means its still week 0.
    if ( $wd[$i] == 0 && $i != 1 ) {
      $wk++;
    }
  }

  return ($yr, $mo, $wk, $yd, $md, $wd, $hr, $min, $sec);
}

sub yr {
  # A function to determine if a given range is within a given year.
  # Returns 1 if it is, 0 if not, and -1 if the supplied range is invalid.

  my($range, $yr) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    return -1 if ( ($v1 =~ /\D/) || ($v2 =~ /\D/) );
    return -1 if ( ($v1 < 0) || ($v2 < 0) );
    return -1 if ( ($v1 > 99) && ($v1 < 1970) );
    return -1 if ( ($v2 > 99) && ($v2 < 1970) );
    $v1 = (100 * substr($yr, 0, 2) + $v1) if ($v1 <= 99);
    $v2 = (100 * substr($yr, 0, 2) + $v2) if ($v2 <= 99);
    if ($v1 > $v2) {
      $i = $v2;
      $v2 = $v1;
      $v1 = $i;
    }

    return 1 if ( ($v1 <= $yr) && ($yr <= $v2) );
  } else {
    return -1 if ( ($range =~ /\D/) || ($range < 0) ||
                   ( ($range > 99) && ($range < 1970) ) );
    $range = (100 * substr($yr, 0, 2) + $range) if ($range <= 99);

    return 1 if ($range == $yr);
  }

  return 0;
}

sub mo {
  # A function to determine if a given range is within a given month.
  # Returns 1 if it is, 0 if not, and -1 if the supplied range is invalid.

  my($range, $mo) = @_[0,1];
  my(%mo, %moV, $v1, $v2);

  # These associative arrays are used to validate months and to map the
  # letter designations to their numeric equivalents.

  %mo =  ('jan' => 0, 'feb' => 1, 'mar' => 2, 'apr' => 3, 'may' => 4,
          'jun' => 5, 'jul' => 6, 'aug' => 7, 'sep' => 8, 'oct' => 9,
          'nov' => 10, 'dec' => 11);
  %moV = ('jan' => 1, 'feb' => 1, 'mar' => 1, 'apr' => 1, 'may' => 1,
          'jun' => 1, 'jul' => 1, 'aug' => 1, 'sep' => 1, 'oct' => 1,
          'nov' => 1, 'dec' => 1);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    if ($v1 =~ /[a-z]/) {
      $v1 = substr($v1, 0, 3);
      return -1 if (!defined($moV{$v1}));
      $v1 = $mo{$v1};
    } elsif ($v1 =~ /\D/) {
      return -1;
    } else {
      $v1--;
      return -1 if ( ($v1 < 0) || ($v1 > 11) );
    }
    if ($v2 =~ /[a-z]/) {
      $v2 = substr($v2, 0, 3);
      return -1 if (!defined($moV{$v2}));
      $v2 = $mo{$v2};
    } elsif ($v2 =~ /\D/) {
      return -1;
    } else {
      $v2--;
      return -1 if ( ($v2 < 0) || ($v2 > 11) );
    }
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $mo) || ($v2 >= $mo) );
    } else {
      return 1 if ( ($v1 <= $mo) && ($mo <= $v2) );
    }
  } else {
    if ($range =~ /[a-z]/) {
      $range = substr($range, 0, 3);
      return -1 if (!defined($moV{$range}));
      $range = $mo{$range};
    } elsif ($range =~ /\D/) {
      return -1;
    } else {
      $range--;
      return -1 if ( ($range < 0) || ($range > 11) );
    }
    return 1 if ($range == $mo);
  }

  return 0;
}

sub wk {
  # A function to determine if a given range is within a given week.
  # Returns 1 if it is, 0 if not, and -1 if the supplied range is invalid.

  my($range, $wk) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    return -1 if ( ($v1 =~ /\D/) || ($v2 =~ /\D/) );
    $v1--;
    $v2--;
    return -1 if ( ($v1 < 0) || ($v1 > 5) );
    return -1 if ( ($v2 < 0) || ($v2 > 5) );
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $wk) || ($v2 >= $wk) );
    } else {
      return 1 if ( ($v1 <= $wk) && ($wk <= $v2) );
    }
  } else {
    return -1 if ($range =~ /\D/);
    $range--;
    return -1 if ( ($range < 0) || ($range > 5) );
    return 1 if ($range == $wk);
  }

  return 0;
}

sub yd {
  # A function to determine if a given range is within a given day of the
  # year.  Returns 1 if it is, 0 if not, and -1 if the supplied range is
  # invalid.

  my($range, $yd) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    return -1 if ( ($v1 =~ /\D/) || ($v2 =~ /\D/) );
    $v1--;
    $v2--;
    return -1 if ( ($v1 < 0) || ($v1 > 365) );
    return -1 if ( ($v2 < 0) || ($v2 > 365) );
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $yd) || ($v2 >= $yd) );
    } else {
      return 1 if ( ($v1 <= $yd) && ($yd <= $v2) );
    }
  } else {
    $range--;
    return -1 if (($range =~ /\D/) || ($range < 0) || ($range > 365));
    return 1 if ($range == $yd);
  }

  return 0;
}

sub md {
  # A function to determine if a given range is within a given day of the
  # month.  Returns 1 if it is, 0 if not, and -1 if the supplied range is
  # invalid.

  my($range, $md) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    return -1 if ( ($v1 =~ /\D/) || ($v2 =~ /\D/) );
    return -1 if ( ($v1 < 1) || ($v1 > 31) );
    return -1 if ( ($v2 < 1) || ($v2 > 31) );
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $md) || ($v2 >= $md) );
    } else {
      return 1 if ( ($v1 <= $md) && ($md <= $v2) );
    }
  } else {
     return -1 if (($range =~ /\D/) || ($range < 1) || ($range > 31));
     return 1 if ($range == $md);
  }

  return 0;
}

sub wd {
  # A function to determine if a given range is within a given day of the
  # week.  Returns 1 if it is, 0 if not, and -1 if the supplied range is
  # invalid.

  my($range, $wd) = @_[0,1];
  my(%wd, %wdV, $v1, $v2);

  # These associative arrays are used to validate week days and to map the
  # letter designations to their numeric equivalents.

  %wd =  ('su' => 0, 'mo' => 1, 'tu' => 2, 'we' => 3, 'th' => 4, 'fr' => 5,
          'sa' => 6);
  %wdV = ('su' => 1, 'mo' => 1, 'tu' => 1, 'we' => 1, 'th' => 1, 'fr' => 1,
          'sa' => 1);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    if ($v1 =~ /[a-z]/) {
      $v1 = substr($v1, 0, 2);
      return -1 if (!defined($wdV{$v1}));
      $v1 = $wd{$v1};
    } elsif ($v1 =~ /\D/) {
      return -1;
    } else {
      $v1--;
      return -1 if ( ($v1 < 0) || ($v1 > 6) );
    }
    if ($v2 =~ /[a-z]/) {
      $v2 = substr($v2, 0, 2);
      return -1 if (!defined($wdV{$v2}));
      $v2 = $wd{$v2};
    } elsif ($v2 =~ /\D/) {
      return -1;
    } else {
      $v2--;
      return -1 if ( ($v2 < 0) || ($v2 > 6) );
    }
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $wd) || ($v2 >= $wd) );
    } else {
      return 1 if ( ($v1 <= $wd) && ($wd <= $v2) );
    }
  } else {
    if ($range =~ /[a-z]/) {
      $range = substr($range, 0, 2);
      return -1 if (!defined($wdV{$range}));
      $range = $wd{$range};
    } elsif ($range =~ /\D/) {
      return -1;
    } else {
      $range--;
      return -1 if ( ($range < 0) || ($range > 6) );
    }
    return 1 if ($range == $wd);
  }

  return 0;
}

sub hr {
  # A function to determine if a given range is within a given hour.
  # Returns 1 if it is, 0 if not, and -1 if the supplied range is invalid.

  my($range, $hr) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    if ($v1 =~ /^(\d+)am$/) {
      if ($1 == 12) {
        $v1 = 0;
      } else {
        $v1 = $1;
      }
    } elsif ($v1 =~ /^(\d+)pm$/) {
      if ($1 == 12) {
        $v1 = $1;
      } else {
        $v1 = $1+12;
      }
    } elsif ($v1 =~ /^(\d+)noon$/) {
      return -1 if ($1 != 12);
      $v1 = $1;
    }
    if ($v2 =~ /^(\d+)am$/) {
      if ($1 == 12) {
        $v2 = 0;
      } else {
        $v2 = $1;
      }
    } elsif ($v2 =~ /^(\d+)pm$/) {
      if ($1 == 12) {
        $v2 = $1;
      } else {
        $v2 = $1+12;
      }
    } elsif ($v2 =~ /^(\d+)noon$/) {
      return -1 if ($1 != 12);
      $v2 = $1;
    }
    return -1 if ( ($v1 =~ /\D/) || ($v1 < 0) || ($v1 > 23) );
    return -1 if ( ($v2 =~ /\D/) || ($v2 < 0) || ($v2 > 23) );

    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $hr) || ($v2 >= $hr) );
    } else {
      return 1 if ( ($v1 <= $hr) && ($hr <= $v2) );
    }
  } else {
    if ($range =~ /^(\d+)am$/) {
      if ($1 == 12) {
        $range = 0;
      } else {
        $range = $1;
      }
    } elsif ($range =~ /^(\d+)pm$/) {
      if ($1 == 12) {
        $range = $1;
      } else {
        $range = $1+12;
      }
    } elsif ($range =~ /^(\d+)noon$/) {
      return -1 if ($1 != 12);
      $range = $1;
    }
    return -1 if (($range =~ /\D/) || ($range < 0) || ($range > 23));
    return 1 if ($range == $hr);
  }

  return 0;
}

sub min {
  # A function to determine if a given range is within a given minute.
  # Returns 1 if it is, 0 if not, and -1 if the supplied range is invalid.

  my($range, $min) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    return -1 if ( ($v1 =~ /\D/) || ($v2 =~ /\D/) );
    return -1 if ( ($v1 < 0) || ($v1 > 59) );
    return -1 if ( ($v2 < 0) || ($v2 > 59) );
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $min) || ($v2 >= $min) );
    } else {
      return 1 if ( ($v1 <= $min) && ($min <= $v2) );
    }
  } else {
    return -1 if (($range =~ /\D/) || ($range < 0) || ($range > 59));
    return 1 if ($range == $min);
  }

  return 0;
}

sub sec {
  # A function to determine if a given range is within a given second.
  # Returns 1 if it is, 0 if not, and -1 if the supplied range is invalid.

  my($range, $sec) = @_[0,1];
  my($v1, $v2);

  if ($range =~ /(.*)-(.*)/) {
    $v1 = $1;
    $v2 = $2;
    return -1 if ( ($v1 =~ /\D/) || ($v2 =~ /\D/) );
    return -1 if ( ($v1 < 0) || ($v1 > 59) );
    return -1 if ( ($v2 < 0) || ($v2 > 59) );
    if ($v1 > $v2) {
      return 1 if ( ($v1 <= $sec) || ($v2 >= $sec) );
    } else {
      return 1 if ( ($v1 <= $sec) && ($sec <= $v2) );
    }
  } else {
    return -1 if (($range =~ /\D/) || ($range < 0) || ($range > 59));
    return 1 if ($range == $sec);
  }

  return 0;
}

1;

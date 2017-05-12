=head1 NAME

Time::Avail - A Perl module to calculate time availability.

=head1 SYNOPSIS

C<use Time::Avail;>

C<$minRemaining = timeAvailable( $timeStartStr, $timeEndStr, $dayMask );>

=head1 DESCRIPTION

The B<timeAvailable> function compares the time interval specified by
B<timeStartStr>, B<timeEndStr>, and B<dayMask> with the current day and time.
B<timeAvailable> returns B<0 > if the current day and time do not fall within
the specified time interval, otherwise the number of minutes remaining is
returned.  B<timeStartStr> and B<timeEndStr> are string parameters
that must adhere to a B<HH:MM 24 hour> format, where B<HH> represents a two
digit hour value and B<MM> represents a two digit minute value.  B<dayMask> is
a bitmask which specifies the valid days for the time interval.

The B<dayMask> parameter is constructed by OR'ing together one or more of the following dayMask constants:

=over 4

=item *

Time::Avail::DAY_MONDAY

=item *

Time::Avail::DAY_TUESDAY

=item *

Time::Avail::DAY_WEDNESDAY

=item *

Time::Avail::DAY_THURSDAY

=item *

Time::Avail::DAY_FRIDAY

=item *

Time::Avail::DAY_SATURDAY

=item *

Time::Avail::DAY_SUNDAY

=item *

Time::Avail::DAY_WEEKDAY

=item *

Time::Avail::DAY_WEEKEND

=item *

Time::Avail::DAY_EVERYDAY

=back

=head2 EXAMPLES

To calculate the time remaining given a starting time of 5am and an ending time
of 5pm for Sunday and Monday, the call to B<timeAvailable> can be coded as
follows: 

C<$minRemaining = timeAvailable( "05:00", "17:00", Time::Avail::DAY_SUNDAY | Time::Avail::DAY_MONDAY );>


To calculate the time remaining given a starting time of 10:30am and an ending
time of 7:45pm for Saturday, Sunday, and Monday, the call to B<timeAvailable>
can be coded as follows: 

C<$minRemaining = timeAvailable( "10:30", "19:45", Time::Avail::DAY_SATURDAY |  Time::Avail::DAY_SUNDAY |Time::Avail::DAY_MONDAY );>

or

C<$minRemaining = timeAvailable( "10:30", "19:45", Time::Avail::DAY_WEEKEND | Time::Avail::DAY_MONDAY );>


To calculate the time remaining given a starting time of 7am and an ending time
of 7pm for everyday but Saturday and Sunday, the call to B<timeAvailable> can be
coded as follows: 

C<$minRemaining = timeAvailable( "07:00", "19:00", Time::Avail::DAY_WEEKDAY );>


To calculate the time remaining given a starting time of 10pm and an ending time
of 2am for everyday, the call to B<timeAvailable> can be coded as follows: 

C<$minRemaining = timeAvailable( "22:00", "02:00", Time::Avail::DAY_EVERYDAY );>


=head1 VERSION

1.00

=head1 HISTORY

	Version 1.00
	------------
		- Released.

=head1 AUTHOR

Peter Santoro peter@pscomp.com

=head1 COPYRIGHT

Copyright (c) 1998 Peter Santoro.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself; however, you must leave this copyright statement intact.

=head1 DATE

December 19, 1998

=head1 SOURCE

This distribution can be also be found at the author's web site:

	http://www.connix.com/~psantoro/

=cut

package Time::Avail;

# Copyright (c) 1998 Peter Santoro. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself; however, you must leave this copyright
# statement intact.

require 5.003;

use Exporter();
@ISA = qw(Exporter);
@EXPORT = qw( timeAvailable );

use strict;
use integer;
#use diagnostics;

BEGIN
{
*Time::Avail::DAY_MONDAY    = \0x01;
*Time::Avail::DAY_TUESDAY   = \0x02;
*Time::Avail::DAY_WEDNESDAY = \0x04;
*Time::Avail::DAY_THURSDAY  = \0x08;
*Time::Avail::DAY_FRIDAY    = \0x10;
*Time::Avail::DAY_SATURDAY  = \0x20;
*Time::Avail::DAY_SUNDAY    = \0x40;
*Time::Avail::DAY_WEEKDAY   = \0x1C;
*Time::Avail::DAY_WEEKEND   = \0x60;
*Time::Avail::DAY_EVERYDAY  = \0x7C;
*Time::Avail::MIN_PER_DAY   = \1440;
$Time::Avail::VERSION       = "1.00";
}

sub _dayOk($$)
{
# inputs:
#   $dayMask - bitmask specifying days available using above constants
#   $nowDay - today
#
# returns:
#   1 if application is available today
#   0 if application is not available today

   my( $dayMask, $nowDay ) = @_;	# get parameters

   my $dayOk = 0;

   if( ( $nowDay == 0 ) && ( $dayMask & $Time::Avail::DAY_SUNDAY ) )
   {
      $dayOk = 1;
   }
   elsif( ( $nowDay == 1) && ( $dayMask & $Time::Avail::DAY_MONDAY ) )
   {
      $dayOk = 1;
   }
   elsif( ($nowDay == 2) && ( $dayMask & $Time::Avail::DAY_TUESDAY ) )
   {
      $dayOk = 1;
   }
   elsif( ($nowDay == 3)  && ( $dayMask & $Time::Avail::DAY_WEDNESDAY ) )
   {
      $dayOk = 1;
   }
   elsif( ( $nowDay == 4) && ( $dayMask & $Time::Avail::DAY_THURSDAY ) )
   {
      $dayOk = 1;
   }
   elsif( ( $nowDay == 5 ) && ( $dayMask & $Time::Avail::DAY_FRIDAY ) )
   {
      $dayOk = 1;
   }
   elsif( ( $nowDay == 6 ) && ( $dayMask & $Time::Avail::DAY_SATURDAY ) )
   {
      $dayOk = 1;
   }

   $dayOk;
}

sub _timeDiff($$)
{
# inputs:
#   $iStartMin - starting time in minutes
#   $iEndMin - ending time in minutes
#
# returns:
#   difference

   my( $iStartMin, $iEndMin ) = @_; # get parameters

   my $diff = $iEndMin - $iStartMin;

   if( $diff < 0 )
   {
      $diff = $diff + $Time::Avail::MIN_PER_DAY;
   }

   $diff;
}

sub _timeWithin($$$$)
{
# inputs:
#   $nowHour - current hour
#   $nowMin - current minutes
#   $timeStart - string specifying availability start time in HH:MM format
#   $timeEnd - string specifying availability end time in HH:MM format
#
# returns:
#   number of minutes application is available today, a zero value indicates
#   that the application is not currently available

   my( $nowHour, $nowMin, $timeStart, $timeEnd ) = @_; # get parameters

   my $minutesRemaining = 0;
   my( $startHour, $startMin ) = split( /:/, $timeStart );
   my( $endHour, $endMin ) = split( /:/, $timeEnd );

   $startMin = $startMin + ($startHour * 60);
   $endMin = $endMin + ($endHour * 60);
   $nowMin = $nowMin + ($nowHour * 60);

   if( ( $endMin > $startMin ) && ( ($nowMin >= $startMin) && ($nowMin < $endMin) ) )
   {
      $minutesRemaining = _timeDiff( $nowMin, $endMin );
   }
   elsif( $startMin > $endMin )
   {
      if( ( $nowMin >= $startMin ) || ( $nowMin < $endMin ) )
      {
         $minutesRemaining = _timeDiff( $nowMin, $endMin );
      }
   }

   $minutesRemaining;
}

sub timeAvailable($$$)
{
# inputs:
#   $timeStartStr - string specifying availability start time in HH:MM format
#   $timeEndStr - string specifying availability end time in HH:MM format
#   $dayMask - bitmask specifying days available using above constants
#
# returns:
#   number of minutes of available time today, a zero value indicates that
#   there is no time available for today

   my( $timeStartStr, $timeEndStr, $dayMask ) = @_; # get parameters

   my $minutesRemaining = 0;

#  get current time

   my @nowLocalTime = localtime;
   my $nowDay = $nowLocalTime[6];
   my $nowHour = $nowLocalTime[2];
   my $nowMin = $nowLocalTime[1];

   if( _dayOk( $dayMask, $nowDay ) )
   {
      $minutesRemaining = _timeWithin( $nowHour, $nowMin, $timeStartStr, $timeEndStr );
   }

   $minutesRemaining;
}

1;

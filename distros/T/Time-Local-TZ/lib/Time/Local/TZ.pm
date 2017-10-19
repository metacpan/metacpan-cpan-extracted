package Time::Local::TZ;

use 5.008;
use strict;
use warnings;
use base 'Exporter';
use XSLoader;

our $VERSION = '0.04';

our %EXPORT_TAGS = (
    func => [ qw/
        tz_localtime
        tz_timelocal
        tz_truncate
        tz_offset
    / ],
    const => [ qw/
        TM_SEC
        TM_MIN
        TM_HOUR
        TM_MDAY
        TM_MON
        TM_YEAR
        TM_WDAY
        TM_YDAY
        TM_ISDST
    / ],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = [ @EXPORT_OK ];


sub TM_SEC   () { 0 }
sub TM_MIN   () { 1 }
sub TM_HOUR  () { 2 }
sub TM_MDAY  () { 3 }
sub TM_MON   () { 4 }
sub TM_YEAR  () { 5 }
sub TM_WDAY  () { 6 }
sub TM_YDAY  () { 7 }
sub TM_ISDST () { 8 }


XSLoader::load('Time::Local::TZ', $VERSION);

1;
__END__

=head1 NAME

Time::Local::TZ - time converter functions with localtime-based interface

=head1 SYNOPSIS

  use Time::Local::TZ qw/:const :func/;

  # get localtime-like result for given timezone and unixtime
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = tz_localtime("Europe/Moscow" => $epoch);
  ($asctime) = tz_localtime("Europe/Moscow" => 0);      # Thu Jan  1 03:00:00 1970

  # get unixtime for given timezone and localtime data
  $epoch = tz_timelocal("Europe/Moscow" => $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
  $epoch = tz_timelocal("Europe/Moscow" => $sec,$min,$hour,$mday,$mon,$year);    # the same

  # truncate unixtime to the beginning of minute/hour/day/month/year (of course, in given timezone)
  $epoch2 = tz_truncate("Europe/Moscow", $epoch, TM_HOUR());

  # get offset (in seconds) between given timezone and UTC (for the given moment)
  $tz_offset_seconds = tz_offset("Europe/Moscow" => $epoch);
  $tz_offset_seconds = tz_offset("Europe/Moscow");   

  # convert localtime data from one timezone to another
  @localtime_berlin = tz_localtime("Europe/Berlin", tz_timelocal("Europe/Moscow", @localtime_moscow));

  # constants to navigate @localtime (and to use with tz_offset function)
  @localtime = tz_localtime("UTC", $epoch);
  $date_str = sprintf "%04d-%02d-%02d", @localtime[TM_YEAR()+1900, TM_MON()+1, TM_MDAY()];   # 1970-01-01
  $time_str = sprintf "%02d:%02d:%02d", @localtime[TM_HOUR(),      TM_MIN(),   TM_SEC() ];   # 13:25:59
  $weekday = $localtime[ TM_WDAY() ];
  $yearday = $localtime[ TM_YDAY() ];
  $isdst   = $localtime[ TM_ISDST() ];

=head1 DESCRIPTION

This module provides a set of functions to convert time between timezones and do some other timezone-dependant operations.
Most functions work with localtime-like arrays, so they can be easily integrated with other modules supporting this format.
Module is written in XS, so it is fast enough.

=head1 FUNCTIONS

=over 4

=item @localtime = tz_localtime($timezone_name, $epoch)

Works similar to build-in C<localtime> function, but works with timezone you provide, instead of system timezone. Both arguments are mandatory.

In scalar context, C<tz_localtime> returns the C<asctime(3)> value (without trailing C<\n>, like C<localtime>):

  $date_string = tz_localtime("Europe/Moscow" => time());  # e.g., "Thu Apr 27 15:35:34 2017"

In list context, converts time provided to a 9-element list with the time analyzed for the given timezone:

  #  0    1    2     3     4    5     6     7     8
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = tz_localtime("Europe/Moscow" => time);

  @localtime = tz_localtime("Europe/Moscow" => time);
  $date_string = POSIX::strftime("%d %B %Y, %H:%M", @localtime);

Values C<$mday>, C<$year>, C<$wday>, C<$yday> have special format, which can confuse beginners. See C<localtime> function for details.

=item $epoch = tz_timelocal($timezone_name, @localtime)

Works similar to C<timelocal> function from C<Time::Local> module, but works with timezone you provide, instead of system timezone.
Returns unixtime value for the C<localtime> data and timezone provided. All arguments are mandatory, except C<$wday>, C<$yday>, C<$isdst>.

  $epoch = tz_timelocal("Europe/Moscow" => $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
  $epoch = tz_timelocal("Europe/Moscow" => $sec,$min,$hour,$mday,$mon,$year);

  $data_string = "2017-04-27 15:35:34";
  @localtime = POSIX::strptime($data_string, "%Y-%m-%d %H:%M:%S");
  $epoch = tz_timelocal("Europe/Moscow" => @localtime);

=item $epoch = tz_truncate($timezone, $epoch, $unit)

This function calculates C<tz_localtime> for the timezone and unixtime provided, resets fields with index smaller than C<$unit> and calculates unixtime back.
This can be useful to get unixtime for first second of the interval unit (year/month/day/hour/minute) which C<$epoch> belongs to. All arguments are mandatory. 
It is recommended to use C<TM_*> constants from this module to specify C<$unit>.

  $data_string = "1970-03-08 05:25:45";
  @localtime = POSIX::strptime($data_string, "%Y-%m-%d %H:%M:%S");
  $epoch = tz_timelocal("Europe/Moscow" => @localtime);              # 5711145
  
  $epoch2 = tz_truncate("Europe/Moscow" => $epoch, TM_HOUR());       # 5709600
  print tz_localtime("Europe/Moscow" => $epoch2);                    # Sun Mar  8 05:00:00 1970
  
  $epoch2 = tz_truncate("Europe/Moscow" => $epoch, TM_YEAR());       # -10800
  print tz_localtime("Europe/Moscow" => $epoch2);                    # Thu Jan  1 00:00:00 1970
  
  # of course, in other timezones this alignment is wrong:
  print tz_localtime("Europe/Berlin" => $epoch2);                    # Wed Dec 31 22:00:00 1969

=item $offset_seconds = tz_offset($timezone, $epoch)

Calculates offset (in seconds) from UTC to provided timezone, actual for the given unixtime. Both arguments are mandatory.

  print tz_offset("Europe/Moscow", 1293829200); # 10800 (+3 hours for the date 2011-01-01)
  print tz_offset("Europe/Moscow", 1309464000); # 14400 (+4 hours for the date 2011-07-01)

=back

=head2 CONSTANTS

=over 4

=item TM_SEC, TM_MIN, TM_HOUR, TM_MDAY, TM_MON, TM_YEAR, TM_WDAY, TM_YDAY, TM_ISDST 

These constants can be useful to navigate on C<localtime> and C<tz_localtime> arrays:

    @localtime = tz_localtime("Europe/Moscow" => time);
    printf "Time is is %02d:%02d:%02d", @localtime[ TM_HOUR(), TM_MIN(), TM_SEC() ];

It is recommended to use them with C<tz_truncate> function:

  $epoch2 = tz_truncate("Europe/Moscow" => $epoch, TM_HOUR());       # 5709600

=back

=head1 NOTES AND CAVEATS

This module uses your operating system rules to convert time. They are based on environment variable C<TZ> and can differ from OS to OS. Many modern OSes
(including Linux and FreeBSD) support Olson timezone names (like C<Europe/Berlin>, C<America/New_York> etc.), which is the only recommended way to use with
this module. Other OSes usually know only POSIX timezone names. You can deal with them too, but the result can be inconsistent. There is no native Olson db
support in Windows, but CYGWIN solves this.

Please note that set of timezone rules is not something permanent, they are refreshed up to several times per month. So, to get correct results from this
module you should always have fresh timezone information in your OS. If you don't want to do this, take a look on "DateTime::TimeZone", which have its own
timezones database inside. Anyway, you should update it on a regular basis too.

This module works with process environment, so it is not thread-safe.

This module works with mod_perl2 (at least in non-threaded mode). mod_perl2 has problem with C<%ENV>. Unlike mod_perl1 and usual perl programs C<%ENV> under
mod_perl2 is untied from process environment. So, even if you change C<$ENV{TZ}>, built-in functions (like C<localtime>) will know nothing about it, because
real process environment is untouched. This module works with environment bypassing perl C<%ENV>, so in mod_perl2 prefork mode it works fine.

=head1 SEE ALSO

To get more information about "localtime" format, see L<perlfunc/localtime> and L<Time::Local/timelocal>.

If you are interested in useful functions to work with "localtime" data, see L<POSIX/strftime> and L<POSIX::strptime>.

If you want to know more on alternative modules to convert time between timezones, see L<DateTime> and L<DateTime::TimeZone>.

If you want to know more about environment variable C<TZ> and it's formats, you can look at the articles below:
L<http://www.gnu.org/software/libc/manual/html_node/TZ-Variable.html>
L<https://www.ibm.com/developerworks/aix/library/au-aix-posix/>

=head1 SOURCE

The development version is on github at L<https://github.com/bambr/Time-Local-TZ>

=head1 AUTHOR

Sergey Panteleev, E<lt>bambr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Sergey Panteleev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

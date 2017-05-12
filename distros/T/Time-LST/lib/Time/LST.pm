package Time::LST;

use 5.008008;
use strict;
use warnings;
use Astro::Time;
use Carp qw(croak);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = 0.038;
use Exporter qw(import);
@EXPORT = qw(ymdhms2lst datetime2lst filestat2lst now2lst time2lst);
@EXPORT_OK = qw(ymdhms_2_lst datetime_2_lst filestat_2_lst now_2_lst time_2_lst);

=head1 NAME

Time::LST - Convert date/time representations to local sidereal time via Astro-Time and other Date/Time modules

=head1 VERSION

This is documentation for Version 0.038 of Time::LST (2009.09.26).

=head1 SYNOPSIS

  use Time::LST qw(datetime2lst filestat2lst now2lst time2lst ymdhms2lst);
  
  $long = -3.21145; # London, in degrees
  
  $lst_from_string = datetime2lst('1942:8:7T17:00:00', -3.21145, 'BST'); # note approx only for pre-1970
  $data_mod_lst    = filestat2lst('mod', 'valid_path_to_a_file', $long); # or filestat2lst('create', $path, $long)
  $now_as_lst      = time2lst(time(), $long);
  $lst_from_aref   = ymdhms2lst([2006, 11, 21, 12, 15, 0], $long, 'EADT'); # optional timezone

=head1 DESCRIPTION

This is essentially no more than a wrapper to a number of L<Astro::Time|Astro::Time> methods that simplifies conversion into local sidereal time of a datetime representation, such as returned by L<Date::Calc|lib::Date::Calc>), or seconds since the epoch, such as returned by L<time|perlfunc/time>, or L<stat|perlfunc/stat> fields). 

Manditorily, you need to know the longitude (in degrees) of the space relevant to your time.

Give a filepath to get the LST of its last modified time, or readily see what the LST is now. 

Get an accurate representation of the relevant datetime ("now," a given time, or a file's creation or modified time) in so many "seconds since the epoch", taking TimeZone into account.

Optionally, a timezone string in some methods can be helpful for accurately parsing (solar) clock-and-calendar times.

=head1 METHODS

Methods need to be explicitly imported in the C<use> statement. None are exported by default.

All methods expect a longitude, either in I<degrees.decimal> or I<degrees:minutes:seconds> - e.g. -3.21145 (London), 147.333 (Hobart, Tasmania) - or degrees+minutes - e.g., 147:19:58.8 (Hobart). See the L<str2turn|lib::Astro::Time/str2turn> method in the Astro::Time module for valid representations of longitude. Note, however, the degrees, not hours, are here supported.

LST is always returned in the format B<H:M:S>, hours ranging from 0 (12 AM) to 23 (11 PM).

=head2 datetime2lst

 $lst = datetime2lst('1942:12:27:16:04:07', -3.21145, 'BST')

Returns LST on the basis of parsing a datetime string into "seconds since the epoch". 

The first two values to the function are manditory.

Firstly, there should be passed a string in any form parseable by L<Date::Parse|lib::Date::Parse>, e.g., "1995:01:24T09:08:17.1823213"; "21 dec 17:05"; "16 Nov 94 22:28:20 PST". There are system limitations in handling years outside of a certain range. Years less than 1000 will not parse. Years between 1000 and 1969, inclusive, will be rendered as 1970, and those greater than 2037 will be rendered as 2037. (LST deviates by only about 3 minutes from 1970 to 2037).

A second mandatory value to the function is the I<longitude> in degrees.

Then follow non-mandatory values.

A timezone string can be specified as an optional third value for accurate parsing of the datetime string into "seconds since the epoch"; the local timezone is used if this is not specified. Valid representations of Timezone include the likes of "AEDT" and "EST" (parsed by L<Date::Parse|Date::Parse>; i.e., a capital-letter string of 3-5 letters in length), or "Australia/Hobart" (parsed by L<DateTime|DateTime>).

=cut

sub datetime2lst {
   my ($str, $long, $tz) = @_;
   croak __PACKAGE__, '::datetime2lst: Need a datetime string' if !$str;
   require Date::Parse;
   my @ari = Date::Parse::strptime($str);
   croak __PACKAGE__, '::datetime2lst: Check datetime: the sent datetime did not parse' if ! scalar @ari;
   pop @ari;
   $ari[4] += 1;
   $ari[5] += 1900 if $ari[5] < 1000;
   return ymdhms2lst([reverse @ari], $long, $tz);
}
*datetime_2_lst = \&datetime2lst; # Alias

=head2 filestat2lst

 $lst = filestat2lst('create|mod', $path, $long)

Returns LST corresponding to the creation or modification time of a given path. 

First argument equals either 'c' or 'm' (only the first letter is looked-up, case-insensitively). This, respectively, determines access to C<ctime> (element 10) and C<mtime> (element 9) returned by Perl's internal L<stat|perlfunc/stat> function. Note that only modification-time is truly portable across systems; see L<Files and Filesystems in perlport|perlport/Files and Filesystems> (paras 6 and 7). 

The path must be to a "real" file, not a link to a file.

=cut

sub filestat2lst {
   my ($op, $path, $long, $tz) = @_;
   croak __PACKAGE__, '::filestat_2_lst: First argument needs to be create or mod' if $op !~ /^c|m/i;
   croak __PACKAGE__, '::filestat_2_lst: Invalid path to file' if !$path or !-e $path;
   return time2lst( (stat($path))[ $op =~ /^c/i ? 10 : 9 ] , $long, $tz);
}
*filestat_2_lst = \&filestat2lst; # Alias

=head2 now2lst

 $lst = now2lst($long)

Returns local now (as returned by perl's time()) as LST, given longitude in degrees.

Same as going: C<time2lst(time(), $long)>.

=cut

sub now2lst {
    return time2lst(time(), @_);
}
*now_2_lst = \&now2lst;

=head2 ymdhms2lst

 $lst = ymdhms2lst([2006, 8, 21, 12, 3, 0], $long, $timezone)

Returns LST corresponding to a datetime array reference of the following elements:

=for html <p>&nbsp;&nbsp;[<br>&nbsp;&nbsp;&nbsp;year (4-digit <i>only</i>),<br>&nbsp;&nbsp;&nbsp;month-of-year (i.e., <i>n</i>th month (ranging 1-12, or 01-12), not month index as returned by localtime()),<br>&nbsp;&nbsp;&nbsp;day-of-month (1-31 (or 01-31)),<br>&nbsp;&nbsp;&nbsp;hour (0 - 23),<br>&nbsp;&nbsp;&nbsp;minutes,<br>&nbsp;&nbsp;&nbsp;seconds<br>&nbsp;&nbsp;]</p>

Range-checking of these values is performed by Astro::Time itself; digital representations such as "08" or "00" are stripped of leading zeroes for parseability to another module (so there's no need to add them as fillers). Ensure that the year is 4-digit representation.

A value for longitude is required secondary to this datetime array.

A final timezone string - e.g., 'EST', 'AEDT' - is optional. Sending nothing, or an erroneous timezone string, assumes present local timezone. The format is as used by L<Date::Parse|Date::Parse> or L<DateTime|DateTime>; UTC+I<n> format does not parse.

=cut

sub ymdhms2lst {
   my ($ymdhms, $long, $tz) = @_;
   croak __PACKAGE__, '::ymdhms2lst: Need an array reference to calculate LST' if ! ref $ymdhms;
   croak __PACKAGE__, '::ymdhms2lst: Need an array reference of datetime (6 values) to calculate LST' if ! ref $ymdhms eq 'ARRAY' or scalar @{$ymdhms} != 6;

  # Ensure the year is epoch-able:
   if ($ymdhms->[0] < 1970) {
        $ymdhms->[0] = 1970;
        if($ymdhms->[1] == 2 && $ymdhms->[2] == 29) {
            $ymdhms->[2] = 28;
        }
   }
   
   if ($ymdhms->[0] > 2037) {
        $ymdhms->[0] = 2037; 
        if($ymdhms->[1] == 2 && $ymdhms->[2] == 29) {
            $ymdhms->[2] = 28;
        }
   }

   # Some module doesn't like "pseudo-octals" like 08, or 00, but another will need at least a 0; SO:
   my $i;
   for ($i = 0; $i < 6; $i++) {
       $ymdhms->[$i] =~ s/^0+//;
       $ymdhms->[$i] ||= 0;
   }

   my $epoch = _ymdhms2epochsecs($ymdhms, $tz);
   croak __PACKAGE__, '::ymdhms2lst: Check datetime: the sent datetime did not parse' if  ! defined $epoch;
   return time2lst($epoch, $long, $tz); # knock off time, just do the LST conversion
#
}
*ymdhms_2_lst = \&ymdhms2lst;

=head2 time2lst

 $lst = time2lst('1164074032', $long)

Returns LST given seconds since the epoch. If you have a time in localtime format, see L<Time::localtime|Time::localtime> to convert it into the format that can be used with this function.

=cut

sub time2lst {
   my ($time, $long, $tz) = @_;
   croak __PACKAGE__, '::time2lst: Need longitude and time to calculate LST' if !$long || !$time;
   my @time_ari = gmtime($time);
   return _convert(
        [
           ($time_ari[5] + 1900), # year (ISO format)
           ($time_ari[4] + 1),   # month
           $time_ari[3],        # day of month
           @time_ari[2, 1, 0]  # hours, minutes, seconds
        ],
        $long
   );
}
*time_2_lst = \&time2lst; # Alias


sub _ymdhms2epochsecs {
   my ($ymdhms, $tz) = @_;
   
   # Get the epoch seconds of this datetime thing:
   my $epoch;
   #$tz ||= 'local'; # Date::Parse handles localtime more reliably than does DateTime
   if ($tz =~ /^([A-Z]{3,5}|local)$/) { # e.g., 'AEDT', 'BST', 'local'
       require Date::Parse;
	   my $str = join':', (@{$ymdhms}[0 .. 5]); # all 6 els as a string
       $epoch = Date::Parse::str2time($str, $tz);
   }
   elsif ($tz =~ /^[A-Z]/) {
       require DateTime;
	   my @dkeys = (qw/year month day hour minute second/);
	   my $i = 0;
       my $dt = DateTime->new( ( map { $dkeys[$i++] => $_ } @{$ymdhms} ), time_zone => $tz, );
       $epoch = $dt->epoch();
  }
  else { # No timezone specification; use Time::Local
    require Time::Local;
    #$time = timelocal($sec,$min,$hour,$mday,$mon,$year);
    $epoch = Time::Local::timelocal(reverse @{$ymdhms});
  }
  return $epoch;
}

sub _convert {
   my $ymdhms = shift;
   return turn2str(   # Convert Julian day into fraction of a turn
            mjd2lst(
                cal2mjd( # Convert calendar date & time (dayfraction) into Julian Day, via Astro-Time:
                    $ymdhms->[2], # $day
                    $ymdhms->[1], # $month
                    $ymdhms->[0], # $year
                    hms2time(# Convert hours, minutes & seconds into day fraction (ut), via Astro-Time:
                        $ymdhms->[3],
                        $ymdhms->[4],
                        $ymdhms->[5],,
                    ),
                ), 
                str2turn(# Convert angle from string (in Degrees, not Hours) into fraction of a turn, via Astro-Time:
                    shift,
                    'D',
                )
            ),
       'H', # into 'H(ours)' (not D(egrees))
       0 # 'No. sig. digits'
   );
}

1;
__END__

=head1 EXAMPLE

=head2 Here and Now

Use HeavensAbove and Date::Calc to blindly get the present LST.

 use Time::LST qw(ymdhms2lst);
 use Date::Calc qw(Today_and_Now);
 use WWW::Gazetteer::HeavensAbove;

 my $atlas = WWW::Gazetteer::HeavensAbove->new;
 my $cities = $atlas->find('Hobart', 'AU'); # cityname, ISO country code
 # Assume call went well, and the first city returned is "here".

 print 'The LST here and now is ' . ymdhms2lst([Today_and_Now()], $cities->[0]->{'longitude'});

=head1 SEE ALSO

L<Astro::Time|lib::Astro::Time> : the present module uses the C<turn2str>, C<hms2time>, C<str2turn>, C<cal2mjd>, and C<mjd2lst> methods to eventually get the LST for a given time.

L<Date::Parse|lib::Date::Parse> : the present module uses the C<str2time> method to parse datetime strings to a format that can be readily converted to LST via C<ymdhms_2_time()>. See this module for parsing other datetime representations into a "time" format that can be sent to C<time2lst()>.

L<WWW::Gazetteer::HeavensAbove|lib::WWW::Gazetteer::HeavensAbove> : see this module for determining longitudes of a certain city, or visit L<http://www.heavens-above.com/countries.asp>.

L<http://home.tiscali.nl/~t876506/TZworld.html> for valid timezone strings.

=head1 TO DO/ISSUES

Timezone handling might need higher sensitivity.

Epoch-external periods merit a better solution than reduction to the minimum/maximum.

=head1 ACKNOWLEDGEMENT

The author of Astro::Time kindly looked over the basic conversion wrap-up. Any errors are fully those of the present author.

=head1 AUTHOR/LICENSE

=over 4

=item Copyright (c) 2006-2008 R Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=cut

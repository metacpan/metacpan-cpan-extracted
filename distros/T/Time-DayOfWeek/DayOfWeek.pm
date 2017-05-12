# 3C7JExdx:Time::DayOfWeek.pm by PipStuart <Pip@CPAN.Org> to simply tell what day of the week a specific (YMD) date is.
package    Time::DayOfWeek;
use strict;use warnings;use utf8;
require      Exporter  ;
use base qw( Exporter );
our $VERSION    = '1.8';our $d8VS='G7MMAGT7';
our @EXPORT     =              qw( DoW                                   ); # only export DoW() for 'use Time::DayOfWeek;' and all other stuff optionally
our @EXPORT_OK  =              qw(     Dow DayOfWeek DayNames MonthNames );
our %EXPORT_TAGS= ( 'all' => [ qw( DoW Dow DayOfWeek DayNames MonthNames ) ],
                    'dow' => [ qw( DoW Dow DayOfWeek                     ) ],
                    'nam' => [ qw(                   DayNames MonthNames ) ],
                    'day' => [ qw( DoW Dow DayOfWeek DayNames            ) ]);
my @Days   =   qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );
my @Day    = ();push(@Day,substr($_, 0, 3)) for(@Days);
my @Months = ( qw( January February March     April   May      June 
                   July    August   September October November December ) );
sub DoW{ # calculate the day-of-the-week from the Year, Month, and Day
  my $year = shift; $year = 2000 unless(defined($year));
  my $mont = shift; $mont =    1 unless(defined($mont) && $mont);  # 1..12
  my $daay = shift; $daay =    1 unless(defined($daay) && $daay);  # 1..31
  if($mont !~ /^\d+$/){ # match a named month if param not a number 1..12
    for(my $i = 0; $i < @Months; $i++) { if($Months[$i] =~ /^$mont/i) { $mont = ($i + 1); last;}}}
  my $mndx = int((14 - $mont) / 12); my $yshf = $year - $mndx; my $ys4h = $yshf / 400; $daay += $yshf + int($ys4h) - int($ys4h * 4) + int($ys4h * 100);
  $daay++ if(($year == 2008 &&  $mont >=  3) || ($year == 2009 && $mont <= 2)); # silly kludge hack to shift right between Feb.29..28leap-dayz for 2008..2009
  return(($daay + (31 * int((12 * $mndx) + $mont - 2)) / 12) % 7);}
sub Dow      {return($Day[ DoW(@_)]);} # return 3-letter abbrev.
sub DayOfWeek{return($Days[DoW(@_)]);} # return full day name
sub DayNames {@Days = @_ if(@_ >= @Days); @Day  = ();            # assign a new day   names list if there aren't too few day   names
  for(@Days) {(length($_) > 3) ? push(@Day, substr($_, 0, 3)) : push(@Day, $_);} # redo abbrevs
  return(@Days);}
sub MonthNames{@Months = @_ if(@_ >= @Months); return(@Months);} # assign a new month names list if there aren't too few month names
8;

=encoding utf8

=head1 NAME

Time::DayOfWeek - calculate which Day-of-Week a date is

=head1 VERSION

This documentation refers to version 1.8 of Time::DayOfWeek, which was released on Fri Jul 22 10:16:29:07 -0500 2016.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;use warnings;use utf8;use v5.10;
  use Time::DayOfWeek qw(:dow);

  my         ($year, $month, $day)  =  (2003, 12, 7);

  say "The Day-of-Week of $year/$month/$day (YMD) is: ",
    DayOfWeek($year, $month, $day);

  say 'The 3-letter abbreviation       of the Dow is: ',
    Dow(      $year, $month, $day);

  say 'The 0-based  index              of the DoW is: ',
    DoW(      $year, $month, $day);

=head1 DESCRIPTION

This module just calculates the Day-of-Week for any particular date. It was inspired by the clean L<Time::DaysInMonth> module written by David Muir
Sharnoff <Muir@Idiom.Com>.

=head1 USAGE

=head2 DoW(<Year>, <Month>, <Day>)

Time::DayOfWeek's core function which does the calculation and returns the weekday index answer between 0 and 6. If no Year is supplied, 2000 C.E. is assumed.
If no Month or Day is supplied, they are set to 1. Months are 1-based with values between 1 and 12. Days similarly range from 1 through 31.

DoW() is the only function that is exported from a normal 'use Time::DayOfWeek;' command. Other functions can be imported into the local namespace explicitly
or with the following tags:

  :all - every function described here
  :dow - only DoW(), Dow(), and DayOfWeek()
  :nam - only DayNames()  and  MonthNames()
  :day - everything       but  MonthNames()

=head2 Dow(<Year>, <Month>, <Day>)

Dow()       is the same as DoW() above but returns 3-letter day abbreviations running from 'Sun' through 'Sat'.

=head2 DayOfWeek(<Year>, <Month>, <Day>)

DayOfWeek() is the same as DoW() above but returns full day names from 'Sunday' through 'Saturday'.

=head2 DayNames(<@NewDayNames>)

DayNames() can override default day names with the strings in @NewDayNames. The current list of day names is returned so call DayNames() with no parameters to
obtain a list of the default day names.

An example call for Spanish days would be:

  DayNames('Domingo', 'Lunes',  'Martes',  'Miercoles', 'Jueves', 'Viernes', 'Sabado');

=head2 MonthNames(<@NewMonthNames>)

MonthNames() has also been included to provide a centralized name set. Just like DayNames(), this function returns the current list of month names so call it
with no parameters to obtain a list of the default month names.

=head1 CHANGES

Revision history for Perl extension Time::DayOfWeek:

=over 2

=item - 1.8 G7MMAGT7  Fri Jul 22 10:16:29:07 -0500 2016

* updated license to GPLv3

* removed PT from VERSION

=item - 1.6.A6FFxZB  Tue Jun 15 15:59:35:11 2010

* had to bump minor version to keep them ascending

=item - 1.4.A6FCO7V  Tue Jun 15 12:24:07:31 2010

* added hack to shift days right one between Feb2008..2009 (still not sure why algorithm skewed)

=item - 1.4.75R5ulZ  Sun May 27 05:56:47:35 2007

* added kwalitee && POD tests, bumped minor version

* condensed code && moved POD to bottom

=item - 1.2.4CCMRd5  Sun Dec 12 22:27:39:05 2004

* updated License

=item - 1.0.429BmYk  Mon Feb  9 11:48:34:46 2004

* updated DoW param tests to turn zero month or day to one

* updated POD to contain links

=item - 1.0.41M4ecn  Thu Jan 22 04:40:38:49 2004

* made bin/dow as EXE_FILES && added named month param detection

=item - 1.0.3CNH7Fs  Tue Dec 23 17:07:15:54 2003

* removed most eccentric misspellings

=item - 1.0.3CCA4sO  Fri Dec 12 10:04:54:24 2003

* removed indenting from POD NAME field

=item - 1.0.3CB7PxT  Thu Dec 11 07:25:59:29 2003

* added month name data and tidied up for release

=item - 1.0.3C7IOam  Sun Dec  7 18:24:36:48 2003

* wrote pod and made tests

=item - 1.0.3C7Exdx  Sun Dec  7 14:59:39:59 2003

* original version

=back

=head1 TODO

=over 2

=item - figure out why 2008 needed increment hack

=item - test that UTF-8 characters work in MonthNames and DayNames

=item - write many more tests for boundary conditions

=back

=head1 INSTALL

From the command shell, please run:

  `perl -MCPAN -e "install Time::DayOfWeek"`

or uncompress the package and run the standard:

  `perl Makefile.PL;       make;       make test;       make install`
    or if you don't have  `make` but Module::Build is installed, try:
  `perl    Build.PL; perl Build; perl Build test; perl Build install`

=head1 LICENSE

Most source code should be Free! Code I have lawful authority over is and shall be!
Copyright: (c) 2003-2016, Pip Stuart.
Copyleft :  This software is licensed under the GNU General Public License
  (version 3 or later). Please consult L<HTTP://GNU.Org/licenses/gpl-3.0.txt>
  for important information about your freedom. This is Free Software: you
  are free to change and redistribute it. There is NO WARRANTY, to the
  extent permitted by law. See L<HTTP://FSF.Org> for further information.

=head1 AUTHOR

Pip Stuart <Pip@CPAN.Org>

=cut

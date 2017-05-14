package Tivoli::DateTime;

our(@ISA, @EXPORT, $VERSION, $Fileparse_fstype, $Fileparse_igncase);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(YYYYMMDD YYYYMMDDHHMMSS HHdMMdSS YYYYmMMmDD DDdMMdYYYY DDmMMmYYYY EpocheSS EpocheSS2DdMdYYYY EpocheSS2DdMdYYYYsHdMdS date_split_dot date_split_minus slash_date longDateTime longDate abr_mon abr_day month day month_num day_num year days_left);

$VERSION = '0.03';

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
@nummonths = ("01","02","03","04","05","06","07","08","09","10","11","12");
@months = ("January","February","March","April","May","June","July","August","September","October","November","December");
@abr_months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec");
@days = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
@abr_days = ('Sun','Mon','Tues','Wed','Thurs','Fri','Sat');
$year += 1900;
$mday = "0" . $mday if $mday < 10;
$hour = "0" . $hour if $hour < 10;
$min = "0" . $min if $min < 10;
$sec = "0" . $sec if $sec < 10;

################################################################################################

=pod

=head1 NAME

	Tivoli::DateTime - Perl Extension for Tivoli

=head1 SYNOPSIS

	use Tivoli::DateTime;


=head1 VERSION

	v0.03

=head1 LICENSE

	Copyright (c) 2001 Robert Hase.
	All rights reserved.
	This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 DESCRIPTION

=over

	This Package will handle about everything you may need for displaying the date / time.
	If anything has been left out, please contact me at
	kmeltz@cris.com , tivoli.rhase@muc-net.de
	so it can be added.

=back

=head2 DETAILS

	d = dot, s = slash, m = minus

=head2 ROUTINES

	Description of Routines

=head3 YYYYMMDD

=over

=item * DESCRIPTION

	Returns YYYYMMDD

=item * CALL

	$Var = &YYYYMMDD;

=item * SAMPLE

	$Var = &YYYYMMDD;
	$Var = 20010804

=back

=cut

sub YYYYMMDD
{
	return($year . @nummonths[$mon] . $mday);
}

=pod

=head3 YYYYMMDDHHMMSS

=over

=item * DESCRIPTION

	Returns YYYYMMDDHHMMSS

=item * CALL

	$Var = &YYYYMMDDHHMMSS;

=item * SAMPLE

	$Var = &YYYYMMDDHHMMSS;
	$Var = 20010804134527

=back

=cut

sub YYYYMMDDHHMMSS
{
        return($year . @nummonths[$mon] . $mday . $hour . $min . $sec);
}

=pod

=head3 HHdMMdSS

=over

=item * DESCRIPTION

	Returns HHdMMdSS

=item * CALL

	$Var = &HHdMMdSS;

=item * SAMPLE

	$Var = &HHdMMdSS;
	$Var = 13.45.27

=back

=cut

sub HHdMMdSS
{
	return("$hour.$min.$sec");
}

=pod

=head3 YYYYmMMmDD

=over

=item * DESCRIPTION

	Returns YYYYmMMmDD

=item * CALL

	$Var = &YYYYmMMmDD;

=item * SAMPLE

	$Var = &YYYYmMMmDD;
	$Var = 2001-08-04

=back

=cut

sub YYYYmMMmDD
{
	return("$year-@nummonths[$mon]-$mday");
}

=pod

=head3 DDdMMdYYYY

=over

=item * DESCRIPTION

	Returns DDdMMdYYYY

=item * CALL

	$Var = &DDdMMdYYYY;

=item * SAMPLE

	$Var = &DDdMMdYYYY;
	$Var = 04.08.2001

=back

=cut

sub DDdMMdYYYY
{
	return("$mday.@nummonths[$mon].$year");
}

=pod

=head3 DDmMMmYYYY

=over

=item * DESCRIPTION

	Returns DDmMMmYYYY

=item * CALL

	$Var = &DDmMMmYYYY;

=item * SAMPLE

	$Var = &DDmMMmYYYY;
	$Var = 04-08-2001

=back

=cut

sub DDmMMmYYYY
{
	return("$mday-@nummonths[$mon]-$year");
}

=pod

=head3 EpocheSS

=over

=item * DESCRIPTION

	Returns EpocheSS since 1970-01-01 00:00.00

=item * CALL

	$Var = &EpocheSS;

=item * SAMPLE

	$Var = &EpocheSS;
	$Var = 78762323109843

=back

=cut

sub EpocheSS
{
	return(time());
}

=pod

=head3 EpocheSS2DdMdYYYY

=over

=item * DESCRIPTION

	Converts the given Epoche-Seconds to DdMdYYYY

=item * CALL

	$Var = &EpocheSS2DdMdYYYY(78762323109843);

=item * SAMPLE

	$Var = &EpocheSS2DdMdYYYY(78762323109843);
	$Var = 04.08.2001

=back

=cut

sub EpocheSS2DdMdYYYY
{
	# UNIX-Sek in Datum DMY wandeln
	# Syntax: &sek2dat(SECONDS);
	$U_SEK = $_[0];
	($TAG, $MONAT, $JAHR) = (localtime $U_SEK) [3,4,5];
	$MONAT++;
	$JAHR += 1900;
	return("$TAG.$MONAT.$JAHR");
}

=pod

=head3 EpocheSS2DdMdYYYYsHdMdS

=over

=item * DESCRIPTION

	Converts the given Epoche-Seconds to DdMdYYYYsHdMdS

=item * CALL

	$Var = &EpocheSS2DdMdYYYYsHdMdS(78762323109843);

=item * SAMPLE

	$Var = &EpocheSS2DdMdYYYYsHdMdS(78762323109843);
	$Var = 04.08.2001/13.45.27

=back

=cut

sub EpocheSS2DdMdYYYYsHdMdS
{
	# UNIX-Sek in Datum DMYhms wandeln
	# Syntax: &sek2dat_time(SECONDS);
	$U_SEK = $_[0];
	($SEK, $MIN, $STD, $TAG, $MONAT, $JAHR, $WOCH_TAG, $JAHR_TAG, $ISDST) = (localtime $U_SEK);
	$MONAT++;
	$JAHR += 1900;
	return("$TAG.$MONAT.$JAHR/$STD.$MIN.$SEK");
}

=pod

=head3 date_split_dot

=over

=item * DESCRIPTION

	Splits the given Dot-Date 04.08.2001 to 04 08 2001

=item * CALL

	$Var = &date_split_dot("04.08.2001");

=item * SAMPLE

	@Arr = &date_split_dot("04.08.2001");
	@Arr = qw(04 08 2001);

=back

=cut

sub date_split_dot
{
	# Datum xx.xx.xxxx splitten
	# Syntax: &date_split_punkt(DATUM);
	$DAT_SPLIT = $_[0];
	($Tag, $MONAT, $JAHR) = ($DAT_SPLIT =~ /(\d+)\.(\d+)\.(\d+)/);
	@DAT_SPLIT = ($TAG, $MONAT, $JAHR);
	return(@DAT_SPLIT);
}

=pod

=head3 date_split_minus

=over

=item * DESCRIPTION

	Splits the given Date 04-08-2001 to 04 08 2001

=item * CALL

	$Var = &date_split_minus("04-08-2001");

=item * SAMPLE

	@Arr = &date_split_minus("04-08-2001");
	@Arr = qw(04 08 2001);

=back

=cut

sub date_split_minus
{
	# Datum xx-xx-xxxx splitten
	# Syntax: &dat_split_strich(DATUM);
	$DAT_SPLIT = $_[0];
	($Tag, $MONAT, $JAHR) = ($DAT_SPLIT =~ /(\d+)-(\d+)-(\d+)/);
	@DAT_SPLIT = ($TAG, $MONAT, $JAHR);
	return(@DAT_SPLIT);
}

=pod

=head3 slash_date

=over

=item * DESCRIPTION

	Returns MM/DD/YYYY

=item * CALL

	$Var = &slash_date;

=item * SAMPLE

	$Var = &slash_date;
	$Var = 04/08/2001;

=back

=cut

sub slash_date
{
   # returns as mm/dd/yy
    ($ob = $sdate) =~ s/^\d{2}//g;
    $sdate = "@nummonths[$mon]/$mday/$year";
    return($sdate);
}

=pod

=head3 longDateTime

=over

=item * DESCRIPTION

	Returns long DateTime

=item * CALL

	$Var = &longDateTime;

=item * SAMPLE

	$Var = &longDateTime;
	$Var = Saturday, 08 04, 2001 at 13:45:27

=back

=cut

sub longDateTime
{
   # Syntax: &date_time;
   # Returns as DayName, MonthName MonthDay, Year at hour:minute:second
  # if ($hour < 10) { $hour = "0$hour"; }
   if ($min < 10) { $min = "0$min"; }
   if ($sec < 10) { $sec = "0$sec"; }
   $date_time =  "$days[$wday], $months[$mon] $mday, $year at $hour\:$min\:$sec";
   return($date_time);
}

=pod

=head3 longDate

=over

=item * DESCRIPTION

	Returns long Date

=item * CALL

	$Var = &longDate;

=item * SAMPLE

	$Var = &longDate;
	$Var = Saturday, 08 04, 2001

=back

=cut

sub longDate
{
   # Syntax: &long_date;
   # Returns as DayName, MonthName MonthDay, Year
   $ldate = "$days[$wday], $months[$mon] $mday, $year";
   return($ldate);
}

=pod

=head3 abr_mon

=over

=item * DESCRIPTION

	Returns abbreviation of Month

=item * CALL

	$Var = &abr_mon;

=item * SAMPLE

	$Var = &abr_mon;
	$Var = Aug

=back

=cut

sub abr_mon
{
   # Syntax: &abr_mon;
   # Returns abbreviation of Month
   return($abr_months[$mon]);
}

=pod

=head3 abr_day

=over

=item * DESCRIPTION

	Returns abbreviation of Day

=item * CALL

	$Var = &abr_day;

=item * SAMPLE

	$Var = &abr_day;
	$Var = Sat

=back

=cut

sub abr_day
{
   # Syntax: &abr_day;
   # Returns abbreviation on Day
   return($abr_days[$wday]);
}

=pod

=head3 month

=over

=item * DESCRIPTION

	Returns Nr of Month

=item * CALL

	$Var = &month;

=item * SAMPLE

	$Var = &month;
	$Var = 08

=back

=cut

sub month
{
   # Syntax: &month;
   # Returns Month name
   return($months[$mon]);
}

=pod

=head3 day

=over

=item * DESCRIPTION

	Returns Nr of Day

=item * CALL

	$Var = &day;

=item * SAMPLE

	$Var = &day;
	$Var = 6

=back

=cut

sub day
{
   # Syntax: &day;
   # Returns day of week
   return($days[$wday]);
}

=pod

=head3 month_num

=over

=item * DESCRIPTION

	Returns Nr of Month

=item * CALL

	$Var = &month_num;

=item * SAMPLE

	$Var = &month_num;
	$Var = 8

=back

=cut

sub month_num
{
   # Syntax: &month_num;
   # Returns number of month
   return($nummonths[$mon]);
}

=pod

=head3 day_num

=over

=item * DESCRIPTION

	Returns Nr of Day

=item * CALL

	$Var = &day_num;

=item * SAMPLE

	$Var = &day_num;
	$Var = 6

=back

=cut

sub day_num
{
   # Syntax: &day_num;
   # Returns number of the day
   return($mday);
}

=pod

=head3 year

=over

=item * DESCRIPTION

	Returns Year

=item * CALL

	$Var = &year;

=item * SAMPLE

	$Var = &year;
	$Var = 2001

=back

=cut

sub year
{
   $year = "$year";
   return($year);
}

=pod

=head3 days_left

=over

=item * DESCRIPTION

	Returns days left in year

=item * CALL

	$Var = &days_left;

=item * SAMPLE

	$Var = &days_left;
	$Var = 236

=back

=cut

sub days_left
{
   return(365 - $yday);
}

=pod

=head2 Plattforms and Requirements

=over

	Supported Plattforms and Requirements

=item * Plattforms

	tested on:

	- w32-ix86 (Win9x, NT4, Windows 2000)
	- aix4-r1 (AIX 4.3)
	- Linux (Kernel 2.2.x)

=back

=item * Requirements

	requires Perl v5 or higher

=back

=head2 HISTORY

	VERSION		DATE		AUTHOR		WORK
	----------------------------------------------------
	0.01		1999		kmeltz		created
	0.02		2000-08		RHase		several Date / Time Formats
	0.03		2001-08-04	RHase		POD-Doku added

=head1 AUTHOR

	kmeltz, Robert Hase
	ID	: KMELTZ, RHASE
	eMail	: kmeltz@cris.com, Tivoli.RHase@Muc-Net.de
	Web	: http://www.Muc-Net.de

=head1 SEE ALSO

	CPAN
	http://www.perl.com

=cut


###############################################################################################

1; # return true

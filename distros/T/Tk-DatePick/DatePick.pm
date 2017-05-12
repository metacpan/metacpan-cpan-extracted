package Tk::DatePick;

use strict;
use warnings;

our $VERSION = '1.02';

require Tk::Frame;
our @ISA = qw(Tk::Frame);

Tk::Widget->Construct('DatePick');

sub Populate
	{
	require Tk::Label;
	require Tk::FireButton;
	my ($cw,$args) = @_;
	my $max = $args->{'-max'};
	my $min = $args->{'-min'};
	my $yeartype = $args->{'-yeartype'};
	my $currdate = $args->{'-text'};
	my $format = $args->{'-dateformat'};
	$format = 0 unless defined $format;
	if (defined $currdate)
		{die "Invalid Date" unless isvaliddate($currdate,$format);}
	$currdate = ourtoday($format) unless defined $currdate;
	if (defined $yeartype)
		{
		if ($yeartype eq 'calyear')
			{($min,$max) = calyear($currdate,$format);}
		else 	{($min,$max) = finyear($currdate,$format);}
		}
	$cw->SUPER::Populate($args);
	my $f = $cw->Frame(-relief => 'sunken',
			-border => 1)->pack;
	my $l = $f->Label(
		-width => '16',
		-text => $currdate,
	)->pack(-side => 'top');
	my $temp;
	$cw->ConfigSpecs(
			'-status' => ['METHOD'],
			'-dateformat' => ['PASSIVE'],
			'-max' => ['PASSIVE'],
			'-min' => ['PASSIVE'],
			'-yeartype' => ['PASSIVE'],
			DEFAULT => [$l]);
	my($button_1) = $f->FireButton (
		-text => '<<<',
		-command => sub
			{
			$currdate = addyear($currdate,-1,$format,$max,$min);
			$l->configure(-text => $currdate);

			}
	)->pack(-side => 'left');

	my($button_2) = $f->FireButton (
		-text => '<<',
		-command => sub
			{
			$currdate = addmonths($currdate,-1,$format,$max,$min);
			$l->configure(-text => $currdate);
			}
	)->pack(-side => 'left');
	my($button_3) = $f->FireButton (
		-text => '<',
		-command => sub
			{
			$currdate = adddays($currdate,-1,$format,$max,$min);
			$l->configure(-text => $currdate);
			}
	)->pack(-side => 'left');
	my($button_4) = $f->FireButton (
		-text => '>',
		-command => sub
			{
			$currdate = adddays($currdate,1,$format,$max,$min);
			$l->configure(-text => $currdate);
			}
	)->pack(-side => 'left');
	my($button_5) = $f->FireButton (
		-text => '>>',
		-command => sub
			{
			$currdate = addmonths($currdate,1,$format,$max,$min);
			$l->configure(-text => $currdate);
			}
	)->pack(-side => 'left');
	my($button_6) = $f->FireButton (
		-text => '>>>',
		-command => sub
			{
			$currdate = addyear($currdate,1,$format,$max,$min);
			$l->configure(-text => $currdate);
			}
	)->pack(-side => 'left');
	$cw->Advertise('but1' => $button_1);
	$cw->Advertise('but2' => $button_2);
	$cw->Advertise('but3' => $button_3);
	$cw->Advertise('but4' => $button_4);
	$cw->Advertise('but5' => $button_5);
	$cw->Advertise('but6' => $button_6);
	$cw->Delegates('state' => $button_1,$button_2,$button_3,
				$button_4,$button_5,$button_6);
	}
#-----------------------------------------------------------------
#to disable and enable the firebuttons
######################################
sub status
	{
	my ($cw,$temp) = @_;
	my $but1 = $cw->Subwidget('but1');
	my $but2 = $cw->Subwidget('but2');
	my $but3 = $cw->Subwidget('but3');
	my $but4 = $cw->Subwidget('but4');
	my $but5 = $cw->Subwidget('but5');
	my $but6 = $cw->Subwidget('but6');
	$but1->configure(-state => $temp);
	$but2->configure(-state => $temp);
	$but3->configure(-state => $temp);
	$but4->configure(-state => $temp);
	$but5->configure(-state => $temp);
	$but6->configure(-state => $temp);
	}
#--------------------------------------------------------------
#########################
#date manipulation stuff
########################
my %monthnum = ('Jan',1,'Feb',2,'Mar',3,'Apr',4,'May',5,'Jun',6,
	'Jul',7,'Aug',8,'Sep',9,'Oct',10,'Nov',11,'Dec',12);
my %monthname = (1,'Jan',2,'Feb',3,'Mar',4,'Apr',5,'May',
	6,'Jun',7,'Jul',8,'Aug',9,'Sep',10,'Oct',11,'Nov',12,'Dec');

#-----------------------------------------------------------
sub daysinmonth
{
	my($yr,$mth) = @_;
	my $days;
	if ($mth == 1) {$days = 31;}
	if (($mth == 2) and (($yr % 4) == 0))  {$days = 29;}
	if (($mth == 2) and (($yr % 4) != 0))  {$days = 28;}
	if ($mth == 3) {$days = 31;}
	if ($mth == 4) {$days = 30;}
	if ($mth == 5) {$days = 31;}
	if ($mth == 6) {$days = 30;}
	if ($mth == 7) {$days = 31;}
	if ($mth == 8) {$days = 31;}
	if ($mth == 9) {$days = 30;}
	if ($mth == 10) {$days = 31;}
	if ($mth == 11) {$days = 30;}
	if ($mth == 12) {$days = 31;}
	return $days;
} #end of daysinmonth
#------------------------------------------------------------
#scalar date returns the number of days since 1.1.1900.
sub scalardate
{
	my($day,$month,$year,$i);
	my $scdate = 365;
	my ($date,$format) = @_;
	($day,$month,$year) = parsedate($date,$format);
	die "Invalid Date" unless isvaliddate($date,$format);
	$year = $year - 1900;
	for ($i = 1; $i < $year; $i++)
		{
		if (($i % 4) == 0) {$scdate = $scdate + 366;}
		else {$scdate = $scdate +365;}
		}
	for ($i = 1; $i < $month; $i++)
		{
		$scdate = $scdate + daysinmonth($year,$i);
		}
	$scdate = $scdate + $day;
	return $scdate;
}# end of scalardate.
#-------------------------------------------------------------
sub daysinyear

{
	my $result;
	my($yer) = @_;
	if (($yer % 4) == 0) {$result = 366;}
	else {$result = 365;}
	return $result;
}
#-------------------------------------------------------------
#this converts a number into a date string

sub datefromscalar

{
	my($inscale,$year,$i,$month,$day,$format,$date);
	($inscale, $format) = @_;
	$inscale = $inscale - 365;
	for ($i = 1; $inscale > daysinyear($i); $i++)
		{
		$inscale = $inscale - daysinyear($i);
		}
	$year = $i + 1900;
	for ($i = 1; $inscale > daysinmonth($year,$i); $i++)
		{
		$inscale = $inscale - daysinmonth($year,$i);
		}
	$month = $i; 
	$day = $inscale;
	if ($format == 0)
		{$date = $day.'/'.$month.'/'.$year;}
	else	{$date = $month.'/'.$day.'/'.$year;}
	return $date;
}# end of datefromscalar

#---------------------------------------------------------------

# this adds or subtracts days to a date and gives the result

sub adddays
{
	my($date,$addition,$format,$max,$min) = @_;
	my ($mx,$mn,$newdate);
	if (defined $max)
		{
		$mx = scalardate($max, $format);
		}
	else
		{
		$mx = scalardate('31/12/2095',0);
		}
	if (defined $min)
		{
		$mn = scalardate($min, $format);
		}
	else
		{
		$mn = scalardate('1/1/1905',0);
		}
	my $temp = scalardate($date,$format) + $addition;
	if (($temp > $mx)or ($temp < $mn))
		{$newdate = $date}
	else
	{$newdate = datefromscalar($temp,$format);}
	return $newdate;
}#end of adddays
#--------------------------------------------------------------

#this adds or subtracts months
sub addmonth
{
	my($month,$adden,$mm,$newmonth);
	$month = $_[0];
	$adden = $_[1];
	$mm = $monthnum{$month};
	$mm = ($mm + $adden) % 12;
	if ($mm <= 0){$mm = $mm + 12;}
	$newmonth = $monthname{$mm};
	return $newmonth;
}#end of addmonth
#--------------------------------------------------------------
#this adds a years to a date
sub addyear
{
	my($inyear,$years,$format,$max,$min) = @_;
	my ($mx,$mn,$total,$i,$outyear);
	if (defined $max)
		{
		$mx = scalardate($max, $format);
		}
	else
		{
		$mx = scalardate('31/12/2095',0);
		}
	if (defined $min)
		{
		$mn = scalardate($min, $format);
		}
	else
		{
		$mn = scalardate('1/1/1905',0);
		}
	my ($day,$mth,$yr) = parsedate($inyear,$format);
	$total = scalardate($inyear,$format);
	if ($years > 0) 
	{
	for ($i=1;$i <= $years;$i++)
		{
		if ($mth > 2)
		{$total += daysinyear($yr+$i);}
		else
		{$total += daysinyear($yr+$i-1);}
		}
	}#end of if
	else
	{
	for ($i=$years;$i < 0;$i++)
		{
		if ($mth > 2)
			{$total -= daysinyear($yr+$i+1);}
		else
			{$total -= daysinyear($yr+$i+4);}
		}
	}#end of else
	if (($total > $mx)or ($total < $mn))
		{$outyear = $inyear;}
	else
	{$outyear = datefromscalar($total,$format);}
	return $outyear;
}#end of addyear
#---------------------------------------------------------------
#this adds  months to a date
sub addmonths
{
	my($inyear,$months,$format,$max,$min) = @_;
	my ($mx,$mn,$total,$i,$outyear);
	if (defined $max)
		{
		$mx = scalardate($max, $format);
		}
	else
		{
		$mx = scalardate('31/12/2095',0);
		}
	if (defined $min)
		{
		$mn = scalardate($min, $format);
		}
	else
		{
		$mn = scalardate('1/1/1905',0);
		}
	my ($day,$mth,$yr) = parsedate($inyear,$format);
	$total = scalardate($inyear,$format);
	if ($months > 0) 
	{
	for ($i=1;$i <= $months;$i++)
		{
		$total += daysinmonth($yr,$mth);
		if ($mth == 12) {$mth = 1;++$yr;}
		else {++$mth}
		}
	}#end of if
	else
	{
	if ($mth == 1) {$mth = 12;--$yr;}
	else {--$mth;}
	for ($i=$months;$i < 0;$i++)
		{
		$total -= daysinmonth($yr,$mth);
		if ($mth == 1) {$mth = 12;--$yr;}
		else {--$mth;}
		}
	}#end of else
	if (($total > $mx) or ($total < $mn))
		{$outyear = $inyear;}
	else
	{$outyear = datefromscalar($total,$format);}
	return $outyear;
}#end of addmonth
#---------------------------------------------------------------
# this gives the days between two dates

sub datedif
{
	my($date1,$date2) = @_;
	my $difference = scalardate($date1) - scalardate($date2);
	return $difference;
} # end of datedif
#---------------------------------------------------------------
# this compares two dates

sub datecomp
{
	my $result;
	my($date1,$date2) = @_;
	if (datedif($date1,$date2) == 0){$result = 0;}
	elsif (datedif($date1,$date2) < 0){$result = -1;}
	else {$result = 1;}
	return $result;
} # end of datedcomp
#---------------------------------------------------------------
sub calyear #gives the begining and end of the calendar year
	{
	my ($date,$format) = @_;
	my ($begin,$end);
	my ($day,$month,$year) = parsedate($date,$format);
	if ($format == 0)
		{
		$begin = '1/1/'.$year;
		$end = '31/12/'.$year;
		}
	else
		{
		$begin = '1/1/'.$year;
		$end = '12/31/'.$year;
		}
	return ($begin,$end);
	}#end of calyear

#-------------------------------------------------------
sub finyear #gives the begining and end of the financial year
	{
	my ($date,$format) = @_;
	my ($begin,$end,$begyear,$endyear);
	my ($day,$month,$year) = parsedate($date,$format);
	if ($month < 4) 
		{
		$begyear = $year-1;
		$endyear = $year;
		}
	else
		{
		$begyear = $year;
		$endyear = $year+1;
		}
	if ($format == 0)
		{
		$begin = '1/4/'.$begyear;
		$end = '31/3/'.$endyear;
		}
	else
		{
		$begin = '4/1/'.$begyear;
		$end = '3/31/'.$endyear;
		}
	return ($begin,$end);
	}#end of finyear

#-------------------------------------------------------
sub parsedate #returns day, month, year from datestring
	{
	my ($date,$format) = @_;
	my ($day,$month,$year);
	my @nut = split(/\D/,$date,4);
	if ($format == 0)
		{
		$day = $nut[0];
		$month = $nut[1];
		}
	else
		{
		$day = $nut[1];
		$month = $nut[0];
		}
	$year = $nut[2];
	return ($day,$month,$year);
	} #end of parsedate

#-----------------------------------------------------------
sub ourtoday #gives the current system date
	{
	my $format = $_[0];
	my @ar = localtime;
	my $day = $ar[3];
	my $month = $ar[4]+1;
	my $year = $ar[5] + 1900;
	my $date;
	if ($format == 0)
	{$date = $day.'/'.$month.'/'.$year;}
	else
	{$date = $month.'/'.$day.'/'.$year;}
	return $date;
	}
#---------------------------------------------------------------
#this converts unix dates to our dates

sub unixtodate
{
	my($unixdate,$dd,$mm,$yy,$format,$ourdate);
	($unixdate, $format) = @_;
	my @nut = split(/\s+/,$unixdate,7);
	$dd = $nut[2];
	$yy = $nut[5];
	$mm = $monthnum{$nut[1]};
	if ($format == 0)
	{$ourdate = $dd.'/'.$mm.'/'.$yy;}
	else
	{$ourdate = $mm.'/'.$dd.'/'.$yy;}
	return $ourdate;
}# end of unixtodate
#---------------------------------------------------------------

sub isvaliddate
	{
	my $valid = 1;
	my ($date,$format) = @_;
	my ($day,$month,$year) = parsedate($date,$format);
	if (($month < 1) or ($month > 12))
		{$valid = 0;}
	if (($year < 1901) or ($year > 2099))
		{$valid = 0;}
	if (($day < 1) or ($day > daysinmonth($year,$month)))
		{$valid =0;}
	return $valid;
	}
#---------------------------------------------------------------
1;



1;
__END__

=head1 NAME

Tk::DatePick - Perl extension for Tk to pick dates

=head1 SYNOPSIS

  use Tk::DatePick;
  	$datepick = $main->DatePick(
		-text => $currentdate,
		-dateformat => $format,
		-max => $max,
		-min => $min,
		-yeartype => $yeartype,
		-disabled => 'normal',
	)->pack();
	$currentdate = $datepick->cget('-text');

=head1 DESCRIPTION

This widget is meant to get idiot-proof input of date data in the correct
format. The date is not user editable, so the problem of checking the format
does not arise.

All options are optional. This works fine:

	$datepick = $main->DatePick()->pack();
	$newdate = $datepick->cget('-text');

The options are:

-text: this is the date fed in by the programmer. Defaults to the current
system date.

-dateformat: 0 = dd/mm/yyyy, 1 = mm/dd/yyyy. defaults to 0.

-max, -min: these are strings in the correct date format to specify the
range of dates. max defaults to 31/12/2095 and min to 1/1/1905.

-yeartype: 'calyear' sets min to 1st jan and max to 31st dec of the current
year specified in the '-text' option. 
'finyear' does the same setting the limits to the financial year (1st april
to 31st march). If the '-text' option is not set, the system date is taken
for determining the current calendar or financial year. If '-yeartype' is set it overrides any settings for '-max'
and '-min'.

-status: can be 'disabled' where the user cannot change the date or 'normal'
which is the default. 



=head1 PREREQUISITES

1. Tk

2. Tk-GBARR

=head1 INSTALLATION

Unpack the distribution

perl Makefile.PL

make

make install


=head1 AUTHOR

Kenneth Gonsalves.

 
I welcome all comments, suggestions and flames to 

lawgon@thenilgiris.com

=head1 BUGS

Must be any number crawling around - havent found any though.

=cut

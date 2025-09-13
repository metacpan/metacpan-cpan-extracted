#!/usr/bin/perlml

#BEGIN {
#	$| = 1;
#	open(STDERR, ">&STDOUT");
#	print "Content-type: text/plain\n\n";
#}

##########################################################
#	This is a demonstration file using static date for
#	a set date range. Place this file in a folder and
#	create a sub folder called demo libs. In that folder
#	you will place calendar.lib.
#
#   This file is desgined to be run from your CLI:
#
#	>perl cal_agenda_pdf.pl
#   ...or...
#   >cal_agenda_pdf.pl
##########################################################

use strict;
use warnings;
use PDF::API2;
use FindBin;
#use lib "$FindBin::Bin/../Vigil";

use lib '../';
use Vigil::Calendar;
require './calendar.lib';

my %qs;
my @qs_pairs = split(/\&/, $ENV{'QUERY_STRING'});
foreach(@qs_pairs) {
    my($k, $v) = split(/\=/, $_);
    $qs{$k} = $v;
}


my %test_data = (
    # September 2025
    '2025-09-01' => '* 09:00 Team Standup',
    '2025-09-02' => '* 14:00 Client Call',
    '2025-09-03' => '* 11:30 Project Review',
    '2025-09-07' =>  ['* 15:00 HR Meeting', '* 10:00 Code Review'],
    '2025-09-10' => '* 13:00 Lunch with Partner',
    '2025-09-12' => '* 09:30 Sprint Planning',
    '2025-09-15' => '* 16:00 Budget Review',
    '2025-09-18' => '* 12:00 Team Lunch',
    '2025-09-21' => '* 10:00 Client Presentation',
    '2025-09-25' => '* 14:30 Marketing Review',
    '2025-09-28' => '* 09:00 Project Kickoff',

    # October 2025
    '2025-10-01' => '* 10:00 Quarterly Planning',
    '2025-10-03' => '* 14:00 Design Review',
    '2025-10-05' => '* 09:00 Standup Meeting',
    '2025-10-08' => '* 11:00 Budget Discussion',
    '2025-10-10' => '* 15:00 Client Feedback',
    '2025-10-15' => ['* 13:30 Team Sync', '* 09:00 Tech Workshop', '* 16:00 Performance Review'],
    '2025-10-20' => '* 12:00 Lunch & Learn',
    '2025-10-22' => '* 10:30 Product Demo',
    '2025-10-25' => '* 14:00 Board Meeting',
    '2025-10-28' => '* 09:30 Retrospective',

    # November 2025
    '2025-11-02' => '* 09:00 Standup',
    '2025-11-04' => '* 11:00 Client Call',
    '2025-11-06' => '* 15:00 Project Review',
    '2025-11-08' => '* 10:00 Team Workshop',
    '2025-11-10' => '* 13:00 Lunch Meeting',
    '2025-11-12' => '* 09:30 Sprint Planning',
    '2025-11-15' => '* 16:00 Budget Check',
    '2025-11-17' => '* 12:00 Team Lunch',
    '2025-11-19' => '* 10:00 Client Presentation',
    '2025-11-22' => '* 14:30 Marketing Review',
    '2025-11-25' => '* 09:00 Project Kickoff',
    '2025-11-28' => '* 11:00 Retrospective',
);

my $small_test_data_demolink = qq~<a href="javascript:window.alert('Your Link Here!');">Item</a>~;
my %small_test_data;
foreach my $key (keys %test_data) {
	my $this_link = $small_test_data_demolink;
	$this_link =~ s/Here\!/Here for $key\.\.\. et al\./;
	$small_test_data{$key} = $this_link;
}

my %dayname = (
    1 => 'Sunday',
	2 => 'Monday',
	3 => 'Tuesday',
	4 => 'Wednesday',
	5 => 'Thursday',
	6 => 'Friday',
	7 => 'Saturday'
);

my $ScriptURL = "http://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";

#The default number of days between calendar iterations is 7, but a user can set this
#value up to 365. So, we need to calculate what the first day (minus max days) for the
#previous link, and then the first day (plus max days) for the next iteration link.

#Hard coded for demo.
$qs{year}  ||= 2025;
$qs{month} ||= 9;
$qs{day}   ||= 1;

$test_data{print_year}  = $qs{year};
$test_data{print_month} = $qs{month};
$test_data{print_day}   = $qs{day};

my $cal = Vigil::Calendar->new($qs{year}, $qs{month});

my ($previous_iteration_link, $next_iteration_link) = get_html_grid_links($qs{year}, $qs{month});

#Begin printing out the results.
print "Pragma: no-cache\n";
print "Content-type: text/html\n\n";
print qq~
<html>
  <head>
    <title>Vigil::Calendar - HTML Weekly Calendar</title>
    <style>
    body {
      color: #000000;                    /* text color */
      background-color: #FFFFFF;         /* background */
      font-family: Verdana, Arial, Helvetica, sans-serif;
      font-size: 14px;
      margin: 0;                         /* optional: remove default margin */
      padding: 0;                        /* optional: remove default padding */
    }
    a:link   { color: navy; }
    a:visited{ color: navy; }
    a:active { color: red; }
	h2 {
	  display: block;
	  font-size: 1.5em;      /* usually 24px if base font is 16px */
	  font-weight: bold;
	  margin-block-start: 0.83em;
	  margin-block-end: 0.83em;
	  margin-inline-start: 0;
	  margin-inline-end: 0;
	}
    </style>
	<link rel="stylesheet" href="calendar_css.pl?file=demo1&prefix=demo&pid=$$">
	<link rel="stylesheet" href="calendar_css.pl?file=demo2&prefix=small&pid=$$">
  </head>
  <body>
  <h1 style="color: #000000; font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 32px; font-weight: bold; margin: 20 auto 40px auto; text-align: center;">
    Vigil::Calendar - Monthly HTML Calendar Demonstration
  </h1>
  <div style="width: 75%; max-width: 1050px; border: 2px solid black; border-collapse: collapse; margin: 0 auto; color: #4169E1; font-family: verdana, helvetica, arial; font-size: 18px; font-weight: bold; padding: 5px; text-align:center;">
~;
print $cal->month_name, ", $qs{year}<br />\n";
print qq~
    <a href="$previous_iteration_link" style="font-weight: bold;">&lt;&lt; Previous</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="$next_iteration_link" style="font-weight: bold;">Next &gt;&gt;</a>
  </div>
~;

print calendar_maker(
    'output_style' => 'html_grid', 
	'calendar_object' => $cal,
	'css_prefix' => 'demo',
	'dayname_ref' => \%dayname,
	'content_ref' => \%test_data,
);

print qq~<p>&nbsp;</p>\n~;

print calendar_maker(
    'output_style' => 'html_grid', 
	'calendar_object' => $cal,
	'css_prefix' => 'small',
	'dayname_ref' => { 1 => 'S', 2 => 'M', 3 => 'T', 4 => 'W', 5 => 'Th', 6 => 'F', 7 => 'S'},
	'content_ref' => \%small_test_data,
);
print qq~
    <p>&nbsp;</p>
    <p>&nbsp;</p>
  </body>
</html>
~;

sub get_html_grid_links {
	my ($y, $m) = @_;
	
	my $prev_y = $y;
	my $prev_m = $m - 1;
	if($prev_m == 0) {
		$prev_m = 12;
		$prev_y -= 1;
	}

	my $next_y = $y;
	my $next_m = $m + 1;
	if($next_m == 13) {
		$next_m = 1;
		$next_y += 1;
	}

    my $previous_month_link = qq~${ScriptURL}?year=${prev_y}&month=${prev_m}&pid=$$~;
    my $next_month_link = qq~${ScriptURL}?year=${next_y}&month=${next_m}~;

    return($previous_month_link, $next_month_link);
}

exit;


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

#Default num event days printed is 7. You can adjust this from 1 .. 365 here. Default is 7.
#WARNING: This is a number of days WITH events. If a day does not have events, it is skipped
#and not counted. This will play havoc with how you interpret what you are seeing on the
#monitor.
$test_data{agenda_max_days} = 30;

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

my @now = localtime(time);
$qs{year}  ||= $now[5] + 1900;
$qs{month} ||= $now[4] + 1;
$qs{day}   ||= $now[3];

$test_data{print_year}  = $qs{year};
$test_data{print_month} = $qs{month};
$test_data{print_day}   = $qs{day};

my $cal = Vigil::Calendar->new($qs{year}, $qs{month});

my ($previous_iteration_link, $next_iteration_link) = get_html_agenda_links($cal, \%test_data);

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
  </head>
  <body>
  <h1 style="color: #000000; font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 32px; font-weight: bold; margin: 20 auto 40px auto; text-align: center;">
    Vigil::Calendar - Weekly HTML Calendar Demonstration
  </h1>
  <div style="width: 75%; border: 2px solid black; border-collapse: collapse; margin: 0 auto; color: #4169E1; font-family: verdana, helvetica, arial; font-size: 18px; font-weight: bold; padding: 5px; text-align:center;">
~;
print $cal->month_name, ", $qs{year}<br />\n";
print qq~
    <a href="$previous_iteration_link" style="font-weight: bold;">&lt;&lt; Previous</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="$next_iteration_link" style="font-weight: bold;">Next &gt;&gt;</a>
  </div>
~;

print calendar_maker(
    'output_style' => 'html_agenda', 
	'calendar_object' => $cal,
	'css_prefix' => 'demo',
	'dayname_ref' => \%dayname,
	'content_ref' => \%test_data,
);

print qq~
  <p>&nbsp;</p>
  </body>
</html>
~;

sub get_html_agenda_links {
	my $c_obj = shift;
	my $data_ref = shift;

	my($display_year, $display_month, $display_day);

    my $count = 0;
	my $iterator = 0;

	my $sse_tracker = $c_obj->sse_from_ymd($data_ref->{print_year}, $data_ref->{print_month}, $data_ref->{print_day}) + 7200;
	my $reset_sse = $sse_tracker;
	while ($count < $data_ref->{agenda_max_days}) {

		return do {
			my @p = localtime( $reset_sse - ($test_data{agenda_max_days} * 86400) );
            my $previous_iteration_link = qq~$ScriptURL?year=~ . ($p[5] + 1900) . qq~&month=~ . ($p[4] + 1) . qq~&day=~ . $p[3] . qq~&pid=$$~;

            my @n = localtime( $reset_sse + ($test_data{agenda_max_days} * 86400) );
            my $next_iteration_link = qq~$ScriptURL?year=~ . ($n[5] + 1900) . qq~&month=~ . ($n[4] + 1) . qq~&day=~ . $n[3] . qq~&pid=$$~;

			($previous_iteration_link, $next_iteration_link);

		} if $iterator >= 364;

		$sse_tracker += 86400 if $iterator;
		$iterator++;
		my @loc_t = localtime($sse_tracker);
		$display_year  = $loc_t[5] + 1900;
		$display_month = $loc_t[4] + 1;
		$display_day   = $loc_t[3];
        my $display_date = sprintf("%04d-%02d-%02d", $display_year, $display_month, $display_day);
		# skip undef
		next unless defined $data_ref->{$display_date};

        $count++;
	}

    my @p = localtime( $cal->sse_from_ymd($data_ref->{print_year}, $data_ref->{print_month}, $data_ref->{print_day}) - ($test_data{agenda_max_days} * 86400) );
    my $previous_iteration_link = qq~$ScriptURL?year=~ . ($p[5] + 1900) . qq~&month=~ . ($p[4] + 1) . qq~&day=~ . $p[3] . qq~&pid=$$~;

    #my @n = localtime( $cal->sse_from_ymd($display_year, $display_month, $display_day) + (($test_data{agenda_max_days} * 86400) * 2) );
    my @n = localtime( $sse_tracker );
    my $next_iteration_link = qq~$ScriptURL?year=~ . ($n[5] + 1900) . qq~&month=~ . ($n[4] + 1) . qq~&day=~ . $n[3] . qq~&pid=$$~;

    return($previous_iteration_link, $next_iteration_link);
}

exit;


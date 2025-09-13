#!/usr/bin/env perl

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
use FindBin;
use PDF::API2;
use lib "$FindBin::Bin/../../lib";
use Vigil::Calendar;
require './calendar.lib';

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

#Default num days printed is 7. You can adjust this from 1 .. 365 here. Default is 7.
$test_data{'agenda_max_days'} = 30;

#To serialize the agenda output, set this value to a true value.
$test_data{serialize} = 1;

my %dayname = (
    1 => 'Sunday',
	2 => 'Monday',
	3 => 'Tuesday',
	4 => 'Wednesday',
	5 => 'Thursday',
	6 => 'Friday',
	7 => 'Saturday'
);

my $cal = Vigil::Calendar->new(2025, 9);

my $pdf = PDF::API2->new();

my $page = $pdf->page();

my $text = $page->text();
$text->font($pdf->corefont('Helvetica'), 12);

# page layout constants
my $margin_top    = 700;
my $margin_bottom = 50;
my $line_height   = 14;

my $y = $margin_top;

my $new_page = sub {
    $page = $pdf->page();
    $text = $page->text();
    $text->font($pdf->corefont('Helvetica'), 12);
    $y = $margin_top;
};

my $draw_callback = sub {
    my ($line) = @_;
	if ($y <= $margin_bottom) {
        $new_page->();
    }
    $text->translate(50, $y);
    $text->text($line);
    $y -= $line_height;
};

calendar_maker(
    'output_style' => 'pdf_agenda', 
	'calendar_object' => $cal,
	'dayname_ref' => \%dayname,
	'content_ref' => \%test_data,
    'pdf_draw_callback' => $draw_callback
);

# Save the PDF
my $outfile = "agenda.pdf";
$pdf->saveas($outfile);
$pdf->end();

# Open it (platform-specific)
if ($^O eq 'MSWin32') {
    system(1, "start", $outfile);
}
elsif ($^O eq 'darwin') { # macOS
    system("open", $outfile);
}
else { # Linux/BSD
    system("xdg-open", $outfile);
}

print "\nCalendar finished.\n";

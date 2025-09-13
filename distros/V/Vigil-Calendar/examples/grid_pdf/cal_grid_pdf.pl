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
    '2025-09-01' => '*Item',
    '2025-09-02' => '*Item',
    '2025-09-03' => '*Item',
    '2025-09-07' =>  ['*Item', '*Item'],
    '2025-09-10' => '*Item',
    '2025-09-12' => '*Item',
    '2025-09-15' => '*Item',
    '2025-09-18' => '*Item',
    '2025-09-21' => '*Item',
    '2025-09-25' => '*Item',
    '2025-09-28' => '*Item'
);

#For demonstration purposes ;-)
$test_data{'print_year'} = 2025;
$test_data{'print_month'} = 9;

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

my $y_dayname_top = 750;
my $margin_top  = 700;
my $cell_width  = 80;   # width of each day column
my $cell_height = 60;   # height of each week row
my $start_x     = 50;   # left margin
my $start_y     = $margin_top; # top margin
my $current_y   = $start_y;

my $draw_daynames = sub {
    my ($pdf, $page, $y_dayname_top, $cell_width, $cell_height) = @_;

    my $daynames = [ map { $dayname{$_} } sort { $a <=> $b } keys %dayname ];

    my $text = $page->text();
    $text->font($pdf->corefont('Helvetica-Bold'), 12);

    for my $col (0..6) {
        my $x = 50 + $col * $cell_width;
        my $y = $y_dayname_top;

        # Draw cell border
        my $gfx = $page->gfx();
        $gfx->strokecolor('black');
        $gfx->rect($x, $y - $cell_height, $cell_width, $cell_height);
        $gfx->stroke();

        # Draw text centered in cell
        my $txt_width = $text->advancewidth($daynames->[$col]);
        my $x_text = $x + ($cell_width - $txt_width) / 2;
        my $y_text = $y - ($cell_height - 12)/2; # 12 = font size
        $text->translate($x_text, $y_text);
        $text->text($daynames->[$col]);
    }
};

my $draw_callback = sub {
    my ($day, $week, $wday, $items) = @_;

    # Skip empty cells (prev/next month)
    return unless defined $day;

    # Calculate cell top-left coordinates
    my $x = $start_x + $wday * $cell_width;
    my $y = $start_y - $week * $cell_height;

    # Draw cell border
    my $rect = $page->gfx();
    $rect->strokecolor('black');
    $rect->linewidth(0.5);
    $rect->rect($x, $y - $cell_height, $cell_width, $cell_height);
    $rect->stroke();

    # Draw day number in top-left of cell
    $text->translate($x + 2, $y - 15);  # slight margin inside cell
    $text->text("$day");

    # Draw events inside the cell, below day number
    my $line_y = $y - 30;  # start below day number
    foreach my $event (@$items) {
        $text->translate($x + 2, $line_y);
        $text->text($event);
        $line_y -= 12;  # line spacing for each event
    }
};

$draw_daynames->($pdf, $page, $margin_top + 75, $cell_width, $cell_height);

calendar_maker(
    'output_style' => 'pdf_grid', 
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

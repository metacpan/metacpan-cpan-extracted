use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;
require Tk::LabFrame;

BEGIN { use_ok('Tk::ColorPicker') };

createapp;

my $picker;
if (defined $app) {
	my $entry;
	my $frame = $app->Frame(
		-width => 200,
		-height => 100,
	)->pack(-fill => 'both');
	my $bframe = $frame->LabFrame(
		-label => 'History',
	)->pack(-fill => 'x');
	$bframe->Button(
		-text => 'Add',
		-command => sub {
			my $txt = $entry->get;
			$picker->HistoryAdd($txt);
		}
	)->pack(
		-side => 'left',
	);
	$bframe->Button(
		-text => 'Clear',
		-command => sub { $picker->HistoryReset }
	)->pack(
		-side => 'left',
	);
	my $var = '';
	my $lab = $frame->Label(
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2,
	);
	$entry = $frame->Entry(
		-textvariable => \$var,
	)->pack(
		-fill => 'both',
		-padx => 2,
		-pady => 2,
	);
	$picker = $frame->ColorPicker(
		-updatecall => sub { 
			$var = shift;
			$lab->configure(-background => $var);
		},
		-depthselect => 1,
		-historyfile => 't/colorentry_history',
	)->pack(
		-fill => 'both',
		-padx => 2,
		-pady => 2,
	);
	$entry->bind('<Key>', sub { $picker->put($entry->get) });
}

push @tests, (
	[ sub { return defined $picker }, 1, 'ColorPicker widget created' ],
);


starttesting;

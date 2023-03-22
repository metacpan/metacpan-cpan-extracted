use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::PopColor') };

createapp;

my @padding = (-padx => 2, -pady => 2);

my $pop;
if (defined $app) {
	my $frame = $app->Frame(
		-width => 200,
		-height => 100,
	)->pack(-fill => 'both');
	my $button = $frame->Button(
		-width => 32,
		-command => sub { $pop->popFlip },
	)->pack(@padding,
		-fill => 'x',
	);
	my $label = $frame->Label(
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(@padding,
		-fill => 'x'
	);
	$pop = $frame->PopColor(
		-depthselect => 1,
		-historyfile => 't/colorentry_history',
		-updatecall => sub {
			my $color = shift;
			$button->configure(-text => $color);
			$label->configure(-background => $color);
		},
		-widget => $frame,
	);

}

push @tests, (
	[ sub { return defined $pop }, 1, 'PopColor widget created' ],
);


starttesting;

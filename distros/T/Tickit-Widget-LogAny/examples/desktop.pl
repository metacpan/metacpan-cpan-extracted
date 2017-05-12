#!/usr/bin/env perl
use strict;
use warnings;

use Log::Any qw($log);

use Tickit;
use Tickit::Widget::LogAny;
use Tickit::Widget::Layout::Desktop;

my $desktop = Tickit::Widget::Layout::Desktop->new;
my $tickit = Tickit->new(
	root => $desktop,
		# root => 
);
$log->debug("This is a debug message");
$log->debug("This message $_") for 1..5;
$tickit->later(sub {
my $panel = $desktop->create_panel(
	label => 'something',
	left => 3,
	top => 3,
	lines => 15,
	cols => 60
);
	$panel->add(my $w = Tickit::Widget::LogAny->new(
	));
});
$tickit->run;

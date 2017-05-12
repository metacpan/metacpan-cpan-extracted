#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Placegrid;
use Tickit::Widget::Layout::Desktop;

my $tickit = Tickit->new;
my $desktop = Tickit::Widget::Layout::Desktop->new;
$tickit->later(sub {
	my $left = int($desktop->window->cols * rand);
	my $top = int($desktop->window->lines * rand);
	my $cols = 20 + int(10 * rand);
	my $lines = 5 + int(20 * rand);
	$left = $desktop->window->cols - $cols if $left + $cols >= $desktop->window->cols;
	$top = $desktop->window->lines - $lines if $top + $lines >= $desktop->window->lines;
	$desktop->create_panel(
		label => 'widget',
		left => $left,
		top => $top,
		cols => $cols,
		lines => $lines,
	)->add(Tickit::Widget::Placegrid->new);
});
$tickit->set_root_widget($desktop);
$tickit->run;

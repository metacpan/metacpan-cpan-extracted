#!/usr/bin/env perl
use strict;
use warnings;

use Tickit;
use Tickit::Widget::Table;
use Tickit::Widget::VBox;
use Tickit::Widget::Static;

my $t = Tickit->new;

my $vbox = Tickit::Widget::VBox->new;
my $static = Tickit::Widget::Static->new(
	text => 'Select items with space, and update this text with enter',
	align => 'left',
	valign => 'middle'
);
$vbox->add($static);
my $tbl = Tickit::Widget::Table->new(
	multi_select => 1,
	on_activate => sub {
		my ($indices, $items) = @_;
		if(@$items) {
			$static->set_text("Selected these: " . join(', ', map $_->[0], @$items));
		} else {
			$static->set_text("No items selected");
		}
	},
	columns => [
		{ label => 'Name' },
		{ label => 'Value', width => 0 },
	]
);
my $idx = 0;
$tbl->adapter->push([
	map [ $_ => $idx++ ], qw(cat dog lemming rabbit gnu springbok)
]);
$vbox->add($tbl, expand => 1);
$t->set_root_widget($vbox);
$t->run;


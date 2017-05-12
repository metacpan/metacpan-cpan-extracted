#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;
use Tickit::Widget::HBox;
use Tickit::Widget::Table::Paged;
use Tickit::Async;
my $tickit = Tickit::Async->new;
Tickit::Style->load_style(<<'EOF');
Static { fg: "red"; }
Static:highlight { fg: "green"; b: true; bg: "blue"; }
EOF

my $mktbl = sub {
	my $tbl = Tickit::Widget::Table::Paged->new;
	$tbl->{row_offset} = 0;
	$tbl->add_column(
		label => 'Left',
		align => 'left',
		width => 8,
	);
	$tbl->add_column(
		label => 'Second column',
		align => 'centre'
	);
	$tbl->add_column(
		label => 'Widget column',
		type => 'widget',
		# We'll take care of creating our own widgets
		factory => sub {
			my $win = shift;
			my $w = Tickit::Widget::Static->new(text => 'new!');
			$w->set_window($win);
			$w
		},
		align => 'left'
	);
	$tbl->add_column(
		label => 'Right column',
		align => 'right'
	);

	$tbl->add_row(sprintf('line%04d', $_), sprintf("col2 line %d", $_), sub {
		shift->set_text(''.localtime);
	}, "third column!") for 1..200;
	$tbl;
};
my $vb = Tickit::Widget::VBox->new;
my $top = Tickit::Widget::HBox->new;
$vb->add($top, expand => 2);
$top->add($mktbl->(), expand => 3);
$top->add($mktbl->(), expand => 1);
my $right = Tickit::Widget::HBox->new;
$vb->add($mktbl->(), expand => 1);
$tickit->set_root_widget($vb);
$tickit->run;

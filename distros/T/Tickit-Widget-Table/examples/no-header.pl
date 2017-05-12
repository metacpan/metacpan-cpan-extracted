#!/usr/bin/env perl
use strict;
use warnings;

use Tickit;
use Tickit::Widget::Table;

my $tbl;
$tbl = Tickit::Widget::Table->new(
	on_activate => sub {
		$tbl->header_visible
		? $tbl->hide_header
		: $tbl->show_header
	}
);
$tbl->hide_header;
$tbl->add_column(
	label => 'List of options',
	align => 'left',
	width => 8,
);
$tbl->adapter->push([ map ["option $_"], 1..100 ]);
Tickit->new(root => $tbl)->run;

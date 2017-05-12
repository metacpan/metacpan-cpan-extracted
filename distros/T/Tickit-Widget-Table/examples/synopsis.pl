#!/usr/bin/env perl
use strict;
use warnings;

use Tickit;
use Tickit::Widget::Table;

my $tbl = Tickit::Widget::Table->new;
$tbl->add_column(
	label => 'Left',
	align => 'left',
	width => 8,
);
$tbl->add_column(
	label => 'Second column',
	align => 'centre'
);
$tbl->adapter->push([ map [qw(left middle)], 1..100 ]);
Tickit->new(root => $tbl)->run;

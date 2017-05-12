#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Widget::Table::Paged;
use Tickit;
Tickit::Style->load_style(<<'EOF');
Table::Paged {
 fg: "white";
 header-fg: "red";
 header-b: true;
 highlight-fg: "white";
 highlight-b: true;
 highlight-bg: 18;
 scrollbar-fg: "black";
}
EOF

my $tbl = Tickit::Widget::Table::Paged->new;
$tbl->{row_offset} = 0;
$tbl->add_column(
	label => 'Left',
	align => 'left',
	width => 8,
);
$tbl->add_column(
	label => 'Second column',
	align => 'left'
);
$tbl->add_column(
	label => 'Right column',
	align => 'right'
);

$tbl->add_row(sprintf('line%04d', $_), sprintf("col2 line %d", $_), "third column") for 1..200;
Tickit->new(root => $tbl)->run;


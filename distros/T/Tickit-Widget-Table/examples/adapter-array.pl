#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit::DSL qw(:async);

vbox {
	my $static;
	my $tbl;
	entry {
		my ($entry, $search) = @_;
		$static->set_text("Search for [$search]");
		my $re = qr/$search/i;
		$tbl->filter(sub { shift->[0] =~ $re });
		$tbl->unselect_hidden_rows;
	};
	$static = static 'Press TAB to switch between table and input box';
	$tbl = customwidget {
		my $w = Tickit::Widget::Table->new(
			multi_select => 1,
		);
		$w->add_column(
			label => 'Item',
		);
		my $adapter = $w->adapter;
		$adapter->insert(0, [map [$_], map "line $_", 1..200]);
		$w
	} expand => 1;
};
tickit->run;

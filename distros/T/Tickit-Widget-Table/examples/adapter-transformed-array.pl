#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit::DSL qw(:async);
use POSIX qw(strftime);

vbox {
	my $static;
	my $tbl;
	$tbl = customwidget {
		my $w = Tickit::Widget::Table->new(
		);
		$w->add_column(
			label => 'ID',
			align => 'right',
			width => 8
		);
		$w->add_column(
			label => 'Created',
			align => 'right',
			width => 20,
			transform => sub {
				my ($row, $col, $cell) = @_;
				Future->wrap(
					String::Tagged->new(
						strftime '%Y-%m-%d %H:%M:%S', localtime $cell
					)
					->apply_tag( 0, 4, b => 1)
					->apply_tag( 5, 2, b => 1)
					->apply_tag( 8, 2, b => 1)
					->apply_tag(11, 2, fg => 2)
					->apply_tag(14, 2, fg => 4)
					->apply_tag(17, 2, fg => 1)
				)
			}
		);
		$w->add_column(
			label => 'Description',
			align => 'left',
		);
		my $adapter = $w->adapter;
		$adapter->insert(0, [
			map [
				$_, (time - 86400) + (3600 * $_ + 600 * rand), "Some description for line $_"
			], 1..200
		]);
		$w
	} expand => 1;
};
tickit->run;

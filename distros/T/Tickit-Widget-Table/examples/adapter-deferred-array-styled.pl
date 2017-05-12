#!/usr/bin/env perl
use strict;
use warnings;
{
package DeferredArray;
use parent qw(Adapter::Async::OrderedList::Array);
use Tickit::DSL qw(:async);

sub defer_by(&$) {
	my ($code, $delay) = @_;
	my $f = loop->new_future;
	tickit->timer(
		after => $delay,
		sub { $f->done($code->()) }
	);
	$f
}

sub get {
	my ($self, %args) = @_;
	my @items = @{$self->{data}}[@{$args{items}}];
	my $f;
	if(my $code = $args{on_item}) {
		my @idx = @{$args{items}};
		$f = repeat {
			my $item = shift;
			defer_by { $code->(shift(@idx), $item) } 0.08;
		} foreach => [ @items ];
	}
	$f ||= Future->wrap;
	my $task = $f->then(sub {
		defer_by { \@items } 0.5 + rand;
	});
	$task->on_ready(sub { undef $task });
}

}
use Tickit::DSL qw(:async);
use POSIX qw(strftime);

vbox {
	my $static;
	my $tbl;
	$tbl = customwidget {
		my $w = Tickit::Widget::Table->new(
			multi_select => 1,
			adapter => DeferredArray->new,
			item_transformations => [
				sub {
					my ($row, $item) = @_;
					my @copy = @$item;
					$copy[1] = time;
					Future->wrap(\@copy);
				}
			],
		);
		$w->add_column(
			label => 'ID',
			align => 'right',
			width => 8
		);
		$w->add_column(
			label => 'Created',
			align => 'center',
			width => 20,
			transform => sub {
				my ($row, $col, $cell) = @_;
				Future->wrap(
					String::Tagged->new(
						strftime '%Y-%m-%d %H:%M:%S', localtime $cell
					)
					->apply_tag( 0, 4, fg => 4)
					->apply_tag( 4, 1, fg => 8)
					->apply_tag( 5, 2, fg => 4)
					->apply_tag( 7, 1, fg => 8)
					->apply_tag( 8, 2, fg => 4)
					->apply_tag(11, 2, fg => 2)
					->apply_tag(14, 2, fg => 2)
					->apply_tag(17, 2, fg => 2)
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
				$_, 0, "Some description for line $_"
			], 1..200
		]);
		my $update = sub {
			$adapter->splice(0, 0, [
				map [
					$_, 0, "New item",
				], 1..(15 * rand)
			]);
		};
		my $timed;
		$timed = sub {
			tickit->timer(
				after => 3 * rand,
				sub {
					$update->();
					$timed->();
				}
			)
		};
		$timed->();
		$w
	} expand => 1;
	statusbar { };
};
tickit->run;

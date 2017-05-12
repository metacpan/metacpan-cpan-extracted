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
	$f->then(sub {
		defer_by { \@items } 0.5 + rand;
	})
}

}
use Tickit::DSL qw(:async);

vbox {
	my $static;
	my $tbl;
	$tbl = customwidget {
		my $w = Tickit::Widget::Table->new(
			multi_select => 1,
			adapter => DeferredArray->new,
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

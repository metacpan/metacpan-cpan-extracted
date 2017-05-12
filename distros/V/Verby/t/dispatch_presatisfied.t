#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 61;
use Test::Deep;
use Test::MockObject;
use List::MoreUtils qw/uniq/;
use Verby::Config::Data;

my $m;
BEGIN { use_ok($m = "Verby::Dispatcher") }

foreach my $s ([0, 2], [0, 1], [2], [0, 1, 2], [0], [1]){ # not quite random. Note that 0 and 2 don't care which comes first
	my $n = do { my %s; @s{@$s} = (); [ grep { not exists $s{$_} } 0 .. 3 ] }; # the inverse of $s

	my @items = map { Test::MockObject->new } 1 .. 4;
	$_->set_always(provides_cxt => undef) for @items;
	$_->set_always(is_satisfied => undef) for @items[@$n];
	$_->set_always(is_satisfied => 1) for @items[@$s];
	$_->set_list(depends => ()) for @items;
	$items[1]->set_list(depends => @items[0, 2]);
	$items[3]->set_list(depends => ($items[1]));

	my @log;
	$_->mock(do => sub { push @log, shift }) for @items;

	isa_ok(my $d = $m->new, $m);

	my $cfg = Verby::Config::Data->new;
	$cfg->data->{logger} = Test::MockObject->new;
	$d->config_hub($cfg);

	$cfg->logger->set_true($_) for qw/info debug/;

	can_ok($d, "add_step");
	$d->add_step($_) for @items;

	can_ok($d, "do_all");
	$d->do_all;

	ok($d->is_satisfied($_), "step satisfied") for @items;

	is(@log, @$n, (scalar @$n) . " steps executed");
	is((uniq @log), @$n, "each step is distinct");

	cmp_deeply([ @log ], [ @items[@$n] ], "execution log order is correct");
}

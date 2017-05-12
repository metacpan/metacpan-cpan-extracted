#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Deep;
use Test::MockObject;
use List::MoreUtils qw/uniq/;
use Verby::Config::Data;

use POE;

my $m;
BEGIN { use_ok($m = "Verby::Dispatcher") }

my @items = map { Test::MockObject->new } 1 .. 4;
foreach my $meth (qw/is_satisfied provides_cxt/){
	$_->set_always($meth => undef) for @items;
}
$_->set_list(depends => ()) for @items;
$items[1]->set_list(depends => @items[0, 2]);
$items[3]->set_list(depends => ($items[1]));

my @log;

foreach my $item ( @items ) {
	$item->mock( 'do' => sub {
		my $state = shift;
		POE::Session->create(
			inline_states => {
				map {
					my $event = $_;
					"_$event" => sub { push @log, [ $event, $state ] }
				} qw/start stop/,
			},
		);
	});
}

isa_ok(my $d = $m->new, $m);

my $cfg = Verby::Config::Data->new;
$cfg->data->{logger} = Test::MockObject->new;
$d->config_hub($cfg);

$cfg->logger->set_true($_) for qw/info debug/;

can_ok($d, "add_step");
$d->add_step($_) for @items;

isa_ok($d->step_set, "Set::Object");
cmp_deeply([ $d->step_set->members ], bag(@items), "step set contians items");

isa_ok($d->satisfied_set, "Set::Object");
cmp_deeply([ $d->satisfied_set->members ], [], "selected set contains no items");

can_ok($d, "do_all");
$d->do_all;

ok($d->is_satisfied($_), "step satisfied") for @items;

$_->called_ok("do") for @items;

is(@log, 8, "4 steps executed, in 8 events");
is((uniq map { $_->[1] } @log), 4, "each step is distinct");

my @finished = map { $_->[1] } grep { $_->[0] eq "stop" } @log;

cmp_deeply([ @finished[0,1] ], bag(@items[0,2]), "first two steps are in either order");
cmp_deeply([ @finished[2,3] ], [ @items[1,3] ], "last steps are stricter");

foreach my $item (@items){
	my ($start_cxt, $finish_cxt) = map { $_->[2] } grep { $_->[1] == $item } @log;
	is($start_cxt, $finish_cxt, "context when starting and finishing was the same");
}

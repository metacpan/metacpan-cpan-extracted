#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More tests => 20;
use Test::Deep;
use Test::MockObject;
use List::MoreUtils qw/uniq/;

use Verby::Config::Data;

my $m; BEGIN { use_ok($m = "Verby::Dispatcher") };

my @items = map { Test::MockObject->new } 1 .. 4;
foreach my $meth (qw/is_satisfied provides_cxt/){
	$_->set_always($meth => undef) for @items;
}
$_->mock(depends => sub { wantarray ? () : [] }) for @items;
$items[1]->mock( depends => sub { wantarray ? @items[0, 2] : [ @items[0, 2] ] });
$items[3]->mock( depends => sub { wantarray ? $items[1] : [ $items[1] ] });

my @log;
$_->mock(do => sub { push @log, shift }) for @items;

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

is(@log, 4, "4 steps executed");
is((uniq @log), 4, "each step is distinct");

cmp_deeply([ @log[0,1] ], bag(@items[0,2]), "first two steps are in either order");
cmp_deeply([ @log[2,3] ], [ @items[1,3] ], "last steps are stricter");



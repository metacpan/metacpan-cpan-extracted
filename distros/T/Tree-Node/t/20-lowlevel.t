#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

use_ok("Tree::Node", 0.06, ':p_node');

my $n = p_new(1);

ok(defined $n, "p_new returned an integer");
is(p_child_count($n), 1, "p_child_count");

is(p_get_child($n, 0), 0, "p_get_child == 0");
eval {
  $@ = undef;
  p_get_child($n, 1);
};
ok($@, "boundary error");
is(p_get_child_or_null($n, 1), 0, "p_get_child == 0");


my $m = p_new(2);
ok(($m+0) != 0, "p_new returned an integer");
is(p_child_count($m), 2, "p_child_count");

is(p_get_child($m, 0), 0, "p_get_child == 0");
p_set_child($m, 0, $n);
is(p_get_child($m, 0), $n, "p_get_child == n");

is(p_child_count(p_get_child($m, 0)), p_child_count($n));

eval{
  p_destroy(0);
  p_destroy($n);
  p_destroy($m);
};

ok(!$@, "no errors in p_destroy");

$n = p_new(1);
$m = p_new(4);
p_set_child($n, 0, $m);

undef $m;
$m = p_get_child($n, 0);

ok(defined $m);
is(p_child_count($m), 4);

eval{
  p_destroy($n);
  p_destroy($m);
};

ok(!$@, "no errors in p_destroy");

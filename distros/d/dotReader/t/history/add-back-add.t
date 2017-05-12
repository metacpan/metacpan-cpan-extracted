#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('List::History') };

my %mspec = (
  day => 1,
  hour => 1,
  dog => 'fido',
  );
my $hist = List::History->new(moment_spec => \%mspec);
ok($hist, 'constructor');
isa_ok($hist, 'List::History');


is($hist->current_pos, -1);
ok(my $m1 = $hist->add(),  'add');
ok(!$hist->has_current);
is($hist->current_pos, 1);
ok(my $m2 = $hist->remember(), 'remember');
ok($hist->has_current);
is($hist->current_pos, 1);
ok(my $m1b = $hist->back(), 'back');
ok($hist->has_current);
is($hist->current_pos, 0);
is($m1b, $m1, 'got it back');
if(1) {
  ok(my $m2b = $hist->fore, 'forward');
  ok($hist->has_current);
  is($hist->current_pos, 1);
  is($m2b, $m2, 'got it back');
  ok(my $m1c = $hist->back(), 'back');
  ok($hist->has_current);
  is($hist->current_pos, 0);
  is($m1c, $m1, 'got it back');
}
ok(my $m2_1 = $hist->add(),  'add');
ok(!$hist->has_current);
is($hist->current_pos, 1);
ok($m2_1 != $m2, 'different');

{
  my @list = $hist->get_list;
  ok(@list == 1, 'list');
  is_deeply(\@list, [$m2_1]);
}

ok($hist->back(), 'back');
ok(! $hist->has_prev, 'no prev');

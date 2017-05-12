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

# now, but leaving it
ok(my $m1 = $hist->add(),  'add');
ok(!$hist->has_current);
is($hist->current_pos, 1);

# going back, but first remember where we are
ok(my $m2 = $hist->remember(), 'remember');
ok($hist->has_current);
is($hist->current_pos, 1);

# and go back
ok(my $m1b = $hist->back(), 'back');
ok($hist->has_current);
is($hist->current_pos, 0);
is($m1b, $m1, 'got it back');
is(scalar($hist->get_list), 2);

# and now foreward
ok(my $m2b = $hist->foreward(),  'foreward');
ok($hist->has_current);
is($hist->current_pos, 1);
is($m2b, $m2, 'got it back');
is(scalar($hist->get_list), 2);

# let's do back again
ok(my $m1c = $hist->back(), 'back');
ok($hist->has_current);
is($hist->current_pos, 0);
is($m1c, $m1, 'got it back');

{
  my @list = $hist->get_list;
  ok(@list == 2, 'list');
  is_deeply(\@list, [$m1, $m2]);
}


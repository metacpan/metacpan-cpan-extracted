#!/usr/bin/perl

use warnings;
use strict;

use Test::More ('no_plan');

BEGIN { use_ok('MultiTask::Manager') };
BEGIN { use_ok('MultiTask::Minion') };

my $added = 0;
my $master = MultiTask::Manager->new(
  on_add => sub {
    $added++;
  },
);

my @counters = (0)x10;
for my $i (0..9) {
  my $minion = MultiTask::Minion->make(sub {
    my $limit = 10 - $i;
    work => sub {
      my $self = shift;
      $self->quit if(++$counters[$i] >= $limit);
      return($counters[$i], $i);
    }
  });
  $master->add($minion);
}
is($added, 10, 'added 10 minions');
my $is = 0;
my $rem = 10;
my @counter_is = (0)x10;
while($master->has_work) {
  my ($count, $i) = $master->work;
  #warn "$i $is";
  is($i, $is, 'work order') or die;
  is($count, ++$counter_is[$i], 'work ok');
  if(++$is >= $rem) {
    $is = 0;
    $rem--;
  }
}
is_deeply(\@counters, [reverse(1..10)]);


# vim:ts=2:sw=2:et:sta:nowrap

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
my $maker = sub {
  my ($i) = @_;
  MultiTask::Minion->make(sub {
    work => sub {
      my $self = shift;
      $self->quit if(++$counters[$i] >= $i);
      return($counters[$i], $i);
    }
  });
};

eval {
foreach my $i (8,1,0,0,2,7) {
  my $minion = $maker->($i);
  $master->add($minion);
  $master->has_work and $master->work;
  $minion->quit if($i % 2);
}
};
ok(!$@, 'alive');

is($added, 6, 'added minions');
eval {
while($master->has_work) {
  $master->work;
}
};
ok(!$@, 'alive');


# vim:ts=2:sw=2:et:sta:nowrap

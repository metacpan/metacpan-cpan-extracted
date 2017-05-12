#!/usr/bin/perl

use warnings;
use strict;

use Test::More ('no_plan');

BEGIN { use_ok('MultiTask::Minion') };

{
  my $worker = MultiTask::Minion->new;
  isa_ok($worker, 'MultiTask::Minion', 'isa');
  isnt(ref($worker), 'MultiTask::Minion', 'subclassed');
  can_ok($worker, 'done');
  can_ok($worker, 'quit');
  # not sure we need this
  # can_ok($worker, 'worksub');
  # can_ok($worker, '--set_worksub');
  ok(! $worker->can('work'),   'no work');
  ok(! $worker->can('start'),  'no start');
  ok(! $worker->can('finish'), 'no finish');
}

{
  my $worker = MultiTask::Minion->make(sub {
    start => sub {
    },
    work => sub {
    },
    finish => sub {
    },
  });
  can_ok($worker, 'start');
  can_ok($worker, 'work');
  can_ok($worker, 'finish');
}

# vim:ts=2:sw=2:et:sta:nowrap

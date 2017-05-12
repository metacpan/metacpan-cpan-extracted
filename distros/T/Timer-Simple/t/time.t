# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Time::Local (); # core

eval 'use Test::MockObject 1.09 (); 1'
  or plan skip_all => 'Test::MockObject required for this test';

eval 'use Test::MockTime 0.12 (); 1'
  or plan skip_all => 'Test::MockObject required for this test';

my ($start, $time, $elapsed) = Time::Local::timegm(0, 0, 12, 22, 05, 2010);
my (@gettimeofday, $tv_interval);

my $mock = Test::MockObject->new;
$mock->fake_module('Time::HiRes',
  gettimeofday => sub { @gettimeofday },
  tv_interval  => sub { $tv_interval  },
);


my $mod = 'Timer::Simple';
eval "require $mod" or die $@;

subtest integer => sub {
  Test::MockTime::set_fixed_time($start);
  my $t = new_ok($mod, [hires => 0]);

  elapse(12);

  is($t->elapsed,             12,  'expected elapsed time');
  is(scalar $t->hms,   '00:00:12', 'hms string');
  is_deeply([$t->hms], [0, 0, 12], 'hms list');

  elapse(3600 + 120 + 15); # 1h 2m 15s

  is($t->elapsed,           3735,  'expected elapsed time');
  is(scalar $t->hms,   '01:02:15', 'hms string');
  is_deeply([$t->hms], [1, 2, 15], 'hms list');
  is($t->string, '3735s (01:02:15)', 'string');

  is(Timer::Simple::format_hms($t + 12), '01:02:27', 'format_hms');
};

subtest hires => sub {
  eval 'require Time::HiRes'
    or plan skip_all => 'Time::HiRes required for these tests';

  @gettimeofday = ($start, 0);
  my $t = new_ok($mod);

  elapse(12, 345);

  is($t->elapsed,             12.345000,  'expected elapsed time');
  is(scalar $t->hms,   '00:00:12.345000', 'hms string');
  is_deeply([$t->hms], [0, 0, 12.345000], 'hms list');

  elapse(3600 + 120 + 15, 987654); # 1h 2m 15s, fraction

  is($t->elapsed,           3735.987654,  'expected elapsed time');
  is(scalar $t->hms,   '01:02:15.987654', 'hms string');
  is_deeply([$t->hms], [1, 2, 15.987654], 'hms list');
  is($t->string, '3735.987654s (01:02:15.987654)', 'string');

  is(Timer::Simple::format_hms($t + 12), '01:02:27.987654', 'format_hms');
};

done_testing;

sub elapse {
  my ($elapsed, $fraction) = (@_, 0);
  @gettimeofday = ($start + $elapsed, $fraction);
  $tv_interval = $elapsed + "0.$fraction";
  Test::MockTime::set_fixed_time($time = $start + $elapsed);
}

use strict;

BEGIN { $ENV{LC_ALL} = 'C'; require POSIX; POSIX::setlocale(POSIX::LC_NUMERIC()) } # Test::Approx does not respect locales

use Test::More tests => 16;
use Test::Approx;
use WWW::Jawbone::Up::Mock;

my $up = WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 's3kr3t');

my $score = $up->score('20130414');

my $move = $score->move;

is($move->steps, 9885, 'steps');
is_approx_num($move->distance, 7.55, 'distance', 0.01);
is_approx_int($move->active_time / 60,    85,   'active time');
is_approx_int($move->longest_active / 60, 15,   'longest active');
is_approx_int($move->longest_idle / 60,   150,  'longest idle');
is_approx_int($move->total_burn,          2809, 'total burn');
is_approx_int($move->active_burn,         608,  'active burn');
is_approx_int($move->resting_burn,        2201, 'resting burn');

my $sleep = $score->sleep;

is($sleep->bedtime, 10, 'bed time');
is_approx_int($sleep->asleep / 60,        423, 'time asleep');
is_approx_int($sleep->light / 60,         170, 'time light sleeping');
is_approx_int($sleep->time_to_sleep / 60, 11,  'time to sleep');
is_approx_int($sleep->awake / 60,         34,  'time awake');
is_approx_int($sleep->deep / 60,          253, 'time deep sleeping');
is_approx_int($sleep->in_bed / 60,        457, 'time in bed');
is($sleep->awakenings, 2, 'times woken up');

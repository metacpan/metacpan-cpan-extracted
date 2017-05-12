use strict;

BEGIN { $ENV{LC_ALL} = 'C'; require POSIX; POSIX::setlocale(POSIX::LC_NUMERIC()) } # Test::Approx does not respect locales

use Test::More tests => 7;
use Test::Approx;
use WWW::Jawbone::Up::Mock;

my $up = WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 's3kr3t');

my @ticks = $up->band(1365980000, 1365980060);

is($ticks[0]->active_time, 15, 'active time');
ok(!$ticks[0]->aerobic, 'not aerobic');
is_approx_num($ticks[0]->calories, 1.55, 'calories', 0.01);
is($ticks[0]->distance, 25, 'distance');
is_approx_num($ticks[0]->speed, 1.00, 'speed', 0.01);
is($ticks[0]->steps, 31,         'steps');
is($ticks[0]->time,  1365980040, 'time');

use strict;

BEGIN { $ENV{LC_ALL} = 'C'; } # Test::Approx does not respect locales

use Test::More tests => 7;
use Test::Approx;
use WWW::Jawbone::Up::Mock;

my $up = WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 's3kr3t');

my ($workout) = $up->workouts('20130401');

is_approx_int($workout->time / 60, 29, 'time');
is_approx_num($workout->distance, 2.16, 'distance', 0.01);
is($workout->steps, 3221, 'steps');
is_approx_num($workout->intensity, 'easy', 'intensity');
is_approx_int($workout->total_burn, 236, 'total burn');
ok($workout->complete, 'complete');
isa_ok($workout->completed, 'DateTime', 'time inflation');

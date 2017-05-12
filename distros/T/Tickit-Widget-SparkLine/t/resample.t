use strict;
use warnings;

use Test::More;
use Tickit::Widget::SparkLine;

my $w = Tickit::Widget::SparkLine->new;
is($w->resample_mode('max'), $w, 'set resample mode');
is_deeply([ $w->resample(4 => 0,1,2,3,4,5,6,7) ], [1, 3, 5, 7], 'max is correct');
is_deeply([ $w->resample(2 => 0,1,2,3,4,5,6,7) ], [3, 7], 'max is correct');
is_deeply([ $w->resample(5 => 0,1,2,3,4,5,6,7) ], [1,3,4,6,7], 'max is correct');
is($w->resample_mode('min'), $w, 'set resample mode to min');
is_deeply([ $w->resample(4 => 0,1,2,3,4,5,6,7) ], [0, 2, 4, 6], 'min is correct');
is($w->resample_mode('average'), $w, 'set resample mode to avg');
is_deeply([ $w->resample(4 => 0,1,2,3,4,5,6,7) ],
[0.5, 2.5, 4.5, 6.5], 'avg is correct');

done_testing;


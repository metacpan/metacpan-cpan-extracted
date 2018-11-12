#!perl

use Test::Most;

use lib 't/lib';
use MooTest;

ok my $o = MooTest->new;

lives_ok {
    ++$o->foo->[0];
} 'allowed change of array element';

is $o->foo->[0] => 2, 'element was changed';

dies_ok {
    ++$o->bar->[0];
} 'disallowed change of array element';

is $o->bar->[0] => 1, 'element was not changed';

done_testing;

use strict;
use warnings;

use Test::Tester;
use Test::More;
use Test::Deep::Matcher;
use Test::Stub::Generator qw(make_subroutine);

my $some_method = make_subroutine(
    { expects => [is_integer], return => [0] },
    { is_repeat => 1 },
);

check_test(
    sub {
        &$some_method(1);
    },
    {
        ok    => 1,
        depth => 2,
    },
    'succeed'
);

check_test(
    sub {
        &$some_method('a');
    },
    {
        ok    => 0,
        depth => 2,
    },
    'failed'
);

done_testing;

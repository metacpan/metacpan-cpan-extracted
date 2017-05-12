# Testing the max_parallel() function

use strict;
use warnings;

use t::MyTest;
use Test::More;
use Test::ParallelSubtest;

my $default = 4;

is $Test::ParallelSubtest::MaxParallel, $default, "get default via variable";
is max_parallel,                    $default, "get default via function";

is max_parallel,   $default, "reading max_parallel doesn't set it";
is max_parallel(), $default, "reading with brackets";

is max_parallel(15), $default, "setting returns old value";
is max_parallel, 15, "setting takes effect";
is $Test::ParallelSubtest::MaxParallel, 15, "variable updated";

{
    local $Test::ParallelSubtest::MaxParallel = 8;

    is max_parallel(10), 8, "local set variable takes effect";
    is max_parallel(), 10,  "can still be updated via the function";
    is $Test::ParallelSubtest::MaxParallel, 10, "function still tied to variable";
}
is $Test::ParallelSubtest::MaxParallel, 15, "local really was";
is max_parallel(), 15, "variable localization undid function setting";

done_testing;

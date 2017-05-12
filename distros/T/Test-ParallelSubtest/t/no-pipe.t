# Test operation in the face of pipe() not working.

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest no_pipe => <<END;
    BEGIN {
        *CORE::GLOBAL::pipe = sub { return }
    }

    use Test::ParallelSubtest;
    use Test::More tests => 2;

    bg_subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };
END

done_testing;


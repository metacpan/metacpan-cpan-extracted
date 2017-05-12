use strict;
use warnings;
use Test::More;
use Test::Flatten;

subtest 'with done_testing (old style)' => sub {
    pass 'ok';
    done_testing;
};

done_testing;

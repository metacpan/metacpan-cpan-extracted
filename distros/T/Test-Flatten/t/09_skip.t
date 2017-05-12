use strict;
use warnings;
use Test::More;
use Test::Flatten;

plan tests => 3;

SKIP: {
    subtest 'in the skip block' => sub {
        skip 'skip', 2;
        pass 'ok';
        fail 'ng';
    };
}

subtest 'within skip block' => sub {
    SKIP: {
        skip 'skip', 1;
        fail 'ng';
    }
};

done_testing;

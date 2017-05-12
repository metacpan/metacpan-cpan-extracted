use strict;
use warnings;
use Test::More;
use Test::Flatten;

plan tests => 3;

TODO: {
    local $TODO = 'todo';
    subtest 'in the TODO' => sub {
        pass 'ok';
        fail 'ng';
    };
}

subtest 'within TODO' => sub {
    TODO: {
        local $TODO = 'todo';
        fail 'ng';
    }
};

done_testing;

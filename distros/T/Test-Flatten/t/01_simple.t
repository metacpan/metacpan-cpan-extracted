use strict;
use warnings;
use Test::More;
use Test::Flatten;

pass 'ok';

subtest 'foo' => sub {
    pass 'ok';
};

subtest 'bar' => sub {
    pass 'ok';
    subtest 'baz' => sub {
        pass 'ok';
    };
};

subtest 'argument (Test::More supported after 1.001004_001)' => sub {
    is $_[0], 'str';
}, 'str';

pass 'ok';

done_testing;

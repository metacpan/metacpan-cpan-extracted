use strict;
use warnings;
use Test::More;
use Test::Flatten;

plan tests => 6;

subtest 'plan tests' => sub {
    plan tests => 1;
    pass 'ok';
};

subtest 'plan tests' => sub {
    plan tests => 3;
    pass 'ok';
    pass 'ok';
    pass 'ok';
};

subtest 'plan skip_all' => sub {
    plan skip_all => "skip_all";
    pass 'ok';
    fail 'ng';
};

subtest 'plan skip_all' => sub {
    plan 'no_plan';
    pass 'ok';
    pass 'ok';
};

done_testing;

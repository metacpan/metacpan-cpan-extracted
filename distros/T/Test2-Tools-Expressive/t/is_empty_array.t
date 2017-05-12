#!perl -T

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 7;

use Test2::Tools::Expressive;

use Test2::API qw( intercept );

imported_ok( 'is_empty_array' );

subtest 'PASS: simple pass, no name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_array( [] ) };

    is(
        $events,
        array {
            event Ok => sub {
                call pass => 1;
                call effective_pass => 1;

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'PASS: simple pass, with name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_array( [], 'Is this thing empty?' ) };
    is(
        $events,
        array {
            event Ok => sub {
                call name => 'Is this thing empty?';
                call pass => 1;
                call effective_pass => 1;

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: hash reference' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_array( {} ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Expected ARRAY reference but got HASH.';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: hash reference, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_array( {}, 'Is this array empty?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Is this array empty?';
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Expected ARRAY reference but got HASH.';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: nonempty array' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_array( [ 2112 ] ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Array contains 1 element';

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => <<'EOF';
[
  2112
]
EOF
                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: nonempty array, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_array( [ 2112, 5150 ], 'Should be empty?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Should be empty?';
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Array contains 2 elements';

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => <<'EOF';
[
  2112,
  5150
]
EOF
                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


done_testing();

#!perl -T

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 7;

use Test2::Tools::Expressive;

use Test2::API qw( intercept );

imported_ok( 'is_nonempty_array' );

subtest 'PASS: simple pass, no name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_array( [ 'blah blah' ] ) };

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
    my $events = intercept { is_nonempty_array( [ 'look, stuff!' ], 'Is this thing nonempty?' ) };
    is(
        $events,
        array {
            event Ok => sub {
                call name => 'Is this thing nonempty?';
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
    my $events = intercept { is_nonempty_array( {} ) };
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
    my $events = intercept { is_nonempty_array( {}, 'Is this array nonempty?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Is this array nonempty?';
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


subtest 'FAIL: empty array' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_array( [] ) };
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
                call message => 'Array contains no elements';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: empty array, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_array( [], 'Should be nonempty?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Should be nonempty?';
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Array contains no elements';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


done_testing();

#!perl -T

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 7;

use Test2::Tools::Expressive;

use Test2::API qw( intercept );

imported_ok( 'is_nonempty_hash' );

subtest 'PASS: simple pass, no name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_hash( { foo => 'bar' } ) };

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
    my $events = intercept { is_nonempty_hash( { foo => 'bar' }, 'Is this thing nonempty?' ) };
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


subtest 'FAIL: array reference' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_hash( [] ) };
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
                call message => 'Expected HASH reference but got ARRAY.';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: array reference, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_hash( [], 'Is this hash nonempty?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Is this hash nonempty?';
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Expected HASH reference but got ARRAY.';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: empty hash' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_hash( {} ) };
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
                call message => 'Hash contains no entries.';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: empty hash, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonempty_hash( {}, 'Should be nonempty?' ) };
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
                call message => 'Hash contains no entries.';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


done_testing();

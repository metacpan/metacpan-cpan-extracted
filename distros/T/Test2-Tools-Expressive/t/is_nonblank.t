#!perl -T

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 7;

use Test2::Tools::Expressive;

use Test2::API qw( intercept );

imported_ok( 'is_nonblank' );

subtest 'PASS: simple pass, no name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonblank( 'bloofga' ) };

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
    my $events = intercept { is_nonblank( 'bloofga', 'Is this thing nonblank?' ) };
    is(
        $events,
        array {
            event Ok => sub {
                call name => 'Is this thing nonblank?';
                call pass => 1;
                call effective_pass => 1;

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: blank string' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonblank( '' ) };
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
                call message => 'Got an empty string';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: blank string, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_nonblank( '', 'Is this blank?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Is this blank?';
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Got an empty string';

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
    my $events = intercept { is_nonblank( {} ) };
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
                call message => 'Got a HASH reference';

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
    my $events = intercept { is_nonblank( [], 'Is this blank?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Is this blank?';
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Got an ARRAY reference';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};

done_testing();

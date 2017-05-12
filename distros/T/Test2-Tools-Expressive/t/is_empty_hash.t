#!perl -T

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 7;

use Test2::Tools::Expressive;

use Test2::API qw( intercept );

imported_ok( 'is_empty_hash' );

subtest 'PASS: simple pass, no name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_hash( {} ) };

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
    my $events = intercept { is_empty_hash( {}, 'Is this thing empty?' ) };
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
    my $events = intercept { is_empty_hash( [] ) };
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


subtest 'FAIL: hash reference, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_hash( [], 'Is this hash empty?' ) };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => 'Is this hash empty?';
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


subtest 'FAIL: nonempty hash' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_hash( { rush => 2112 } ) };
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
                call message => 'Hash contains 1 element';

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => <<'EOF';
{
  'rush' => 2112
}
EOF
                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


subtest 'FAIL: nonempty hash, with message' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_empty_hash( { yes => 90125, rush => 2112 }, 'Should be empty?' ) };
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
                call message => 'Hash contains 2 elements';

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => <<'EOF';
{
  'rush' => 2112,
  'yes' => 90125
}
EOF
                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
    );
};


done_testing();

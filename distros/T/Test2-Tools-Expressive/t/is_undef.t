#!perl -T

use strict;
use warnings;

use Test2::Bundle::Extended;
plan 5;

use Test2::Tools::Expressive;

use Test2::API qw( intercept );

imported_ok( 'is_undef' );


subtest 'PASS: simple pass, no name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_undef( undef ) };

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
        'is_undef without a name'
    );
};


subtest 'PASS: simple pass, with name' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_undef( undef, 'Is this thing undef?' ) };
    is(
        $events,
        array {
            event Ok => sub {
                call name => 'Is this thing undef?';
                call pass => 1;
                call effective_pass => 1;

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
        'is_undef with a name'
    );
};


subtest 'FAIL: no args passed' => sub {
    plan 1;

    my $LINE = __LINE__ + 1;
    my $events = intercept { is_undef() };
    is(
        $events,
        array {
            fail_events Ok => sub {
                call name => undef;
                call pass => 0;
                call effective_pass => 0;

                prop file => __FILE__;
                prop line => $LINE;
            };
            event Diag => sub {
                call message => 'Must pass a value to is_undef';

                prop file => __FILE__;
                prop line => $LINE;
            };
            end();
        },
        'is_undef with a name'
    );
};


subtest 'FAIL: various defined values' => sub {
    plan 12;

    my %defined_values = (
        'zero'       => 0,
        'one'        => 1,
        'scalar'     => q{Got down on the subway with my oldest friend Jean-Luc},
        'scalar ref' => \'Commemorated the occasion with his gin and my juice',
        'array ref'  => [ 'Luke, you got me thinking', qw( you're drunk all the time ) ],
        'hash ref'   => { No => 'with a chuckle', "I'm not drunk" => 'I feel so fine' },
    );

    while ( my ($desc,$value) = each %defined_values ) {
        my $LINE = __LINE__ + 1;
        my $events = intercept { is_undef( $value ) };
        is(
            $events,
            array {
                fail_events Ok => sub {
                    call name => undef;
                    call pass => 0;
                    call effective_pass => 0;

                    prop file => __FILE__;
                    prop line => $LINE;
                };
                end();
            },
            "is_undef: $desc without test name"
        );

        $LINE = __LINE__ + 1;
        $events = intercept { is_undef( $value, $desc ) };
        is(
            $events,
            array {
                fail_events Ok => sub {
                    call name => $desc;
                    call pass => 0;
                    call effective_pass => 0;

                    prop file => __FILE__;
                    prop line => $LINE;
                };
                end();
            },
            "is_undef: $desc with test name"
        );
    }
};


done_testing();

exit 0;

#!perl

use strict;
use warnings;

use PDL::Core qw(pdl);
use Test2::V0;
use Test2::Tools::PDL;

sub fail_details {
    my ( $name, $details ) = @_;
    unless ( ref($details) eq 'ARRAY' ) {
        $details = [$details];
    }

    event Fail => sub {
        call facet_data => hash {
            field info => array {
                map {
                    item hash {
                        field details => $_;
                        etc;
                    };
                    etc;
                    ();
                } @$details;
            };
            etc;
        };
        call name => $name;
    };
}

subtest pdl_ok => sub {
    my $events = intercept {
        def ok => ( pdl_ok( pdl( 1 .. 10 ) ), '1 arg pass' );
        def ok => ( pdl_ok( pdl( 1 .. 10 ), "simple pass" ), 'simple pass' );
        def ok => ( !pdl_ok( [ 1 .. 10 ], "type fail" ), 'type fail' );
        def ok => ( !pdl_ok( undef, "undef fail" ), 'undef fail' );
    };

    do_def;

    like(
        $events,
        array {
            event Ok => sub {
                call pass => T();
                call name => undef;
            };
            event Ok => sub {
                call pass => T();
                call name => 'simple pass';
            };
            fail_details( 'type fail',  qr/is not a piddle/ );
            fail_details( 'undef fail', qr/is not a piddle/ );
            end;
        },
        "got expected events"
    );
};

subtest pdl_is => sub {
    my $test_name = 'pdl(1..10)';

    my $events = intercept {
        def ok => ( pdl_is( pdl( 1 .. 10 ), pdl( 1 .. 10 ) ), '2 args pass' );
        def ok => (
            pdl_is( pdl( 1 .. 10 ), pdl( 1 .. 10 ), 'simple pass' ),
            'simple pass'
        );
        def ok => (
            !pdl_is( pdl( 1 .. 10 ), pdl( [ 1 .. 5 ] ), 'dimensions fail' ),
            'dimentions fail'
        );
        def ok => (
            !pdl_is(
                pdl( 1 .. 10 ),
                pdl( [ [ 1 .. 5 ], [ 6 .. 10 ] ] ),
                'dimensions fail 2'
            ),
            'dimensions fail 2'
        );
        def ok => (
            !pdl_is(
                pdl( 1 .. 10 ),
                pdl( [ 1 .. 4, 4, 6 .. 10 ] ),
                'values fail'
            ),
            'values fail'
        );
        def ok => (
            !pdl_is( [ 1 .. 10 ], pdl( [ 1 .. 10 ] ), 'type fail' ),
            'type fail'
        );
        def ok =>
          ( !pdl_is( undef, pdl( [ 1 .. 10 ] ), 'undef fail' ), 'undef fail' );
        def ok => (
            pdl_is(
                pdl( [ 0 .. 2 ] )->setbadat(2),
                pdl( [ 0, 1, 'nan' ] )->setnantobad,
                'bad values pass'
            ),
            'bad values pass'
        );
        def ok => (
            pdl_is(
                pdl( [ [ 1 .. 5 ], [ 6 .. 10 ] ] )->setbadat( 2, 1 ),
                pdl( [ 1 .. 5 ], [ 6 .. 10 ] )->setbadat( 2, 1 ),
                'bad values pass 2'
            ),
            'bad values pass 2'
        );
        def ok => (
            !pdl_is(
                pdl( [ 0 .. 2 ] )->setbadat(2),
                pdl( [ 0, 1, 3 ] )->setnantobad,
                'bad values fail'
            ),
            'bad values fail'
        );
    };

    do_def;

    like(
        $events,
        array {
            event Ok => sub {
                call pass => T();
                call name => undef;
            };
            event Ok => sub {
                call pass => T();
                call name => 'simple pass';
            };
            fail_details( 'dimensions fail',   qr/Dimensions do not match/ );
            fail_details( 'dimensions fail 2', qr/Dimensions do not match/ );
            fail_details( 'values fail',       qr/Values do not match/ );
            fail_details( 'type fail',         qr/is not a piddle/ );
            fail_details( 'undef fail',        qr/is not a piddle/ );
            event Ok => sub {
                call pass => T();
                call name => 'bad values pass';
            };
            event Ok => sub {
                call pass => T();
                call name => 'bad values pass 2';
            };
            fail_details( 'bad values fail',
                qr/Bad value patterns do not match/ );
            end;
        },
        "got expected events"
    );
};

subtest tolerance => sub {
    my $test_name = 'piddle is pdl(1..10)';

    {
        my $events = intercept {
            def ok => (
                !pdl_is(
                    pdl( [ 10.1, 9.9 ] ),
                    pdl( [ 10,   10 ] ),
                    'simple fail'
                ),
                'simple fail'
            );
        };

        do_def;

        like(
            $events,
            array {
                fail_details( 'simple fail', qr/Values do not match/ );
                end;
            },
            "got expected events"
        );
    }

    {
        local $Test2::Tools::PDL::TOLERANCE = 0.1;

        my $events = intercept {
            def ok => (
                pdl_is(
                    pdl( [ 10.1, 9.9 ] ),
                    pdl( [ 10,   10 ] ),
                    '$TOLERANCE pass'
                ),
                '$TOLERANCE pass'
            );
        };

        do_def;

        like(
            $events,
            array {
                event Ok => sub {
                    call pass => T();
                    call name => '$TOLERANCE pass';
                };
                end;
            },
            "got expected events"
        );
    }

    {
        local $Test2::Tools::PDL::TOLERANCE     = 0;
        local $Test2::Tools::PDL::TOLERANCE_REL = 1e-2;

        my $events = intercept {
            def ok => (
                pdl_is(
                    pdl( [ 10.1, 9.9 ] ),
                    pdl( [ 10,   10 ] ),
                    '$TOLERANCE_REL pass'
                ),
                '$TOLERANCE_REL pass'
            );
            def ok => (
                pdl_is(
                    pdl( [-0.2763423069] ),
                    pdl( [-0.276342] ),
                    '$TOLERANCE_REL pass 2'
                ),
                '$TOLERANCE_REL pass 2'
            );
        };

        do_def;

        like(
            $events,
            array {
                event Ok => sub {
                    call pass => T();
                    call name => '$TOLERANCE_REL pass';
                };
                event Ok => sub {
                    call pass => T();
                    call name => '$TOLERANCE_REL pass 2';
                };
                end;
            },
            "got expected events"
        );
    }
};

done_testing;

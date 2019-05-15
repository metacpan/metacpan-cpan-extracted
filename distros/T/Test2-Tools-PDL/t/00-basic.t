#!perl

use strict;
use warnings;

use t::lib qw(diag_message);

use PDL::Core qw(pdl);
use Safe::Isa;

use Test2::API qw(intercept);
use Test2::V0;

use Test2::Tools::PDL;

subtest pdl_ok => sub {
    my $test_name = 'this is a PDL';

    {
        my $events = intercept {
            pdl_ok( pdl( 1 .. 10 ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( $event_ok->pass, 'pdl_ok($pdl)' );
        is( $event_ok->name, $test_name, 'pdl_ok() name' );
    }

    {
        my $events = intercept {
            pdl_ok( [ 1 .. 10 ], $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_ok($non_pdl) fails' );
        is( $event_ok->name, $test_name, 'pdl_ok() name' );
    }

    {
        my $events = intercept {
            pdl_ok( undef, $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_ok(undef) fails' );
        is( $event_ok->name, $test_name, 'pdl_ok() name' );
    }
};

subtest pdl_is => sub {
    my $test_name = 'pdl(1..10)';

    {
        my $events = intercept {
            pdl_is( pdl( 1 .. 10 ), pdl( 1 .. 10 ), $test_name );
        };

        my $event = $events->[0];
        ok( $event->pass, 'pdl_is($pdl)' );
        is( $event->name, $test_name, 'pdl_is() name' );
    }

    {
        my $events = intercept {
            pdl_is( pdl( 1 .. 10 ), pdl( [ 1 .. 5 ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_pdl)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );
        like( diag_message($events), qr/^Dimensions do not match/m,
            'diag message' );
    }

    {
        my $name   = 'piddle([ [1..5], [6..10] ])';
        my $events = intercept {
            pdl_is( pdl( 1 .. 10 ), pdl( [ [ 1 .. 5 ], [ 6 .. 10 ] ] ), $name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_dims)' );
        is( $event_ok->name, $name, 'pdl_is() name' );
        like( diag_message($events), qr/^Dimensions do not match/m,
            'diag message' );
    }

    {
        my $events = intercept {
            pdl_is( pdl( 1 .. 10 ), pdl( [ 1 .. 4, 4, 6, 7, 9, 8, 10  ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_pdl)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );

        my $diag_message = diag_message($events);
        like( $diag_message, qr/^Values do not match/m,
            'diag message' );
        diag($diag_message);
    }

    {
        my $events = intercept {
            pdl_is( [ 1 .. 10 ], pdl( [ 1 .. 10 ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($non_pdl)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );
        like( diag_message($events), qr/^First argument/m, 'diag message' );
    }

    {
        my $events = intercept {
            pdl_is( undef, pdl( [ 1 .. 10 ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is(undef)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );
        like( diag_message($events), qr/^First argument/m, 'diag message' );
    }

    {
        my $name   = "piddle1d with bad values bad at tail";
        my $events = intercept {
            pdl_is( pdl( [ 0 .. 2 ] )->setbadat(2),
                pdl( [ 0, 1, 3 ] )->setnantobad, $name );
        };
        my $event = $events->[0];
        ok( !$event->pass, 'pdl_is($piddle1d_with_bad)' );
        is( $event->name, $name, 'pdl_is() name' );
        like( diag_message($events), qr/^Bad value patterns do not match/m,
            'diag message' );
    }

    {
        my $name   = "piddle1d with bad values bad at tail";
        my $events = intercept {
            pdl_is( pdl( [ 0 .. 2 ] )->setbadat(2),
                pdl( [ 0, 1, 'nan' ] )->setnantobad, $name );
        };
        my $event = $events->[0];
        ok( $event->pass, 'pdl_is($piddle1d_with_bad)' );
        is( $event->name, $name, 'pdl_is() name' );
    }

    {
        my $name = "piddle2d with bad values";

        my $events = intercept {
            pdl_is( pdl( [ [ 1 .. 5 ], [ 6 .. 10 ] ] )->setbadat( 2, 1 ),
                pdl( [ 1 .. 5 ], [ 6 .. 10 ] )->setbadat( 2, 1 ), $name );
        };
        my $event = $events->[0];
        ok( $event->pass, 'pdl_is($piddle2d_with_bad)' );
        is( $event->name, $name, 'pdl_is() name' );
    }
};

subtest tolerance => sub {
    my $test_name = 'piddle is pdl(1..10)';

    my $events1 = intercept {
        pdl_is( pdl( [ 10.1, 9.9 ] ), pdl( [ 10, 10 ] ), $test_name );
    };

    my $event_ok1 = $events1->[0];
    ok( !$event_ok1->pass, 'pdl_is() with default tolerance' );

    {
        local $Test2::Tools::PDL::TOLERANCE = 0.1;

        my $events2 = intercept {
            pdl_is( pdl( [ 10.1, 9.9 ] ), pdl( [ 10, 10 ] ), $test_name );
        };

        my $event_ok2 = $events2->[0];
        ok( $event_ok2->pass, '$TOLERANCE' );
    }

    {
        local $Test2::Tools::PDL::TOLERANCE = 0;
        local $Test2::Tools::PDL::TOLERANCE_REL = 1e-2;

        my $events2 = intercept {
            pdl_is( pdl( [ 10.1, 9.9 ] ), pdl( [ 10, 10 ] ), $test_name );
        };

        my $event_ok2 = $events2->[0];
        ok( $event_ok2->pass, '$TOLERANCE_REL' );
    }

    {
        local $Test2::Tools::PDL::TOLERANCE = 0;
        local $Test2::Tools::PDL::TOLERANCE_REL = 1e-2;

        my $events2 = intercept {
            pdl_is( pdl( [-0.2763423069] ), pdl( [-0.276342] ), 'foo' );
        };

        my $event_ok2 = $events2->[0];
        ok( $event_ok2->pass, '$TOLERANCE_REL for negative value' );
    }
};

done_testing;

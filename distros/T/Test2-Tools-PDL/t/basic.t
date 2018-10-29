#!perl

use strict;
use warnings;

use PDL::Core qw(pdl);

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
    my $test_name = 'piddle is pdl(1..10)';

    {
        my $events = intercept {
            pdl_is( pdl( 1 .. 10 ), pdl( 1 .. 10 ), $test_name );
        };

        my $event = $events->[0];
        ok( $event->pass, 'pdl_is($same_pdl)' );
        is( $event->name, $test_name, 'pdl_is() name' );
    }

    {
        my $events = intercept {
            pdl_is( pdl( 1 .. 10 ), pdl( [ 1 .. 5 ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_pdl)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );
        ok( scalar( @$events >= 3 ) );
    }

    {
        my $events = intercept {
            pdl_is( [ 1 .. 10 ], pdl( [ 1 .. 10 ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($non_pdl)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );

        my $event_diag = $events->[2];
        like( $event_diag->message, qr/^First argument/ );
    }

    {
        my $events = intercept {
            pdl_is( undef, pdl( [ 1 .. 10 ] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is(undef)' );
        is( $event_ok->name, $test_name, 'pdl_is() name' );

        my $event_diag = $events->[2];
        like( $event_diag->message, qr/^First argument/ );
    }
};

subtest tolerance => sub {
    my $test_name = 'piddle is pdl(1..10)';

    my $events1 = intercept {
        pdl_is( pdl( [ 1, 2 ] ), pdl( [ 1.01, 1.99 ] ), $test_name );
    };

    my $event_ok1 = $events1->[0];
    ok( !$event_ok1->pass, 'pdl_is() with default tolerance' );

    local $Test2::Tools::PDL::TOLERANCE = 0.02;

    my $events2 = intercept {
        pdl_is( pdl( [ 1, 2 ] ), pdl( [ 1.01, 1.99 ] ), $test_name );
    };

    my $event_ok2 = $events2->[0];
    ok( $event_ok2->pass, 'pdl_is() with large tolerance' );
};

subtest pdlsv => sub {
    eval { require PDL::SV; };
    if ($@) {
        plan skip_all => 'Requires PDL::SV';
    }

    my $test_name = 'piddle is PDL::SV->new([qw(foo bar)])';

    {
        my $events = intercept {
            pdl_is( PDL::SV->new( [qw(foo bar)] ),
                PDL::SV->new( [qw(foo bar)] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( $event_ok->pass, 'pdl_is($pdlsv)' );
    }
    {
        my $events = intercept {
            pdl_is( PDL::SV->new( [qw(foo baz)] ),
                PDL::SV->new( [qw(foo bar)] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_pdlsv) is expected to fail' );
    }
    {
        my $events = intercept {
            pdl_is( pdl([0, 0]),
                PDL::SV->new( [qw(foo bar)] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($pdl, $pdlsv) is expected to fail' );
    }
};

done_testing;

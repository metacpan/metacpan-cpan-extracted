#!perl

use strict;
use warnings;

use t::lib qw(diag_message);

use PDL::Core qw(pdl);

use Test2::API qw(intercept);
use Test2::V0;

use Test2::Tools::PDL;

eval {
    require PDL::DateTime;
    require PDL::Lite;
};
if ($@) { plan skip_all => 'Requires PDL::DateTime'; }

subtest pdldt => sub {

    {
        my $events = intercept {
            pdl_is(
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                'test'
            );
        };

        my $event_ok = $events->[0];
        ok( $event_ok->pass, 'pdl_is($pdldt)' );
    }

    {
        my $events = intercept {
            pdl_is(
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-02)] ),
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                'test'
            );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_pdldt)' );

        my $diag_message = diag_message($events);
        diag($diag_message);
        like( $diag_message, qr/2019-01-01/, 'diag message' );
    }

    {
        my $events = intercept {
            pdl_is(
                pdl( [ 0, 0 ] ),
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                'test'
            );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($pdl, $pdldt) is expected to fail' );
    }
};

done_testing;

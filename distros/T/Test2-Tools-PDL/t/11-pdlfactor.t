#!perl

use strict;
use warnings;

use Test2::API qw(intercept);
use Test2::V0;

use Test2::Tools::PDL;

eval {
    require Alt::Data::Frame::ButMore;
    require PDL::Factor;
    require PDL::Lite;
};
if ($@) { plan skip_all => 'Requires PDL::Factor'; }

subtest pdlsv => sub {

    my $test_name = 'PDL::Factor->new([qw(foo bar foo)])';

    {
        my $events = intercept {
            pdl_is( PDL::Factor->new( [qw(foo bar foo)] ),
                PDL::Factor->new( [qw(foo bar foo)] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( $event_ok->pass, 'pdl_is($pdlfactor)' );
    }
    {
        my $events = intercept {
            pdl_is( PDL::Factor->new( [qw(foo bar foo)] ),
                PDL::Factor->new( [qw(foo bar baz)] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass, 'pdl_is($different_values) is expected to fail' );
    }
    {
        my $events = intercept {
            pdl_is(
                PDL::Factor->new( [qw(foo bar foo)], levels => [qw(bar foo)] ),
                PDL::Factor->new( [qw(foo bar foo)], levels => [qw(foo bar)] ),
                $test_name
            );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass,
            'pdl_is($different_level_order) is expected to fail' );
    }
    {
        my $events = intercept {
            pdl_is( PDL::Factor->new( [qw(foo bar foo)] ),
                PDL::Factor->new( [qw(foo baz foo)] ), $test_name );
        };

        my $event_ok = $events->[0];
        ok( !$event_ok->pass,
            'pdl_is($different_level_name) is expected to fail' );
    }
};

done_testing;

#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

my %api_access;
@api_access{qw(dev_id api_key)} = @ENV{qw(PTV_DEV_ID PTV_API_KEY)};

BAIL_OUT('DevID or API key environment variables not set') unless (grep { defined $_ } values %api_access) == 2; 
 
use_ok( 'Transport::AU::PTV' ); 

for my $train_route (Transport::AU::PTV->new(\%api_access)->routes()->grep(sub { $_->type == 0})->as_array) {
    ok( !$train_route->error, "No route error" );

    my $stops = $train_route->stops();
    ok( !$stops->error, "Stops for - no error" );
    
    for my $stop ($stops->as_array) {
        my $departures = $stop->departures({ max_results => 1 });

        ok( !$departures->error, "Departures - no error" );
        isa_ok( $departures, 'Transport::AU::PTV::Departures' );
        isa_ok( $departures, 'Transport::AU::PTV::Collection' );
        ok( $departures->count, "Departures count > 0" );

        my @departure_methods = qw(
            scheduled_departure
            estimated_departure 
        );

        for my $departure ($departures->as_array) {
            ok( !$departure->error, "Departure - no error" );    
            isa_ok( $departure, 'Transport::AU::PTV::Departure' );
            can_ok( $departure, @departure_methods );

            ok( defined $departure->scheduled_departure, "Scheduled Departure: ". $departure->scheduled_departure );
            ok( defined $departure->estimated_departure, "Estimated Departure: ".$departure->estimated_departure );
            ok( defined $departure->at_platform, "At Platform: ".$departure->at_platform);
            ok( defined $departure->platform_number, "Platform Number ".$departure->platform_number);
        }
    }
}


done_testing();


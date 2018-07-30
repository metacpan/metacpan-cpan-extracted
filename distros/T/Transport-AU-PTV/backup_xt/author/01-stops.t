#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

my %api_access;
@api_access{qw(dev_id api_key)} = @ENV{qw(PTV_DEV_ID PTV_API_KEY)};

BAIL_OUT('DevID or API key environment variables not set') unless (grep { defined $_ } values %api_access) == 2; 
 
my @collection_methods = qw(
    map
    grep
    count
    as_array
);

use_ok( 'Transport::AU::PTV' ); 

for my $train_route (Transport::AU::PTV->new(\%api_access)->routes()->grep(sub { $_->type == 0})->as_array) {
    ok( !$train_route->error, "No route error" );

    my $stops = $train_route->stops();
    ok( !$stops->error, "Stops for - no error" );
    
    isa_ok( $stops, 'Transport::AU::PTV::Stops');
    can_ok( $stops, @collection_methods ); 
    ok( $stops->count > 0, "Stops count > 0" );

    foreach ($stops->as_array) {
        isa_ok( $_, 'Transport::AU::PTV::Stop' );
        ok( defined $_->name, "Stop Name: ". $_->name);
        ok( defined $_->type, "Stop Type: ". $_->name. " - ". $_->type);
        ok( defined $_->id, "Stop ID: ". $_->name. " - ". $_->id);
        ok( defined $_->route_id, "Route ID". $_->name. " - ". $_->route_id);
    }
}


done_testing();


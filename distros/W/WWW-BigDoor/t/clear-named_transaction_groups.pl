use strict;
use warnings;

use Test::Most 'no_plan';

use lib 't/lib';
use Test::Mock::REST::Client;

#use Smart::Comments -ENV;

our $TEST_APP_KEY    = $ENV{BIGDOOR_API_KEY}    || '28d3da80bf36fad415ab57b3130c6cb6';
our $TEST_APP_SECRET = $ENV{BIGDOOR_API_SECRET} || 'B66F956ED83AE218612CB0FBAC2EF01C';

my $module = 'WWW::BigDoor';

use_ok( $module );
can_ok( $module, 'new' );

my $client = new WWW::BigDoor( $TEST_APP_SECRET, $TEST_APP_KEY );

isa_ok( $client, $module );
can_ok( $module, 'GET' );
can_ok( $module, 'POST' );
can_ok( $module, 'PUT' );
can_ok( $module, 'DELETE' );

my $restclient = Test::Mock::REST::Client::setup_mock( $client );
use_ok( 'REST::Client' );

my $response = $client->GET( 'named_transaction_group' );

foreach my $ls ( @{$response->[0]} ) {
    $response = $client->DELETE( sprintf( 'named_transaction_group/%s', $ls->{'id'} ),
        {format => 'json', verbosity => 9} );
    is( $response,                  undef, 'response for DELETE named_transaction_group/{id}' );
    is( $client->get_response_code, 204,   'response_code for DELETE named_transaction_group/{id} matches' );
}

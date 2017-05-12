use strict;
use warnings;

use lib 't/lib';
use Test::Mock::REST::Client;
use Test::Most;

if ( Test::Mock::REST::Client::missing_responses ) {
    Test::Most::plan(
        skip_all =>
          sprintf(
"missing saved HTTP responses in %s, rerun tests with environment variable BIGDOOR_TEST_SAVE_RESPONSES defined",
            $Test::Mock::REST::Client::response_directory )
    );
}
elsif ( ( exists $ENV{BIGDOOR_TEST_SAVE_RESPONSES} || exists $ENV{BIGDOOR_TEST_LIVESERVER} )
    && !( exists $ENV{BIGDOOR_API_KEY} && exists $ENV{BIGDOOR_API_SECRET} ) )
{
    Test::Most::plan( skip_all =>
"ENV{BIGDOOR_API_KEY} and/or ENV{BIGDOOR_API_SECRET} undefined while running against live server"
    );
}
else {
    Test::Most::plan( tests => 13 );
}

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

my $response;

#$response = $client->GET( 'good_summary' );
#cmp_deeply( $response, [[], {}], 'response for GET good_summary matches' );
#is( $#{$response->[0]}, 7 , 'response for GET good_summary matches' );

my $named_good_collection = {
    pub_title            => 'a bunch of goods the user can get',
    pub_description      => 'some goods',
    end_user_title       => 'goods you can get',
    end_user_description => 'goods',
};

$response = $client->POST( 'named_good_collection', {format => 'json'}, $named_good_collection );
is( @$response, 2, 'response for POST named_good_collection matches' );

my $named_good_collection_id = $response->[0]->{'id'};

my @named_goods = (
    {
        pub_title                => 'example good',
        pub_description          => 'something you can purchase',
        end_user_title           => 'example good',
        end_user_description     => 'something you can purchase',
        relative_weight          => 1,
        named_good_collection_id => $named_good_collection_id,
    },
);

foreach my $named_good ( @named_goods ) {
    $response =
      $client->POST( sprintf( 'named_good_collection/%s/named_good', $named_good_collection_id ),
        {format => 'json'}, $named_good );
    is( @$response, 2, 'response for POST named_good matches' );
}

$response = $client->GET( sprintf( 'named_good_collection/%s', $named_good_collection_id ) );
is( @$response, 2, 'response for GET named_good_collection matches' );

$response = $client->GET( 'named_good' );
is( @$response, 2, 'response for GET named_good matches' );

$response = $client->DELETE( sprintf( 'named_good_collection/%s', $named_good_collection_id ) );
is( @$response, 0, 'response for DELETE named_good_collection matches' );


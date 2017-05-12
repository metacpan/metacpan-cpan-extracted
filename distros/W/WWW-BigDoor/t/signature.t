use strict;
use warnings;

use Test::Most tests => 13;    # last test to print
use Test::NoWarnings;

our $TEST_APP_KEY    = '28d3da80bf36fad415ab57b3130c6cb6';
our $TEST_APP_SECRET = 'B66F956ED83AE218612CB0FBAC2EF01C';

my $module = 'WWW::BigDoor';

use_ok( $module );
can_ok( $module, 'new' );

my $client = new WWW::BigDoor( $TEST_APP_SECRET, $TEST_APP_KEY );
isa_ok( $client, $module );

can_ok( $module, 'get_app_secret' );
can_ok( $module, 'get_app_key' );
can_ok( $module, 'generate_signature' );

is( $client->get_app_secret, $TEST_APP_SECRET, 'APP_SECRET match' );
is( $client->get_app_key,    $TEST_APP_KEY,    'APP_KEY match' );

my $params = {'time' => 1270503018.33};
my $url = sprintf "/api/publisher/%s/transaction_summary", $TEST_APP_KEY;
my $signature = $client->generate_signature( $url, $params );

is(
    $signature,
    '9d1550bb516ee2cc47d163b4b99f00e15c84b3cd32a82df9fd808aa0eb505f04',
    'Signature match'
);

$signature = $client->generate_signature( $url );
is(
    $signature,
    'fa5ae4f36a4d90abae0cbbe5fd3d59b73bae6638ff517e9c26be64569c696bcc',
    'Signature for call without params match'
);

$params = {'format' => 'json', 'sig' => 'this_sig_is_fake!'};

$signature = $client->generate_signature( $url, $params );
is(
    $signature,
    'fa5ae4f36a4d90abae0cbbe5fd3d59b73bae6638ff517e9c26be64569c696bcc',
    'Signature for call with whitelisted params match'
);

$url = sprintf "/api/publisher/%s/currency/1", $TEST_APP_KEY;

my $query_params = {'format' => 'json', 'time' => '1270517162.52'};
my $body_params = {
    'end_user_description' => 'Testing signature generation.',
    'time'                 => '1270517162.52',
    'token'                => 'bd323c0ca7c64277ba2b0cd9f93fe463'
};

$signature = $client->generate_signature( $url, $query_params, $body_params );

is(
    $signature,
    'cd073723c4901b57466694f63a2b7746caf1836c9bcdd4f98d55357334c2de64',
    'Signature for call with post params match'
);


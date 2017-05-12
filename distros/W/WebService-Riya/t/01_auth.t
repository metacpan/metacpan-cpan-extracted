use strict;
use Test::More;

use WebService::Riya;

my $api_key   = '';
my $user_name = '';
my $password  = '';

unless ($api_key and $user_name and $password) {
    Test::More->import(skip_all => "requires user_name, password and api_key, skipped.");
    exit;
}

plan tests => 2;

my $response;
my $api = WebService::Riya->new();
$api->api_key($api_key);
$api->user_name($user_name);
$api->password($password);
$response = $api->get_auth_token();
ok $response;

my $api2 = WebService::Riya->new(
    api_key   => $api_key,
    user_name => $user_name,
    password  => $password,
);
$response = $api2->get_auth_token();
ok $response;


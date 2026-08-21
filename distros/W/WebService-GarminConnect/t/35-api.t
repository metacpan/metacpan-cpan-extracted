#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use WebService::GarminConnect;
use JSON;

plan tests => 5;

my $gc = WebService::GarminConnect->new(
  username => 'test',
  password => 'test',
);
isnt($gc, undef, "create instance");
$gc->{is_logged_in} = 1;
$gc->{useragent} = Test::LWP::UserAgent->new();

my $mock_json_response = HTTP::Response->new(
  200, 'OK',
  ['Content-Type', 'application/json'],
  '{"test_key": "test_value"}'
);

my $mock_text_response = HTTP::Response->new(
  200, 'OK',
  ['Content-Type', 'text/plain'],
  'this is plain text'
);

$gc->{useragent}->map_response(qr{/json}, $mock_json_response);
$gc->{useragent}->map_response(qr{/text}, $mock_text_response);

my $response = $gc->_api_raw('/json');
is(ref($response), 'HTTP::Response', 'response is an HTTP::Response object');
my $json = JSON->new();
my $decoded_response = $json->decode($response->content());
is($decoded_response->{test_key}, 'test_value', 'decode JSON response with _api_raw');

$response = $gc->_api_raw('/text');
is($response->content(), 'this is plain text', 'retrieve text/plain response with _api_raw');

$response = $gc->_api('/json');
is($response->{test_key}, 'test_value', 'decode JSON response with _api');

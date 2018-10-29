#!perl -T
use strict;
use warnings;
use Test::More;
use WebService::HMRC::Response;

plan tests => 9;

my $http_response;
my $r;


# Create fake HTTP::Response object
# bare minimum to act as test input
# Test with valid JSON content
$http_response = HTTP::Response->new({
    decoded_content => q|{"message": "MESSAGE TEXT","code":"RESPONSE_CODE"}|,
    status_line => q|200 OK|,
    is_success => 1,
});

$r = WebService::HMRC::Response->new({
    http => $http_response,
});
isa_ok($r, 'WebService::HMRC::Response', 'WebService::HMRC::Response object created OK for valid json content');
is($r->data->{message}, 'MESSAGE TEXT', 'valid json content parsed correctly into data property - message');
is($r->data->{code}, 'RESPONSE_CODE', 'valid json content parsed correctly into data property - code');
ok($r->is_success, 'is_success is true with valid response data');
is($r->header('FAKE_HEADER'), 'FAKE_HEADER-VALUE', 'exracted header from response');




# Test with invalid JSON content
$http_response = HTTP::Response->new({
    decoded_content => q|!!INVALID_JSON_CONTENT.|,
    status_line => q|500 Internal Server Error|,
    is_success => 0,
});

$r = WebService::HMRC::Response->new({
    http => $http_response,
});
isa_ok($r, 'WebService::HMRC::Response', 'WebService::HMRC::Response object created OK for invalid json content');
is($r->data->{message}, 'No valid JSON data received from api call. 500 Internal Server Error', 'data contains error message for invalid JSON');
is($r->data->{code}, 'INVALID_RESPONSE', 'data contains error message for invalid JSON');
ok(!$r->is_success, 'is_success is false with invalid response data');



# Fake HTTP::Response object used for testing
package HTTP::Response;

sub new {
   my $class = shift;
   my $self = shift;
   bless $self;
   return $self;
}
sub decoded_content {
    my $self = shift;
    return $self->{decoded_content};
}
sub status_line {
    my $self = shift;
    return $self->{status_line};
}
sub is_success {
    my $self = shift;
    return $self->{is_success};
}
sub header {
    my $self = shift;
    my $header_name = shift;
    return "$header_name-VALUE";
}

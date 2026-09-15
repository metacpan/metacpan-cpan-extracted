use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

my $request = Uniform::HTTP::Request->new(method => 'GET', target => '/');
my $response = Uniform::HTTP::Response->new(status => 200);

for my $method (qw(
    version header header_values header_count header_name header_value
    add_header remove_header body has_buffered_body is_complete is_mutable
    headers_are_lossless
)) {
    ok $request->can($method), "request provides $method";
    ok $response->can($method), "response provides $method";
}

for my $method (qw(
    send write respond receive parse serialize socket connection transaction
    stream pause resume drain cancel retry redirect
)) {
    ok !$request->can($method), "request does not own $method";
    ok !$response->can($method), "response does not own $method";
}

done_testing;

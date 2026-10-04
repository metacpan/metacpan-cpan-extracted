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
    headers_are_lossless initial_is_mutable body_is_mutable trailers_are_mutable
    trailer trailer_values trailer_count trailer_name trailer_value has_trailers
    trailers_are_lossless add_trailer remove_trailer
)) {
    ok $request->can($method), "request provides portable $method";
    ok $response->can($method), "response provides portable $method";
}

for my $method (qw(method target scheme authority protocol target_is_exact)) {
    ok $request->can($method), "request provides portable $method";
}

for my $method (qw(freeze freeze_initial freeze_trailers mark_incomplete mark_complete)) {
    ok $request->can($method), "canonical request provides helper $method";
    ok $response->can($method), "canonical response provides helper $method";
}

for my $method (qw(
    send write respond receive parse serialize socket connection transaction
    stream pause resume drain cancel retry redirect commit
)) {
    ok !$request->can($method), "request does not own $method";
    ok !$response->can($method), "response does not own $method";
}

done_testing;

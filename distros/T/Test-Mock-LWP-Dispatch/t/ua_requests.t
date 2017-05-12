#!perl
use strict;
use warnings;
use Test::More;
use Test::Mock::LWP::Dispatch;

# Test that 'get' etc on the global mock UA works.
$mock_ua->map('http://example.com/a', HTTP::Response->new(201));

is $mock_ua->get('http://example.com/a')->code, 201, "Can mock GET on global mock UA";

done_testing;

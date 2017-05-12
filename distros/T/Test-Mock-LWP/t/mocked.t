#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'Test::Mock::LWP::UserAgent';
    use_ok 'Test::Mock::HTTP::Response';
    use_ok 'Test::Mock::HTTP::Request';
}

use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request;

is $LWP::UserAgent::VERSION, 'Mocked';
is $HTTP::Response::VERSION, 'Mocked';
is $HTTP::Request::VERSION, 'Mocked';

Basic_usage: {
    my $req = HTTP::Request->new('GET', 'http://example.com');
    my $lwp = LWP::UserAgent->new;
    my $resp = $lwp->simple_request($req);

    is_deeply [$Mock_ua->next_call], 
              ['simple_request', [$Mock_ua, $Mock_req]];
    is_deeply [$Mock_ua->next_call], [];
}

#-*- mode: cperl -*-#
use strict;
use warnings;
use utf8;
use feature 'say';
use Data::Dumper;
use Test::More tests => 10;
use WWW::BetterServers::API;

my $api_id    = $ENV{API_ID};
my $secret    = $ENV{API_SECRET};
my $auth_type = $ENV{AUTH_TYPE};
my $api_host  = $ENV{API_HOST} || 'api.betterservers.com';

SKIP: {
    skip("API_ID, API_SECRET, AUTH_TYPE environment vars not set", 10)
      unless $api_id and $secret and $auth_type;

    eval {require EV};
    skip("EV not installed", 10) if $@;

    eval {require AnyEvent};
    skip("AnyEvent not installed", 10) if $@;

    my $api = new WWW::BetterServers::API;
    $api->api_id($api_id);
    $api->api_secret($secret);
    $api->auth_type($auth_type);
    $api->api_host($api_host);

    my %resp = ();

    my $cv = AnyEvent->condvar;
    $cv->begin;

    for my $loop ( map { $_ + 9 } 1..10) {
        $cv->begin;

        $api->request(method => "GET",
                      uri => "/response_code?code=2$loop",
                      callback => sub { $resp{$loop} = pop->res->body;
                                        $cv->end });
    }

    $cv->end;
    $cv->recv;

    for my $loop ( keys %resp ) {
        ok($resp{$loop}, "$loop entry");
    }
}

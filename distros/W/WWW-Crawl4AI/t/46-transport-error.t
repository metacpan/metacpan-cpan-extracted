#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use WWW::Crawl4AI::Client;

package Stub::UA {
  sub new { bless { res => $_[1], n => 0 }, $_[0] }
  sub request { $_[0]{n}++; $_[0]{res}->clone }
}

sub client_for {
  my $res = shift;
  my $ua = Stub::UA->new($res);
  return ( WWW::Crawl4AI::Client->new(
    base_url => 'http://127.0.0.1:9', ua => $ua, max_attempts => 2,
    sleep_sub => sub { }, retry_backoff => [0],
  ), $ua );
}

my $internal = HTTP::Response->new( 500, "Can't connect to 127.0.0.1:9 (Connection refused)" );
$internal->header( 'Client-Warning' => 'Internal response' );
$internal->content("Can't connect to 127.0.0.1:9 (Connection refused)");

my ( $c, $ua ) = client_for($internal);
my $err = eval { $c->html('http://example.com'); 1 } ? undef : $@;
isa_ok $err, 'WWW::Crawl4AI::Error';
is $err->type, 'transport', 'LWP internal 500 is a transport error';
is $err->status_code, 0, 'status_code 0';
is $ua->{n}, 2, 'retried';

my ($c2) = client_for( HTTP::Response->new( 500, 'boom' ) );
my $e2 = eval { $c2->html('http://example.com'); 1 } ? undef : $@;
is $e2->type, 'api', 'a real server 500 stays an api error';

done_testing;

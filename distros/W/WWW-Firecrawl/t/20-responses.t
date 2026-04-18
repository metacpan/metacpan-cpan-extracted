#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use WWW::Firecrawl;

my $fc = WWW::Firecrawl->new( base_url => 'http://localhost:3002' );

sub mk_response {
  my ( $code, $payload ) = @_;
  my $body = ref $payload ? encode_json($payload) : $payload;
  my $r = HTTP::Response->new($code, 'OK', [ 'Content-Type' => 'application/json' ], $body);
  return $r;
}

subtest 'scrape response' => sub {
  my $res = mk_response(200, { success => JSON::MaybeXS::true(), data => { markdown => '# hi' } });
  my $data = $fc->parse_scrape_response($res);
  is $data->{markdown}, '# hi';
};

subtest 'map response → just links' => sub {
  my $res = mk_response(200, {
    success => JSON::MaybeXS::true(),
    links => [ { url => 'https://a' }, { url => 'https://b' } ],
  });
  my $links = $fc->parse_map_response($res);
  is scalar @$links, 2;
  is $links->[0]{url}, 'https://a';
};

subtest 'crawl status with next pagination' => sub {
  my $res = mk_response(200, {
    status => 'scraping', total => 10, completed => 3,
    next => 'http://localhost:3002/v2/crawl/abc?skip=3',
    data => [{ markdown => 'page1' }],
  });
  my $st = $fc->parse_crawl_status_response($res);
  is $st->{status}, 'scraping';
  is $st->{completed}, 3;
  is $st->{next}, 'http://localhost:3002/v2/crawl/abc?skip=3';
};

subtest 'http error with JSON error body' => sub {
  my $res = mk_response(400, { error => 'bad url' });
  $res->message('Bad Request');
  my $e = exception { $fc->parse_response($res) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_api, 'type=api';
  is $e->status_code, 400;
  isa_ok $e->response, 'HTTP::Response';
  like "$e", qr/HTTP 400.*bad url/, 'stringifies like before';
};

subtest 'success: false body' => sub {
  my $res = mk_response(200, { success => JSON::MaybeXS::false(), error => 'nope' });
  my $e = exception { $fc->parse_response($res) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_api;
  like "$e", qr/Firecrawl: nope/;
};

subtest 'non-JSON error body' => sub {
  my $r = HTTP::Response->new(502, 'Bad Gateway', [ 'Content-Type' => 'text/plain' ], 'upstream down');
  my $e = exception { $fc->parse_response($r) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_api;
  is $e->status_code, 502;
  like "$e", qr/HTTP 502/;
};

subtest 'crawl_status_next_request follows absolute URL' => sub {
  my $req = $fc->crawl_status_next_request('http://other-host/v2/crawl/abc?skip=3');
  is $req->uri, 'http://other-host/v2/crawl/abc?skip=3';
  is $req->method, 'GET';
};

done_testing;

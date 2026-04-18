#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use JSON::MaybeXS;

use WWW::Firecrawl;

my $fc = WWW::Firecrawl->new(
  base_url => 'http://localhost:3002',
  api_key  => 'fc-test',
);

is $fc->endpoint_url('scrape'), 'http://localhost:3002/v2/scrape', 'endpoint_url joins';
is $fc->endpoint_url('crawl', 'abc'), 'http://localhost:3002/v2/crawl/abc', 'endpoint_url with id';

# trailing slash handling
my $fc2 = WWW::Firecrawl->new( base_url => 'http://localhost:3002/' );
is $fc2->endpoint_url('scrape'), 'http://localhost:3002/v2/scrape', 'trailing slash stripped';

subtest 'scrape_request' => sub {
  my $req = $fc->scrape_request( url => 'https://example.com', formats => ['markdown'] );
  isa_ok $req, 'HTTP::Request';
  is $req->method, 'POST';
  is $req->uri, 'http://localhost:3002/v2/scrape';
  is $req->header('Content-Type'), 'application/json';
  is $req->header('Authorization'), 'Bearer fc-test';
  my $body = decode_json($req->content);
  is $body->{url}, 'https://example.com';
  is_deeply $body->{formats}, ['markdown'];
};

subtest 'no api_key → no Authorization header' => sub {
  local $ENV{FIRECRAWL_API_KEY};
  delete $ENV{FIRECRAWL_API_KEY};
  my $anon = WWW::Firecrawl->new( base_url => 'http://localhost:3002' );
  my $req = $anon->scrape_request( url => 'https://example.com' );
  is $req->header('Authorization'), undef, 'no auth header when no key';
};

subtest 'crawl_request + status/cancel/errors/active' => sub {
  my $req = $fc->crawl_request( url => 'https://example.com', limit => 5 );
  is $req->method, 'POST';
  is $req->uri, 'http://localhost:3002/v2/crawl';

  my $status = $fc->crawl_status_request('xyz');
  is $status->method, 'GET';
  is $status->uri, 'http://localhost:3002/v2/crawl/xyz';

  my $cancel = $fc->crawl_cancel_request('xyz');
  is $cancel->method, 'DELETE';

  my $errs = $fc->crawl_errors_request('xyz');
  is $errs->uri, 'http://localhost:3002/v2/crawl/xyz/errors';

  my $active = $fc->crawl_active_request;
  is $active->uri, 'http://localhost:3002/v2/crawl/active';
};

subtest 'map + search' => sub {
  my $m = $fc->map_request( url => 'https://example.com' );
  is $m->uri, 'http://localhost:3002/v2/map';
  my $s = $fc->search_request( query => 'perl' );
  is $s->uri, 'http://localhost:3002/v2/search';
};

subtest 'batch_scrape' => sub {
  my $req = $fc->batch_scrape_request( urls => ['https://a', 'https://b'] );
  is $req->uri, 'http://localhost:3002/v2/batch/scrape';
  my $body = decode_json($req->content);
  is_deeply $body->{urls}, ['https://a', 'https://b'];

  my $st = $fc->batch_scrape_status_request('job1');
  is $st->uri, 'http://localhost:3002/v2/batch/scrape/job1';

  my $er = $fc->batch_scrape_errors_request('job1');
  is $er->uri, 'http://localhost:3002/v2/batch/scrape/job1/errors';
};

subtest 'extract' => sub {
  my $req = $fc->extract_request( urls => ['https://a/*'], prompt => 'pull titles' );
  is $req->uri, 'http://localhost:3002/v2/extract';
  my $st = $fc->extract_status_request('ex1');
  is $st->uri, 'http://localhost:3002/v2/extract/ex1';
};

subtest 'required args' => sub {
  like exception { $fc->scrape_request() }, qr/requires 'url'/;
  like exception { $fc->crawl_request() }, qr/requires 'url'/;
  like exception { $fc->search_request() }, qr/requires 'query'/;
  like exception { $fc->batch_scrape_request() }, qr/requires 'urls'/;
  like exception { $fc->batch_scrape_request( urls => 'oops' ) }, qr/requires 'urls'/;
  like exception { $fc->extract_request() }, qr/requires 'urls'/;
  like exception { $fc->crawl_status_request() }, qr/requires id/;
};

subtest 'usage endpoints' => sub {
  is $fc->credit_usage_request->uri, 'http://localhost:3002/v2/credit-usage';
  is $fc->credit_usage_historical_request->uri, 'http://localhost:3002/v2/credit-usage/historical';
  is $fc->token_usage_request->uri, 'http://localhost:3002/v2/token-usage';
  is $fc->queue_status_request->uri, 'http://localhost:3002/v2/queue-status';
  is $fc->activity_request->uri, 'http://localhost:3002/v2/activity';
};

done_testing;

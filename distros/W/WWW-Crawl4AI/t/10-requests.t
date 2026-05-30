#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use JSON::MaybeXS;
use HTTP::Response;

use WWW::Crawl4AI::Request;
use WWW::Crawl4AI::Client;

my $json = JSON::MaybeXS->new;

subtest 'Request: crawl payload shape + defaults' => sub {
  my $req = WWW::Crawl4AI::Request->new( urls => 'https://example.com' );
  my $p   = $req->to_crawl_payload;
  is_deeply $p->{urls}, ['https://example.com'], 'urls coerced to arrayref';
  is $p->{browser_config}{type}, 'BrowserConfig',    'browser_config type';
  is $p->{crawler_config}{type}, 'CrawlerRunConfig', 'crawler_config type';
  ok $json->encode($p) =~ /"headless":true/,      'default headless true (JSON bool)';
  is $p->{crawler_config}{params}{cache_mode}, 'bypass', 'default cache bypass';
  ok $json->encode($p) =~ /"stream":false/,       'default stream false (JSON bool)';
};

subtest 'Request: params merge over defaults' => sub {
  my $req = WWW::Crawl4AI::Request->new(
    urls           => ['https://a', 'https://b'],
    browser_params => { enable_stealth => WWW::Crawl4AI::Request::JSON_true() },
    crawler_params => { wait_until => 'networkidle', cache_mode => 'enabled' },
  );
  my $p = $req->to_crawl_payload;
  is scalar @{ $p->{urls} }, 2, 'two urls kept';
  is $p->{crawler_config}{params}{wait_until}, 'networkidle', 'crawler param added';
  is $p->{crawler_config}{params}{cache_mode}, 'enabled',     'crawler param overrides default';
  ok $json->encode($p) =~ /"enable_stealth":true/, 'browser param added';
};

subtest 'Request: md payload' => sub {
  my $req = WWW::Crawl4AI::Request->new( urls => 'https://example.com', filter => 'fit' );
  is_deeply $req->to_md_payload, { url => 'https://example.com', f => 'fit' }, 'md payload';
};

subtest 'Request: empty urls dies' => sub {
  isnt exception { WWW::Crawl4AI::Request->new( urls => [] ) }, undef, 'empty urls rejected';
};

my $client = WWW::Crawl4AI::Client->new(
  base_url  => 'http://localhost:11235',
  api_token => 'tok-test',
);

subtest 'Client: crawl_request' => sub {
  my $req = $client->crawl_request( WWW::Crawl4AI::Request->new( urls => 'https://example.com' ) );
  isa_ok $req, 'HTTP::Request';
  is $req->method, 'POST';
  is $req->uri, 'http://localhost:11235/crawl', 'crawl uri';
  is $req->header('Content-Type'), 'application/json';
  is $req->header('Authorization'), 'Bearer tok-test', 'bearer token set';
};

subtest 'Client: job + status + health uris' => sub {
  my $sub = $client->job_submit_request( WWW::Crawl4AI::Request->new( urls => 'https://x' ) );
  is $sub->uri, 'http://localhost:11235/crawl/job', 'job submit uri';
  my $st = $client->job_status_request('crawl_abc');
  is $st->method, 'GET';
  is $st->uri, 'http://localhost:11235/crawl/job/crawl_abc', 'job status uri';
  is $client->health_request->uri, 'http://localhost:11235/health', 'health uri';
};

subtest 'Client: trailing slash on base_url stripped' => sub {
  my $c = WWW::Crawl4AI::Client->new( base_url => 'http://localhost:11235/' );
  is $c->crawl_request( WWW::Crawl4AI::Request->new( urls => 'https://x' ) )->uri,
    'http://localhost:11235/crawl', 'no double slash';
};

subtest 'Client: no token → no Authorization header' => sub {
  local $ENV{CRAWL4AI_API_TOKEN};
  delete $ENV{CRAWL4AI_API_TOKEN};
  my $c = WWW::Crawl4AI::Client->new( base_url => 'http://localhost:11235' );
  my $req = $c->crawl_request( WWW::Crawl4AI::Request->new( urls => 'https://x' ) );
  is $req->header('Authorization'), undef, 'no auth header without token';
};

subtest 'Client: hashref payload accepted directly' => sub {
  my $req = $client->crawl_request( { urls => ['https://x'] } );
  my $body = decode_json( $req->content );
  is_deeply $body->{urls}, ['https://x'], 'raw hashref passed through';
};

subtest 'Client: structured markdown with empty fit_markdown falls through' => sub {
  # Crawl4AI >= 0.8 returns markdown as an object, and fit_markdown is often an
  # empty string when no content filter matched — must not win over raw_markdown.
  my $body = $json->encode(
    {
      success => JSON::MaybeXS::true(),
      results => [
        {
          success     => JSON::MaybeXS::true(),
          url         => 'https://example.com',
          status_code => 200,
          html        => '<html>...</html>',
          markdown    => {
            raw_markdown            => "# Example Domain\nreal content here\n",
            markdown_with_citations => "# Example Domain\nwith refs\n",
            fit_markdown            => '',
            fit_html                => '',
          },
        },
      ],
    }
  );
  my $res = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $body );
  my $pages = $client->parse_crawl_response($res);
  is scalar @$pages, 1, 'one page parsed';
  like $pages->[0]{markdown}, qr/real content here/, 'raw_markdown used, empty fit_markdown skipped';
};

done_testing;

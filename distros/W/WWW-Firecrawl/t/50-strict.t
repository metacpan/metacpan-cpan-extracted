#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use WWW::Firecrawl;

sub ok_404_response {
  my $body = encode_json({
    success => JSON::MaybeXS::true(),
    data => { metadata => { statusCode => 404, sourceURL => 'https://gone.invalid' } },
  });
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], $body );
}

sub ok_500_response {
  my $body = encode_json({
    success => JSON::MaybeXS::true(),
    data => { metadata => {
      statusCode => 503, error => 'timeout', sourceURL => 'https://flaky.invalid',
    } },
  });
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], $body );
}

subtest 'strict=0 (default): 404 target returns data' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  my $data = $fc->parse_scrape_response( ok_404_response() );
  is ref $data, 'HASH';
  is $data->{metadata}{statusCode}, 404;
  ok $fc->is_scrape_ok($data), '404 is not a failure by default';
};

subtest 'strict=0 + 503 target returns data (metadata.error marks failure)' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  my $data = $fc->parse_scrape_response( ok_500_response() );
  is $data->{metadata}{statusCode}, 503;
  ok !$fc->is_scrape_ok($data);
  is $fc->scrape_error($data), 'timeout (HTTP 503)';
};

subtest 'strict=1 + 503 target throws scrape error' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x', strict => 1 );
  my $e = exception { $fc->parse_scrape_response( ok_500_response() ) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_scrape, 'type=scrape';
  is $e->status_code, 503;
  is $e->url, 'https://flaky.invalid';
  like "$e", qr/timeout/;
};

subtest 'strict=1 + 404 target does NOT throw (404 not a default failure)' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x', strict => 1 );
  my $data = $fc->parse_scrape_response( ok_404_response() );
  is $data->{metadata}{statusCode}, 404;
};

subtest 'strict=1 + 404 + failure_codes=>[404] throws' => sub {
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x',
    strict => 1,
    failure_codes => [ 404, 500..599 ],
  );
  my $e = exception { $fc->parse_scrape_response( ok_404_response() ) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_scrape;
  is $e->status_code, 404;
};

subtest 'per-call strict=1 override on loose instance' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  my $e = exception { $fc->parse_scrape_response( ok_500_response(), strict => 1 ) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_scrape;
};

subtest 'per-call strict=0 override on strict instance' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x', strict => 1 );
  my $data = $fc->parse_scrape_response( ok_500_response(), strict => 0 );
  is $data->{metadata}{statusCode}, 503;
};

done_testing;

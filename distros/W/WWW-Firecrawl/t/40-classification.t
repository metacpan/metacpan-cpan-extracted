#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use WWW::Firecrawl;

sub page {
  my (%meta) = @_;
  return { metadata => \%meta };
}

subtest 'default is_failure' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  ok !$fc->is_scrape_ok( page( statusCode => 500 ) ),   '500 is failure';
  ok !$fc->is_scrape_ok( page( statusCode => 503 ) ),   '503 is failure';
  ok  $fc->is_scrape_ok( page( statusCode => 200 ) ),   '200 is ok';
  ok  $fc->is_scrape_ok( page( statusCode => 404 ) ),   '404 is ok by default';
  ok !$fc->is_scrape_ok( page( statusCode => 200, error => 'boom' ) ),
     'metadata.error marks failure even on 200';
  ok  $fc->is_scrape_ok( page() ),                      'no metadata is ok';
};

subtest 'failure_codes arrayref' => sub {
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x',
    failure_codes => [ 404, 500..599 ],
  );
  ok !$fc->is_scrape_ok( page( statusCode => 404 ) ),   '404 is failure';
  ok !$fc->is_scrape_ok( page( statusCode => 500 ) ),   '500 is failure';
  ok  $fc->is_scrape_ok( page( statusCode => 200 ) ),   '200 is ok';
  ok !$fc->is_scrape_ok( page( statusCode => 200, error => 'boom' ) ),
     'metadata.error still marks failure';
};

subtest q{failure_codes => 'any-non-2xx'} => sub {
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x',
    failure_codes => 'any-non-2xx',
  );
  ok !$fc->is_scrape_ok( page( statusCode => 199 ) );
  ok  $fc->is_scrape_ok( page( statusCode => 200 ) );
  ok  $fc->is_scrape_ok( page( statusCode => 299 ) );
  ok !$fc->is_scrape_ok( page( statusCode => 300 ) );
  ok !$fc->is_scrape_ok( page( statusCode => 404 ) );
};

subtest 'custom is_failure CodeRef' => sub {
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x',
    is_failure => sub {
      my ($p) = @_;
      return ($p->{metadata}{statusCode} // 0) == 418;
    },
  );
  ok !$fc->is_scrape_ok( page( statusCode => 418 ) );
  ok  $fc->is_scrape_ok( page( statusCode => 500 ) );
};

subtest 'passing both is_failure and failure_codes croaks' => sub {
  like exception {
    WWW::Firecrawl->new(
      base_url => 'http://x',
      is_failure => sub { 0 },
      failure_codes => [ 500 ],
    );
  }, qr/pass either 'is_failure' or 'failure_codes'/;
};

subtest 'scrape_status' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  is $fc->scrape_status( page( statusCode => 200 ) ), 200;
  is $fc->scrape_status( page( statusCode => 503 ) ), 503;
  is $fc->scrape_status( page() ), 0;
};

subtest 'scrape_error 4 branches' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  is $fc->scrape_error( page( statusCode => 503, error => 'timeout' ) ),
     'timeout (HTTP 503)', 'both set';
  is $fc->scrape_error( page( statusCode => 200, error => 'boom' ) ),
     'boom', 'only metadata.error';
  is $fc->scrape_error( page( statusCode => 404 ) ),
     'HTTP 404', 'only non-2xx status';
  is $fc->scrape_error( page( statusCode => 200 ) ),
     undef, 'nothing wrong';
};

done_testing;

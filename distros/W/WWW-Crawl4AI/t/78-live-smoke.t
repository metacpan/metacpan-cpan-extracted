#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI;

# Optional public-internet smoke test: proves the service can reach and render a
# real site, not just the in-cluster fixture. Gated separately (and off by
# default) because it depends on the network and on example.com staying up, so
# it must never fail an offline or CI run. Assertions are deliberately loose.
plan skip_all => 'set CRAWL4AI_URL and CRAWL4AI_LIVE_PUBLIC=1 to run the public smoke'
  unless $ENV{CRAWL4AI_URL} && $ENV{CRAWL4AI_LIVE_PUBLIC};

my $c = WWW::Crawl4AI->new( base_url => $ENV{CRAWL4AI_URL} );

# example.com is a small page, so relax the thin_content bar for the smoke.
my $r = $c->markdown( 'https://example.com/', min_markdown => 50 );

ok $r->ok, 'example.com crawled successfully';
is $r->backend, 'crawl4ai_plain', 'a plain page needed no escalation';
like $r->markdown, qr/example/i, 'markdown mentions the example domain';
ok defined $r->final_url && length $r->final_url, 'final_url reported';

done_testing;

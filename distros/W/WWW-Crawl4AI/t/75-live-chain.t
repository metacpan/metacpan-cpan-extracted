#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI;

# Live end-to-end tests of the orchestrator (strategy chain + deep_crawl)
# against the deterministic nginx fixture. See t/70-live-client.t for the env
# gate; this file needs the same two variables.
my $base    = $ENV{CRAWL4AI_URL};
my $fixture = $ENV{CRAWL4AI_FIXTURE_URL};
plan skip_all => 'set CRAWL4AI_URL and CRAWL4AI_FIXTURE_URL to run live chain tests'
  unless $base && $fixture;

my $c = WWW::Crawl4AI->new( base_url => $base );

subtest 'the cheapest strategy wins on a clean page' => sub {
  my $r = $c->markdown($fixture);
  ok $r->ok, 'chain succeeded';
  is $r->backend,    'crawl4ai_plain', 'plain backend won (no escalation needed)';
  is $r->cost_class, 'cheap',          'cost class is cheap';
  is $r->attempt_count, 1, 'won on the first attempt';
  like $r->markdown, qr/FIXTURE_MARKER_HOME/, 'winning markdown is the fixture home';
  is $r->attempts->[0]->why_failed, undef, 'no failure recorded on the winning attempt';
};

subtest 'deep_crawl follows same-host links and stops at max_depth' => sub {
  my $results = $c->deep_crawl( $fixture, max_depth => 1, same_host => 1 );
  is scalar( @$results ), 2,
    'start + page2 only (example.com dropped by same_host, back-link deduped)';
  ok +( grep { $_->markdown =~ /FIXTURE_MARKER_HOME/  } @$results ), 'home page in results';
  ok +( grep { $_->markdown =~ /FIXTURE_MARKER_PAGE2/ } @$results ), 'page2 crawled at depth 1';
  ok !( grep { ( $_->final_url // '' ) =~ /example\.com/ } @$results ),
    'off-host example.com was not followed';
  ok +( grep { !$_->ok } @$results ) == 0, 'every followed page classified good';
};

subtest 'a stricter min_markdown makes the fixture read thin' => sub {
  # 100_000 chars is far more than the fixture holds, so every strategy reports
  # thin_content and the chain exhausts -> ok=0 with a why_failed token.
  my $r = $c->markdown( $fixture, min_markdown => 100_000 );
  ok !$r->ok, 'chain failed under an impossible quality bar';
  is $r->why_failed, 'thin_content', 'failure surfaced as thin_content';
  cmp_ok $r->attempt_count, '>', 1, 'chain escalated through multiple strategies';
};

done_testing;

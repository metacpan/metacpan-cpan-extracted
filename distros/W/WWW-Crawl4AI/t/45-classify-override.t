#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI;

# Regression for karr #2: a subclass override of the win/continue classifier
# must actually steer which strategy wins and whether the chain keeps going --
# not merely change the *reported* signals. Before classify_is_good existed,
# _attempt_for called WWW::Crawl4AI::Detect::is_good directly, so a subclass had
# no lever over the decision at all. These tests fail against that old code.

# Same zero-I/O mock as t/40-fallback.t: one pre-programmed page per backend.
package Mock::Client {
  sub new   { my ( $c, %a ) = @_; bless { pages => $a{pages} || {}, calls => [] }, $c }
  sub calls { $_[0]->{calls} }
  sub crawl {
    my ( $self, $req, $backend ) = @_;
    push @{ $self->{calls} }, $backend;
    my $p = $self->{pages}{$backend};
    die "mock: no page configured for $backend\n" unless $p;
    return [$p];
  }
  sub health { 1 }
}

# A crawler whose quality bar is "the markdown must contain ACCEPTED", stricter
# than Detect (which is happy with any content-rich 200).
package Strict::Crawler {
  use Moo;
  extends 'WWW::Crawl4AI';
  sub classify_is_good {
    my ( $self, $page, %opts ) = @_;
    return ( ( $page->{markdown} // '' ) =~ /ACCEPTED/ ) ? 1 : 0;
  }
}

# A crawler that accepts anything -- looser than Detect (which rejects thin).
package Loose::Crawler {
  use Moo;
  extends 'WWW::Crawl4AI';
  sub classify_is_good { 1 }
}

my $rich_no_token = { status_code => 200, markdown => ( 'real useful content ' x 40 ) };
my $rich_token    = { status_code => 200, markdown => ( 'ACCEPTED useful content ' x 40 ) };
my $thin          = { status_code => 200, markdown => 'too short' };

# Deterministic applicability.
local $ENV{CLOAKBROWSER_CDP_URL};
local $ENV{CRAWL4AI_PROXY_URL};
delete $ENV{CLOAKBROWSER_CDP_URL};
delete $ENV{CRAWL4AI_PROXY_URL};

subtest 'default classify_is_good matches Detect::is_good exactly' => sub {
  my $c = WWW::Crawl4AI->new( client => Mock::Client->new );
  is $c->classify_is_good($rich_no_token), WWW::Crawl4AI::Detect::is_good($rich_no_token),
    'good page: default == Detect';
  is $c->classify_is_good($thin), WWW::Crawl4AI::Detect::is_good($thin),
    'thin page: default == Detect';
};

subtest 'stricter override makes the chain CONTINUE past a Detect-good page' => sub {
  # Detect rates the plain page good, so without a working override plain wins
  # immediately. The stricter classifier must reject it and drive to browser.
  my $mock = Mock::Client->new( pages => {
    crawl4ai_plain   => $rich_no_token,   # Detect: good  | Strict: rejected
    crawl4ai_browser => $rich_token,      # Detect: good  | Strict: accepted
  } );
  my $c = Strict::Crawler->new( client => $mock );
  my $r = $c->markdown('https://example.com');

  ok $r->ok, 'overall ok';
  is $r->backend, 'crawl4ai_browser', 'browser won -- plain was rejected by the override';
  is_deeply $mock->calls, [qw( crawl4ai_plain crawl4ai_browser )],
    'chain continued past plain (would have stopped at plain without the override)';
  ok !$r->attempts->[0]->ok, 'plain attempt rejected by classify_is_good';
  ok  $r->attempts->[1]->ok, 'browser attempt accepted';
};

subtest 'looser override makes the chain STOP early on a Detect-bad page' => sub {
  # Detect rates the plain page thin, so without a working override the chain
  # escalates to browser. The looser classifier must accept plain and stop.
  my $mock = Mock::Client->new( pages => {
    crawl4ai_plain   => $thin,            # Detect: thin  | Loose: accepted
    crawl4ai_browser => $rich_no_token,   # Detect: good
  } );
  my $c = Loose::Crawler->new( client => $mock );
  my $r = $c->markdown('https://example.com');

  ok $r->ok, 'overall ok';
  is $r->backend, 'crawl4ai_plain', 'plain won -- accepted by the override despite being thin';
  is_deeply $mock->calls, ['crawl4ai_plain'],
    'chain stopped at plain (would have escalated to browser without the override)';
  ok $r->attempts->[0]->ok, 'plain attempt accepted by classify_is_good';
};

done_testing;

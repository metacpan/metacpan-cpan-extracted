#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI::Strategy::CloakBrowser;

# CloakBrowser requires ?fingerprint= to be a NON-NEGATIVE INTEGER; a raw host
# string (the old behaviour) gets rejected with HTTP 400. These tests lock the
# numeric, deterministic, per-domain seed in place.

# Minimal mock: the strategy only ever reads cloakbrowser_url off the crawler.
package Mock::Crawler {
  sub new { my ( $c, %a ) = @_; bless { %a }, $c }
  sub cloakbrowser_url { $_[0]->{cloakbrowser_url} }
}

my $strat = WWW::Crawl4AI::Strategy::CloakBrowser->new;

subtest 'fingerprint seed is a non-negative integer in 32-bit range' => sub {
  my $crawler = Mock::Crawler->new( cloakbrowser_url => 'http://cloak:9222' );
  my $cdp = $strat->_cdp_url( $crawler, 'https://ainextbrain.com/' );
  like $cdp, qr{^http://cloak:9222\?fingerprint=(\d+)$}, 'numeric fingerprint appended';
  my ($seed) = $cdp =~ /fingerprint=(\d+)/;
  ok $seed >= 0,            'seed non-negative';
  ok $seed <= 0xFFFFFFFF,   'seed within 32-bit range';
};

subtest 'same domain -> same seed, different domain -> different seed' => sub {
  my $crawler = Mock::Crawler->new( cloakbrowser_url => 'http://cloak:9222' );
  my $a1 = $strat->_cdp_url( $crawler, 'https://ainextbrain.com/page1' );
  my $a2 = $strat->_cdp_url( $crawler, 'https://ainextbrain.com/page2' );
  my $b  = $strat->_cdp_url( $crawler, 'https://example.com/' );
  is $a1, $a2, 'same host yields identical seed regardless of path';
  isnt $a1, $b, 'different host yields a different seed';
};

subtest 'trailing slash on cdp url stripped before query' => sub {
  my $crawler = Mock::Crawler->new( cloakbrowser_url => 'http://cloak:9222/' );
  my $cdp = $strat->_cdp_url( $crawler, 'https://example.com/' );
  like $cdp, qr{^http://cloak:9222\?fingerprint=\d+$}, 'no double slash before query';
};

subtest 'cdp url with existing query string used verbatim' => sub {
  my $crawler = Mock::Crawler->new( cloakbrowser_url => 'http://cloak:9222?fingerprint=0' );
  is $strat->_cdp_url( $crawler, 'https://example.com/' ),
    'http://cloak:9222?fingerprint=0',
    'preconfigured query preserved, no host hashing';
};

subtest '_fingerprint_seed is deterministic and integer' => sub {
  is $strat->_fingerprint_seed('ainextbrain.com'),
     $strat->_fingerprint_seed('ainextbrain.com'),
     'stable across calls';
  like $strat->_fingerprint_seed('ainextbrain.com'), qr/^\d+$/, 'integer output';
};

done_testing;

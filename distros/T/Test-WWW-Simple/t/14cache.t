#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Mock;

plan tests => 9;

use Test::WWW::Simple;

my @values = qw(aaaaa bbbbb ccccc ddddd STOPPER);
my $current;
my $caching = 1;
my $resp;
my $mock = Test2::Mock->new(
  class => 'WWW::Mechanize',
  override => [
    get => sub {
      my $value = $_[1] =~ /perl/ ? 'perl' : shift @values;
      $resp = HTTP::Response->new(200, '200 OK', undef, $value);
      return $resp;
    },
    success => sub {1},
    content => sub {
      return $resp->content;
    },
    response => sub {
      return $resp;
    },
  ],
);
my $mock2 = Test2::Mock->new(
  class => 'HTTP::Response',
  override => [
    status_line => sub { "200 OK" },
  ],
);

 # actual tests go here
 no_cache "start without cache";
 my $url = 'http://is.mocked.com';
 page_like($url, qr/aaaaa/, 'initial value as expected');
 page_like($url, qr/bbbbb/, 'reaccessed as expected');
 cache "turn cache on";
 page_like('http://perl.org', qr/perl/i,   'intervening page');
 page_like($url, qr/bbbbb/, 'cached from last get');
 page_like($url, qr/bbbbb/, 'remains cached');
 no_cache "turn back off";
 page_like($url, qr/ccccc/, 'reaccessed again as expected');
 page_like('http://perl.org', qr/perl/i,   'intervening page');
 cache "turn back on";
 page_like($url, qr/ccccc/, 'return to last cached value');
 no_cache "turn back off";
 page_like($url, qr/ddddd/, 'now a new value');

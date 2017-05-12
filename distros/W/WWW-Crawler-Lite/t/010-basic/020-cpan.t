#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use_ok('WWW::Crawler::Lite');

my %pages = ( );
my $pattern = 'https?://search\.cpan\.org\/';
my %links = ( );
my $downloaded = 0;

my $crawler;
$crawler = WWW::Crawler::Lite->new(
  url_pattern => $pattern,
#  http_accept => [qw( text/plain text/html )],
  on_response => sub {
    my ($url, $res) = @_;
    $downloaded++;
    ok($url, "on_response($url)" );
    ok($res, "on_response(\$url, $res)");
    $crawler->stop() if $downloaded++ > 5;
  },
  on_link     => sub {
    my ($from, $to, $text) = @_;
    ok($from, "Got 'from'");
    ok($to, "Got 'to'");
    
    return if exists($pages{$to}) && $pages{$to} eq 'BAD';
    $pages{$to}++;
    $links{$to} ||= [ ];
    push @{$links{$to}}, { from => $from, text => $text };
  },
  on_bad_url => sub {
    my ($url) = @_;
    $pages{$url} = 'BAD';
  },
);
$crawler->crawl( url => "http://search.cpan.org/recent/" );



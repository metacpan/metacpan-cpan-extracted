#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use WWW::Firecrawl;

{
  package Test::ScriptUA;
  sub new {
    my ($class, %s) = @_;
    return bless { script => \%s, log => [] }, $class;
  }
  sub request {
    my ($self, $req) = @_;
    my ($url) = $req->content =~ /"url"\s*:\s*"([^"]+)"/;
    push @{ $self->{log} }, $url;
    my $r = $self->{script}{$url} or die "no script for $url\n";
    return $r;
  }
  sub log { $_[0]->{log} }
}

sub ok_scrape {
  my ($url, $md) = @_;
  HTTP::Response->new( 200, 'OK', [ 'Content-Type'=>'application/json' ],
    encode_json({ success => JSON::MaybeXS::true(),
                  data => { markdown => $md, metadata => { sourceURL => $url, statusCode => 200 } } }),
  );
}

my $ua = Test::ScriptUA->new(
  'https://b' => ok_scrape('https://b','B-now'),
  'https://c' => ok_scrape('https://c','C-now'),
);
my $fc = WWW::Firecrawl->new(
  base_url => 'http://x', ua => $ua, sleep_sub => sub { },
);

my $crawl_result = {
  status => 'completed',
  data   => [ { metadata => { sourceURL => 'https://a', statusCode => 200 } } ],
  failed => [
    { url => 'https://b', statusCode => 503, error => 'timeout', page => {} },
    { url => 'https://c', statusCode => 502, error => 'gateway', page => {} },
  ],
};

my $retry = $fc->retry_failed_pages( $crawl_result, formats => ['markdown'] );
is $retry->{stats}{ok}, 2;
is $retry->{stats}{failed}, 0;
is_deeply $ua->log, ['https://b','https://c'];
is $retry->{ok}[0]{data}{markdown}, 'B-now';
is $retry->{ok}[1]{data}{markdown}, 'C-now';

done_testing;

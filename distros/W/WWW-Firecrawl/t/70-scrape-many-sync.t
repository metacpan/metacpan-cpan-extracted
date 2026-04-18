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
    my ( $class, %script ) = @_;
    return bless { script => \%script, log => [] }, $class;
  }
  sub request {
    my ( $self, $req ) = @_;
    my ($url) = $req->content =~ /"url"\s*:\s*"([^"]+)"/;
    push @{ $self->{log} }, $url;
    my $r = $self->{script}{$url}
      or die "Test::ScriptUA: no script for $url";
    return $r;
  }
  sub log { $_[0]->{log} }
}

sub ok_scrape {
  my ( $url, $md ) = @_;
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ],
    encode_json({ success => JSON::MaybeXS::true(),
                  data => { markdown => $md, metadata => { sourceURL => $url, statusCode => 200 } } }),
  );
}

sub target_fail_scrape {
  my ( $url ) = @_;
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ],
    encode_json({ success => JSON::MaybeXS::true(),
                  data => { metadata => { sourceURL => $url, statusCode => 503, error => 'timeout' } } }),
  );
}

sub api_fail_scrape {
  return HTTP::Response->new( 400, 'Bad', [ 'Content-Type'=>'application/json' ],
    encode_json({ error => 'bad url' }));
}

my $script = {
  'https://a' => ok_scrape('https://a', 'A'),
  'https://b' => target_fail_scrape('https://b'),
  'https://c' => api_fail_scrape(),
  'https://d' => ok_scrape('https://d', 'D'),
};

my $ua = Test::ScriptUA->new(%$script);
my $fc = WWW::Firecrawl->new(
  base_url => 'http://x',
  ua => $ua,
  max_attempts => 1,
  sleep_sub => sub { },
);

my $result = $fc->scrape_many([qw( https://a https://b https://c https://d )]);
is ref $result, 'HASH';
is $result->{stats}{ok},     2;
is $result->{stats}{failed}, 2;
is $result->{stats}{total},  4;
is scalar @{ $result->{ok} },     2;
is scalar @{ $result->{failed} }, 2;

is $result->{ok}[0]{url}, 'https://a';
is $result->{ok}[1]{url}, 'https://d';
is $result->{failed}[0]{url}, 'https://b';
is $result->{failed}[1]{url}, 'https://c';

isa_ok $result->{failed}[0]{error}, 'WWW::Firecrawl::Error';
ok $result->{failed}[0]{error}->is_page;
is $result->{failed}[0]{error}->status_code, 503;
isa_ok $result->{failed}[1]{error}, 'WWW::Firecrawl::Error';
ok $result->{failed}[1]{error}->is_api;
is $result->{failed}[1]{error}->status_code, 400;

is_deeply $ua->log, [qw( https://a https://b https://c https://d )];

done_testing;

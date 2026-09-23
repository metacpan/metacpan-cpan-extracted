#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use WWW::OpenBao;

# Offline by construction — same stub pattern as t/20-request.t, t/30-login-k8s.t
# and t/40-delete-ladder.t: the lazy _http attribute is replaced with a stub
# whose request() records the method/url it was handed and returns a canned
# HTTP::Tiny-shaped response ({status, success, content}). No socket, no running
# OpenBao. Here we prove health() flattens every operational state to a 200 via
# the query parameters and hands back an inspectable body hashref, while a
# server that truly does not answer still maps to undef.
package Test::OpenBao::HTTPStub;

sub new {
  my ($class, $response) = @_;
  return bless { response => $response, calls => [] }, $class;
}

sub request {
  my ($self, $method, $url, $opts) = @_;
  push @{ $self->{calls} }, { method => $method, url => $url, opts => $opts };
  return $self->{response};
}

sub last_call  { $_[0]->{calls}[-1] }
sub call_count { scalar @{ $_[0]->{calls} } }

package main;

my $new_bao = sub {
  my ($response) = @_;
  my $stub = Test::OpenBao::HTTPStub->new($response);
  my $bao  = WWW::OpenBao->new(
    endpoint => 'http://test',
    token    => 't',
    _http    => $stub,
  );
  return ($bao, $stub);
};

# A 200 health response carrying an arbitrary health body.
my $health_200 = sub {
  my ($body) = @_;
  return { status => 200, success => 1, content => encode_json($body) };
};

#### The request carries the state-flattening query parameters
{
  my ($bao, $stub) = $new_bao->($health_200->({
    initialized => JSON->true, sealed => JSON->false, standby => JSON->false,
  }));

  $bao->health;

  is $stub->last_call->{method}, 'GET', 'health uses GET';
  is $stub->last_call->{url},
     'http://test/v1/sys/health?standbyok=true&perfstandbyok=true&sealedcode=200&uninitcode=200',
     'health hits sys/health with the full flattening query string';

  # And, spelled out, each parameter that makes an operational state answer 200.
  my $url = $stub->last_call->{url};
  like $url, qr/[?&]standbyok=true(?:&|$)/,     'standbyok=true present';
  like $url, qr/[?&]perfstandbyok=true(?:&|$)/, 'perfstandbyok=true present';
  like $url, qr/[?&]sealedcode=200(?:&|$)/,     'sealedcode=200 present (503 -> 200)';
  like $url, qr/[?&]uninitcode=200(?:&|$)/,     'uninitcode=200 present (501 -> 200)';
}

#### A sealed server (200 body, sealed=true) returns a hashref, not undef
{
  my ($bao, $stub) = $new_bao->($health_200->({
    initialized => JSON->true, sealed => JSON->true, standby => JSON->false,
    version => '2.6.0',
  }));

  my $h = $bao->health;
  ok defined $h && ref $h eq 'HASH', 'sealed server yields a hashref, not undef';
  ok  $h->{sealed},      'sealed=true is readable from the body';
  ok  $h->{initialized}, 'initialized=true is readable from the body';
  is  $h->{version}, '2.6.0', 'version field passes through';
}

#### An uninitialised server (200 body, initialized=false) returns a hashref
{
  my ($bao, $stub) = $new_bao->($health_200->({
    initialized => JSON->false, sealed => JSON->true, standby => JSON->false,
  }));

  my $h = $bao->health;
  ok defined $h && ref $h eq 'HASH', 'uninitialised server yields a hashref, not undef';
  ok !$h->{initialized}, 'initialized=false is readable (distinct from unreachable undef)';
}

#### A standby server (200 body, standby=true) returns a hashref
{
  my ($bao, $stub) = $new_bao->($health_200->({
    initialized => JSON->true, sealed => JSON->false, standby => JSON->true,
  }));

  my $h = $bao->health;
  ok defined $h && ref $h eq 'HASH', 'standby server yields a hashref, not undef';
  ok  $h->{standby}, 'standby=true is readable from the body';
  ok !$h->{sealed},  'sealed=false is readable from the body';
}

#### A non-2xx despite the flattening codes maps to undef (server errored)
{
  my ($bao, $stub) = $new_bao->({
    status => 500, success => 0, content => '{"errors":["boom"]}',
  });

  is $bao->health, undef, 'a 5xx (non-2xx even with the codes) yields undef';
  is $stub->call_count, 1, 'and it did reach the seam before failing';
}

#### A transport-level failure (unreachable host) maps to undef
# HTTP::Tiny signals a connection error as status 599 / success 0; _request
# croaks on it and health()'s eval turns that into undef.
{
  my ($bao, $stub) = $new_bao->({
    status => 599, success => 0, content => "Internal Exception: connect failed",
  });

  is $bao->health, undef, 'an unreachable host (599) yields undef';
}

done_testing;

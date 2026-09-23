#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use WWW::OpenBao;

# Minimal stub for the lazy _http attribute: request() returns a canned
# HTTP::Tiny-shaped response ({status, success, content}) and records what
# it was called with, so a test can also assert the seam actually reached
# the stub rather than short-circuiting somewhere else.
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

#### Case 1: 2xx with a JSON body is decode_json-ed into a hashref
{
  my $payload = { data => { data => { user => 'app' } }, extra => 'x' };
  my ($bao, $stub) = $new_bao->({
    status  => 200,
    success => 1,
    content => encode_json($payload),
  });

  my $result = $bao->_request('GET', 'v1/secret/data/foo/bar');
  is_deeply $result, $payload, '2xx JSON body decodes to the matching hashref';
  is $stub->call_count, 1,     'the _http stub was actually invoked';
}

#### Case 2: successful response with empty content yields {} (204 case)
{
  my ($bao, $stub) = $new_bao->({
    status  => 204,
    success => 1,
    content => '',
  });

  my $result = $bao->_request('POST', 'v1/secret/data/foo/bar');
  is_deeply $result, {}, '204 / empty content on success yields an empty hashref';
}

#### Case 3: 404 always yields undef, regardless of the success flag
{
  my ($bao, $stub) = $new_bao->({
    status  => 404,
    success => 0,
    content => '{"errors":["no value found"]}',
  });
  is $bao->_request('GET', 'v1/secret/data/missing'), undef,
     '404 with success=0 returns undef';
}
{
  my ($bao, $stub) = $new_bao->({
    status  => 404,
    success => 1,
    content => '',
  });
  is $bao->_request('GET', 'v1/secret/data/missing'), undef,
     '404 with success=1 still returns undef (status check wins over success)';
}

#### Case 4: any other non-2xx croaks, naming method and path
{
  my ($bao, $stub) = $new_bao->({
    status  => 500,
    success => 0,
    content => '{"errors":["internal error"]}',
  });

  my $result = eval { $bao->_request('GET', 'v1/secret/data/boom') };
  my $err    = $@;

  ok !defined $result, 'nothing is returned when _request croaks';
  ok $err,             'non-2xx response croaks';
  like $err, qr/OpenBao\s+GET\s+v1\/secret\/data\/boom/,
     'croak message names both the HTTP method and the path';
}

done_testing;

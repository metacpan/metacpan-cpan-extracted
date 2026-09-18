#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use WWW::OpenBao;

# Offline by construction — same stub pattern as the other request tests: the
# lazy _http attribute is replaced with a stub whose request() returns a canned
# HTTP::Tiny-shaped response ({status, success, content}). No socket, no server.
#
# secret_exists must NOT confuse "policy forbids this path" with "path absent".
# OpenBao answers 403 for paths that may well exist; only a real 404 means "not
# there". So 404 -> false, a live path -> true, and 403 (or any other non-2xx)
# propagates as a croak the caller can catch.
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

#### A live metadata read (2xx) means the path exists -> true
{
  my ($bao, $stub) = $new_bao->({
    status  => 200,
    success => 1,
    content => encode_json({ data => { metadata => { version => 2 } } }),
  });

  ok $bao->secret_exists('app/db'),
     'secret_exists is true when metadata reads back 2xx';
  is $stub->last_call->{method}, 'GET',
     'secret_exists reads via GET';
  is $stub->last_call->{url}, 'http://test/v1/secret/metadata/app/db',
     'secret_exists hits the metadata/ path';
}

#### A real 404 (absent path) is the only soft "no" -> false
{
  my ($bao, $stub) = $new_bao->({
    status  => 404,
    success => 0,
    content => '{"errors":["no value found"]}',
  });

  ok !$bao->secret_exists('missing'),
     'secret_exists is false on a genuine 404';
}

#### 403 (policy denies a path that may exist) must NOT be swallowed to false;
#### it propagates so the caller can tell "forbidden" from "absent".
{
  my ($bao, $stub) = $new_bao->({
    status  => 403,
    success => 0,
    content => '{"errors":["permission denied"]}',
  });

  my $result = eval { $bao->secret_exists('forbidden/path') };
  my $err    = $@;

  ok !defined $result, 'secret_exists returns nothing when it croaks on 403';
  ok $err,             '403 propagates as an exception instead of a false';
  like $err, qr/403/,  'the croak names the 403 status';
  like $err, qr{v1/secret/metadata/forbidden/path},
     'the croak names the path that was denied';
}

#### Any other non-2xx (e.g. 500) also propagates rather than reporting "absent"
{
  my ($bao, $stub) = $new_bao->({
    status  => 500,
    success => 0,
    content => '{"errors":["internal error"]}',
  });

  my $result = eval { $bao->secret_exists('boom') };
  ok !defined $result, 'secret_exists does not swallow a 500 into false';
  ok $@,               'a 500 propagates as an exception';
}

done_testing;

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
# read_secret_metadata surfaces the data.metadata block (version, created_time,
# destroyed, ...) that a KV v2 data read carries alongside the values. It is a
# separate entry point: read_secret must keep returning the bare data.data
# hashref, unchanged, so value-only consumers (goldmine, hiplatform) are not
# broken.
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

# A full KV v2 read envelope: data.data is the value map, data.metadata the
# version info that read_secret_metadata should return.
my $ok_body = sub {
  return {
    status  => 200,
    success => 1,
    content => encode_json({
      data => {
        data     => { user => 'app', pass => 'hunter2' },
        metadata => {
          version      => 4,
          destroyed    => JSON::MaybeXS::false(),
          created_time => '2026-09-09T07:13:12Z',
        },
      },
    }),
  };
};

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

#### read_secret_metadata returns the data.metadata block
{
  my ($bao, $stub) = $new_bao->($ok_body->());

  my $meta = $bao->read_secret_metadata('app/db');
  is $meta->{version}, 4,
     'read_secret_metadata returns the version from data.metadata';
  is $meta->{created_time}, '2026-09-09T07:13:12Z',
     'read_secret_metadata carries created_time';
  ok exists $meta->{destroyed},
     'read_secret_metadata carries the destroyed flag';

  is $stub->last_call->{method}, 'GET',
     'read_secret_metadata reads via GET';
  is $stub->last_call->{url}, 'http://test/v1/secret/data/app/db',
     'read_secret_metadata reads the data/ endpoint (metadata that rides the value read)';
}

#### read_secret keeps its existing shape: the bare data.data hashref, no metadata
{
  my ($bao, $stub) = $new_bao->($ok_body->());

  my $data = $bao->read_secret('app/db');
  is_deeply $data, { user => 'app', pass => 'hunter2' },
     'read_secret still returns only the data.data hashref';
  ok !exists $data->{metadata},
     'read_secret does not leak the metadata block into its return value';
}

#### 404 is a soft miss for the metadata accessor too -> undef
{
  my ($bao, $stub) = $new_bao->({
    status  => 404,
    success => 0,
    content => '{"errors":["no value found"]}',
  });

  is $bao->read_secret_metadata('missing'), undef,
     'read_secret_metadata returns undef on 404, like read_secret';
}

#### Custom kv_mount flows through the metadata read
{
  my $stub = Test::OpenBao::HTTPStub->new($ok_body->());
  my $bao  = WWW::OpenBao->new(
    endpoint => 'http://test',
    token    => 't',
    kv_mount => 'goldmine',
    _http    => $stub,
  );

  $bao->read_secret_metadata('a/b');
  is $stub->last_call->{url}, 'http://test/v1/goldmine/data/a/b',
     'read_secret_metadata honours a non-default kv_mount';
}

done_testing;

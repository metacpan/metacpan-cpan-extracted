#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use WWW::OpenBao;

# Offline by construction — same stub pattern as t/20-request.t and
# t/40-delete-ladder.t: the lazy _http attribute is replaced with a stub whose
# request() records the method/url/opts it was handed and returns a canned
# HTTP::Tiny-shaped response. No socket, no running OpenBao. Here we prove the
# optional version argument to read_secret: without it the request is the
# byte-identical latest-version GET on data/, with it the URL grows exactly a
# ?version=N query string, and the returned shape (data.data hashref, or undef
# on 404) is unchanged either way.
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

# The KV v2 read envelope: data.data is the secret map the method returns.
my $ok_body = sub {
  my ($secret) = @_;
  return {
    status  => 200,
    success => 1,
    content => encode_json({
      data => { data => $secret, metadata => { version => 3 } },
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

#### (a) No version: latest-version GET on data/, NO query string
{
  my ($bao, $stub) = $new_bao->($ok_body->({ user => 'app' }));
  my $secret = $bao->read_secret('app/db');

  is $stub->last_call->{method}, 'GET',
     'read_secret without a version uses GET';
  is $stub->last_call->{url}, 'http://test/v1/secret/data/app/db',
     'read_secret without a version hits data/ with NO ?version query string';
  is_deeply $secret, { user => 'app' },
     'read_secret without a version returns the data.data hashref';
}

#### (b) version => N: same data/ path plus ?version=N
{
  my ($bao, $stub) = $new_bao->($ok_body->({ user => 'app', pass => 'old' }));
  my $secret = $bao->read_secret('app/db', version => 2);

  is $stub->last_call->{method}, 'GET',
     'read_secret with a version uses GET';
  is $stub->last_call->{url}, 'http://test/v1/secret/data/app/db?version=2',
     'read_secret with version => N appends exactly ?version=N';
  is_deeply $secret, { user => 'app', pass => 'old' },
     'read_secret with a version returns the same data.data shape';
}

#### version => 0 is a real argument (defined, not truthy) and is passed through
{
  my ($bao, $stub) = $new_bao->($ok_body->({ user => 'app' }));
  $bao->read_secret('app/db', version => 0);

  is $stub->last_call->{url}, 'http://test/v1/secret/data/app/db?version=0',
     'version => 0 is honoured as an explicit argument, not dropped as "none"';
}

#### Custom kv_mount flows through the versioned read
{
  my $stub = Test::OpenBao::HTTPStub->new($ok_body->({ k => 'v' }));
  my $bao  = WWW::OpenBao->new(
    endpoint => 'http://test',
    token    => 't',
    kv_mount => 'goldmine',
    _http    => $stub,
  );

  $bao->read_secret('a/b', version => 5);
  is $stub->last_call->{url}, 'http://test/v1/goldmine/data/a/b?version=5',
     'versioned read honours a non-default kv_mount';
}

#### (d) 404 still returns undef, with and without a version
{
  my $miss = {
    status  => 404,
    success => 0,
    content => '{"errors":["no value found"]}',
  };

  my ($bao1, $stub1) = $new_bao->($miss);
  is $bao1->read_secret('missing'), undef,
     'read_secret returns undef on 404 (no version)';

  my ($bao2, $stub2) = $new_bao->($miss);
  is $bao2->read_secret('missing', version => 9), undef,
     'read_secret returns undef on 404 (versioned read of a soft-deleted/absent version)';
}

done_testing;

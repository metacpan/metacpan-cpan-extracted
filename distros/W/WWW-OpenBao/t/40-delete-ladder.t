#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use WWW::OpenBao;

# Offline by construction — same stub pattern as t/20-request.t and
# t/30-login-k8s.t: the lazy _http attribute is replaced with a stub whose
# request() records the method/url/opts it was handed and returns a canned
# HTTP::Tiny-shaped response. No socket, no running OpenBao, no k8s. Here we
# prove the KV v2 delete ladder maps each method to the right HTTP verb, the
# right tree (data/ delete/ undelete/ destroy/ metadata/) and the right
# versions body.
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

# 204-with-empty-body is what OpenBao actually answers to these writes.
my $no_content = sub {
  return { status => 204, success => 1, content => '' };
};

my $new_bao = sub {
  my $stub = Test::OpenBao::HTTPStub->new($no_content->());
  my $bao  = WWW::OpenBao->new(
    endpoint => 'http://test',
    token    => 't',
    _http    => $stub,
  );
  return ($bao, $stub);
};

# The decoded request body a recorded call carried, or undef if it carried none.
my $body_of = sub {
  my ($call) = @_;
  return undef unless defined $call->{opts}{content};
  return decode_json($call->{opts}{content});
};

#### Level 1, latest: soft_delete_secret() with no versions -> DELETE data/
{
  my ($bao, $stub) = $new_bao->();
  $bao->soft_delete_secret('app/db');

  is $stub->last_call->{method}, 'DELETE',
     'soft_delete_secret without versions uses DELETE (level 1, latest)';
  is $stub->last_call->{url}, 'http://test/v1/secret/data/app/db',
     'soft_delete_secret without versions hits data/ (soft-delete latest)';
  is $body_of->($stub->last_call), undef,
     'soft-delete-latest carries no request body';
}

#### Level 1, named: soft_delete_secret($path, @v) -> POST delete/ + versions
{
  my ($bao, $stub) = $new_bao->();
  $bao->soft_delete_secret('app/db', 2, 3);

  is $stub->last_call->{method}, 'POST',
     'soft_delete_secret with versions uses POST (level 1, named versions)';
  is $stub->last_call->{url}, 'http://test/v1/secret/delete/app/db',
     'soft_delete_secret with versions hits delete/, not data/';
  is_deeply $body_of->($stub->last_call), { versions => [2, 3] },
     'named soft-delete carries the versions list in the body';
}

#### Undelete: undelete_secret($path, @v) -> POST undelete/ + versions
{
  my ($bao, $stub) = $new_bao->();
  $bao->undelete_secret('app/db', 4);

  is $stub->last_call->{method}, 'POST',
     'undelete_secret uses POST';
  is $stub->last_call->{url}, 'http://test/v1/secret/undelete/app/db',
     'undelete_secret hits undelete/';
  is_deeply $body_of->($stub->last_call), { versions => [4] },
     'undelete carries the versions list in the body';
}

#### Level 2: destroy_secret($path, @v) -> PUT destroy/ + versions
{
  my ($bao, $stub) = $new_bao->();
  $bao->destroy_secret('app/db', 1, 2);

  is $stub->last_call->{method}, 'PUT',
     'destroy_secret uses PUT (level 2, irreversible)';
  is $stub->last_call->{url}, 'http://test/v1/secret/destroy/app/db',
     'destroy_secret hits destroy/';
  is_deeply $body_of->($stub->last_call), { versions => [1, 2] },
     'destroy carries the versions list in the body';
}

#### Level 3 (unchanged): delete_secret($path) -> DELETE metadata/
# Guards the existing public-API contract: delete_secret must keep hitting the
# irreversible metadata/ tree, not the new reversible ones.
{
  my ($bao, $stub) = $new_bao->();
  $bao->delete_secret('app/db');

  is $stub->last_call->{method}, 'DELETE',
     'delete_secret still uses DELETE';
  is $stub->last_call->{url}, 'http://test/v1/secret/metadata/app/db',
     'delete_secret still hits metadata/ (level 3, contract unchanged)';
}

#### The version-required methods croak before touching the seam
{
  my ($bao, $stub) = $new_bao->();

  eval { $bao->undelete_secret('app/db') };
  like $@, qr/undelete_secret requires at least one version/,
     'undelete_secret croaks when called with no versions';

  eval { $bao->destroy_secret('app/db') };
  like $@, qr/destroy_secret requires at least one version/,
     'destroy_secret croaks when called with no versions';

  is $stub->call_count, 0,
     'a version-less undelete/destroy never reaches the HTTP seam';
}

#### Custom kv_mount flows through the new ladder path helpers
{
  my $stub = Test::OpenBao::HTTPStub->new($no_content->());
  my $bao  = WWW::OpenBao->new(
    endpoint => 'http://test',
    token    => 't',
    kv_mount => 'goldmine',
    _http    => $stub,
  );

  $bao->destroy_secret('a/b', 7);
  is $stub->last_call->{url}, 'http://test/v1/goldmine/destroy/a/b',
     'destroy_secret honours a non-default kv_mount';
}

done_testing;

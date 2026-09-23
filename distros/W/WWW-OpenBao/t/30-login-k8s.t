#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use WWW::OpenBao;

# Same offline pattern as t/20-request.t: stub the lazy _http attribute so the
# request never leaves the process. request() returns a canned HTTP::Tiny-shaped
# response and records the method/url it was called with, letting us assert
# exactly which auth mount path login_k8s posted to. No socket, no k8s.
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

sub last_call { $_[0]->{calls}[-1] }

package main;

# A successful Kubernetes login envelope, enough for login_k8s to pull the
# client_token out of and hand back the auth hashref.
my $login_response = sub {
  return {
    status  => 200,
    success => 1,
    content => encode_json({
      auth => { client_token => 'k8s-token', policies => ['default'] },
    }),
  };
};

my $new_bao = sub {
  my (%args) = @_;
  my $stub = Test::OpenBao::HTTPStub->new($login_response->());
  my $bao  = WWW::OpenBao->new(
    endpoint => 'http://test',
    token    => '',
    _http    => $stub,
    %args,
  );
  return ($bao, $stub);
};

#### Case 1: the default mount still hits v1/auth/kubernetes/login (byte-identical)
{
  my ($bao, $stub) = $new_bao->();
  is $bao->k8s_auth_mount, 'kubernetes', 'k8s_auth_mount defaults to kubernetes';

  # jwt is passed so _read_sa_token() (which slurps a file) is never reached.
  my $auth = $bao->login_k8s(role => 'my-app', jwt => 'jwt-blob');

  is $stub->last_call->{method}, 'POST',
     'login_k8s posts';
  is $stub->last_call->{url}, 'http://test/v1/auth/kubernetes/login',
     'default mount posts to v1/auth/kubernetes/login';
  is $bao->token, 'k8s-token',
     'client_token from the response is stored in token';
  is_deeply $auth, { client_token => 'k8s-token', policies => ['default'] },
     'the full auth hashref is returned';
}

#### Case 2: a non-default mount hits v1/auth/<mount>/login
{
  my ($bao, $stub) = $new_bao->(k8s_auth_mount => 'kubernetes-prod');
  is $bao->k8s_auth_mount, 'kubernetes-prod', 'custom k8s_auth_mount honoured';

  $bao->login_k8s(role => 'my-app', jwt => 'jwt-blob');

  is $stub->last_call->{url}, 'http://test/v1/auth/kubernetes-prod/login',
     'custom mount posts to v1/auth/<mount>/login';
}

done_testing;

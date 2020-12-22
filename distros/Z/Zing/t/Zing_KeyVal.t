use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::KeyVal

=cut

=tagline

Key/Value Store

=cut

=abstract

Generic Key/Value Store

=cut

=includes

method: poll
method: recv
method: send
method: term

=cut

=synopsis

  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');

  # $keyval->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Repo

=cut

=attributes

name: ro, opt, Str

=cut

=description

This package provides a general-purpose key/value store abstraction.

=cut

=method poll

The poll method returns a L<Zing::Poll> object which can be used to perform a
blocking-fetch from the store.

=signature poll

poll() : Poll

=example-1 poll

  # given: synopsis

  $keyval->poll;

=cut

=method recv

The recv method fetches the data (if any) from the store.

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $keyval->recv;

=example-2 recv

  # given: synopsis

  $keyval->send({ status => 'happy' });

  $keyval->recv;

=cut

=method send

The send method commits data to the store overwriting any existing data.

=signature send

send(HashRef $value) : Str

=example-1 send

  # given: synopsis

  $keyval->send({ status => 'happy' });

=example-2 send

  # given: synopsis

  $keyval->drop;

  $keyval->send({ status => 'happy' });

=cut

=method term

The term method generates a term (safe string) for the datastore.

=signature term

term() : Str

=example-1 term

  # given: synopsis

  $keyval->term;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'poll', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, { status => 'happy' };

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'OK';

  $result
});

$subs->example(-2, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'OK';

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/zing:main:global:keyval:notes/;

  $result
});

ok 1 and done_testing;

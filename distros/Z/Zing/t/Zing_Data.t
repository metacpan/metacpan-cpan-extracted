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

Zing::Data

=cut

=tagline

Process Data

=cut

=abstract

Process Key/Val Data Store

=cut

=includes

method: recv
method: send

=cut

=synopsis

  use Zing::Data;
  use Zing::Process;

  my $data = Zing::Data->new(process => Zing::Process->new);

  # $data->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::KeyVal

=cut

=attributes

name: ro, opt, Str
process: ro, req, Process

=cut

=description

This package provides a process-specific key/value store for arbitrary data.

=cut

=method recv

The recv method fetches the data (if any) from the store.

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $data->recv;

=example-2 recv

  # given: synopsis

  $data->send({ status => 'works' });

  $data->recv;

=cut

=method send

The send method commits data to the store overwriting any existing data.

=signature send

send(HashRef $value) : Str

=example-1 send

  # given: synopsis

  $data->send({ status => 'works' });

=example-2 send

  # given: synopsis

  $data->drop;

  $data->send({ status => 'works' });

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, { status => 'works' };

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

ok 1 and done_testing;

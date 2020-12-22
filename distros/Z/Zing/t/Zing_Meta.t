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

Zing::Meta

=cut

=tagline

Process Metadata

=cut

=abstract

Generic Process Metadata

=cut

=includes

method: drop
method: recv
method: send
method: term

=cut

=synopsis

  use Zing::Meta;

  my $meta = Zing::Meta->new(name => rand);

  # $meta->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::KeyVal

=cut

=attributes

name: ro, opt, Str

=cut

=description

This package provides process metadata for tracking active processes.

=cut

=method drop

The drop method returns truthy if the process metadata can be dropped.

=signature drop

drop() : Int

=example-1 drop

  # given: synopsis

  $meta->drop;

=cut

=method recv

The recv method fetches the process metadata (if any).

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $meta->recv;

=example-2 recv

  # given: synopsis

  use Zing::Process;

  $meta->send(Zing::Process->new->metadata);

  $meta->recv;

=cut

=method send

The send method commits the metadata provided to the store overwriting any
existing data.

=signature send

send(HashRef $proc) : Str

=example-1 send

  # given: synopsis

  $meta->send({ created => time });

=example-2 send

  # given: synopsis

  use Zing::Process;

  $meta->drop;

  $meta->send(Zing::Process->new->metadata);

=cut

=method term

The term method generates a term (safe string) for the metadata.

=signature term

term(Str @keys) : Str

=example-1 term

  # given: synopsis

  $meta->term;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'drop', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply [sort keys %$result], [
    'data',
    'host',
    'mailbox',
    'name',
    'parent',
    'process',
    'tag',
  ];

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'OK';

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'OK';

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/zing:main:global:meta:[^:]+/;

  $result
});

ok 1 and done_testing;

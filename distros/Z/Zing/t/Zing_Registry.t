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

Zing::Registry

=cut

=tagline

Process Registry

=cut

=abstract

Generic Process Registry

=cut

=includes

method: drop
method: recv
method: send
method: term

=cut

=synopsis

  use Zing::Process;
  use Zing::Registry;

  my $process = Zing::Process->new;
  my $registry = Zing::Registry->new(process => $process);

  # $registry->recv($process);

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

This package provides a process registry for tracking active processes.

=cut

=method drop

The drop method returns truthy if the process can be dropped from the registry.

=signature drop

drop(Process $proc) : Int

=example-1 drop

  # given: synopsis

  $registry->drop($process);

=cut

=method recv

The recv method fetches the process metadata (if any) from the registry.

=signature recv

recv(Process $proc) : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $registry->recv($process);

=example-2 recv

  # given: synopsis

  $registry->send($process);

  $registry->recv($process);

=cut

=method send

The send method commits the process metadata to the registry overwriting any
existing data.

=signature send

send(Process $proc) : Str

=example-1 send

  # given: synopsis

  $registry->send($process);

=example-2 send

  # given: synopsis

  $registry->drop;

  $registry->send($process);

=cut

=method term

The term method generates a term (safe string) for the registry.

=signature term

term(Str @keys) : Str

=example-1 term

  # given: synopsis

  $registry->term($process->name);

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
    'mailbox',
    'name',
    'node',
    'parent',
    'process',
    'server',
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
  my $local = qr/zing:main:local\(\d+\.\d+\.\d+\.\d+\)/;
  my $process = qr/\d+\.\d+\.\d+\.\d+:\d+:\d+:\d+/;
  like $result, qr/$local:registry:\$default:$process/;

  $result
});

ok 1 and done_testing;

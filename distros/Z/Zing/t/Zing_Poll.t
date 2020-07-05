use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Poll

=cut

=tagline

Blocking Receive

=cut

=abstract

Blocking Receive Construct

=cut

=includes

method: await

=cut

=synopsis

  use Zing::Poll;
  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');
  my $poll = Zing::Poll->new(name => 'last-week', repo => $keyval);

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, req, Str
repo: ro, req, Repo

=cut

=description

This package provides an algorithm for preforming a blocking receive by polling
the datastore for a specific item.

=cut

=method await

The await method polls the datastore specified for the data at the key
specified, for at-least the number of seconds specified, and returns the data
or undefined.

=signature await

await(Int $secs) : Maybe[HashRef]

=example-1 await

  # given: synopsis

  $poll->await(0);

=example-2 await

  # given: synopsis

  $poll->repo->send('last-week', { task => 'write research paper' });

  $poll->await(0);

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'await', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'await', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, { task => 'write research paper' };
  $result
});

ok 1 and done_testing;

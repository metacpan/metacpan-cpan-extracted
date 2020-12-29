use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Journal

=cut

=tagline

System Journal

=cut

=abstract

Central System Journal

=cut

=includes

method: stream
method: term

=cut

=synopsis

  use Zing::Journal;

  my $journal = Zing::Journal->new;

  # $journal->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Channel

=cut

=attributes

name: ro, opt, Str
level: ro, opt, Str
tap: rw, opt, Bool
verbose: ro, opt, Bool

=cut

=description

This package provides the default central mechanism for creating and retrieving
process event logs.

=cut

=method stream

The stream method taps the process event log and executes the provided callback
for each new event.

=signature stream

stream(CodeRef $callback) : Object

=example-1 stream

  # given: synopsis

  my $example = {
    from => '...',
    data => {logs => {}},
  };

  for (1..5) {
    $journal->send($example);
  }

  $journal->stream(sub {
    my ($info, $data, $lines) = @_;
    $journal->tap(0); # stop
  });

=cut

=method term

The term method returns the name of the journal.

=signature term

term() : Str

=example-1 term

  # given: synopsis

  $journal->term;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'stream', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/zing:main:global:channel:\$journal/;

  $result
});

ok 1 and done_testing;

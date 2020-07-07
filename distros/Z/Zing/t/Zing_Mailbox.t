use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Mailbox

=cut

=tagline

Process Mailbox

=cut

=abstract

Interprocess Communication Mechanism

=cut

=includes

method: recv
method: reply
method: send
method: size

=cut

=synopsis

  use Zing::Mailbox;
  use Zing::Process;

  my $mailbox = Zing::Mailbox->new(process => Zing::Process->new);

  # $mailbox->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::PubSub

=cut

=attributes

name: ro, opt, Str
process: ro, req, Process

=cut

=description

This package provides represents a process mailbox, the default mechanism of
interprocess communication.

=cut

=method recv

The recv method receives a single new message from the mailbox.

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $mailbox->recv;

=example-2 recv

  # given: synopsis

  $mailbox->send($mailbox->term, { status => 'hello' });

  $mailbox->recv;

=cut

=method reply

The reply method sends a message to the mailbox represented by the C<$bag>
received and returns the size of the recipient mailbox.

=signature reply

reply(HashRef $bag, HashRef $value) : Int

=example-1 reply

  # given: synopsis

  $mailbox->send($mailbox->term, { status => 'hello' });

  my $data = $mailbox->recv;

  $mailbox->reply($data, { status => 'thank you' });

=cut

=method send

The send method sends a new message to the mailbox specified and returns the
size of the recipient mailbox.

=signature send

send(Str $key, HashRef $value) : Int

=example-1 send

  # given: synopsis

  $mailbox->send($mailbox->term, { status => 'hello' });

=cut

=method size

The size method returns the message count of the mailbox.

=signature size

size() : Int

=example-1 size

  # given: synopsis

  my $size = $mailbox->size;

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
  is_deeply $result->{data}, { status => 'hello' };

  $result
});

$subs->example(-1, 'reply', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'size', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

ok 1 and done_testing;

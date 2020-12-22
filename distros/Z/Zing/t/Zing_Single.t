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

Zing::Single

=cut

=tagline

Single Process

=abstract

Single Process

=cut

=synopsis

  package MyApp;

  use parent 'Zing::Single';

  sub perform {
    my ($self) = @_;

    time;
  }

  sub receive {
    my ($self, $from, $data) = @_;

    [$from, $data];
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=description

This package provides a L<Zing::Process> which runs once and shuts-down, but
otherwise operates as a typical process and invokes its C<receive> and
C<perform> methods.

=cut

=scenario perform

The perform method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=example perform

  # given: synopsis

  $myapp->perform;

=scenario receive

The receive method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop whenever a process receives
a message in its mailbox.

=example receive

  # given: synopsis

  $myapp->receive($myapp->name, { task => 'fuzzy_logic' });

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('MyApp');
  ok $result->isa('Zing::Single');

  $result
});

$subs->scenario('perform', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('receive', fun($tryable) {
  ok my $result = $tryable->result;
  like $result->[0], qr/^\w{40}$/;
  is_deeply $result->[1], { task => 'fuzzy_logic' };

  $result
});

ok 1 and done_testing;

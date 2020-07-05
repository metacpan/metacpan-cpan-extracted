use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

use Zing::Queue;

=name

Zing::Zang::Watcher

=cut

=tagline

Watcher Process

=abstract

Watcher Process Implementation

=cut

=synopsis

  use Zing::Zang::Watcher;

  my $zang = Zing::Zang::Watcher->new(
    on_perform => sub {
      my ($self) = @_;

      $self->{performed}++
    },
    scheme => ['MyApp', [], 1],
  );

  # $zang->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Watcher

=cut

=attributes

on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]
scheme: ro, req, Scheme

=cut

=description

This package provides a L<Zing::Watcher> which uses callbacks and doesn't need
to be subclassd. It supports providing a process C<perform> method as
C<on_perform> and a C<receive> method as C<on_receive> which operate as
expected, and also requires a C<scheme> to be launched on execution.

=cut

package MyApp;

use parent 'Zing::Process';

our $DATA = 0;

sub perform {
  $DATA++
}

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  $result->execute;
  ok $result->{performed};
  is $MyApp::DATA, 1;

  $result
});

ok 1 and done_testing;

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

Zing::Zang

=cut

=tagline

Process Implementation

=abstract

Process Implementation

=cut

=synopsis

  use Zing::Zang;

  my $zang = Zing::Zang->new(
    on_perform => sub {
      my ($self) = @_;

      $self->{performed}++
    }
  );

  # $zang->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=attributes

on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]

=cut

=description

This package provides a standard L<Zing::Process> which uses callbacks and
doesn't need to be subclassed. It supports providing the standard process
C<perform> method as C<on_perform> and C<receive> method as C<on_receive> which
operate as expected.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  $result->execute;
  is $result->{performed}, 1;

  $result
});

ok 1 and done_testing;

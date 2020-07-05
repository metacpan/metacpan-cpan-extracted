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

Zing::Zang::Single

=cut

=tagline

Single-Task Process

=abstract

Single-Task Process Implementation

=cut

=synopsis

  use Zing::Zang::Single;

  my $zang = Zing::Zang::Single->new(
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

Zing::Single

=cut

=attributes

on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]

=cut

=description

This package provides a standard L<Zing::Process> which uses callbacks and
doesn't need to be subclassd. It supports providing the standard process
C<perform> method as C<on_perform> and C<receive> method as C<on_receive> which
operate as expected. This process executes its loop only once.

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

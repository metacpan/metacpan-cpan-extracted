use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Class

=cut

=tagline

Base Class

=cut

=abstract

Abstract Base Class

=cut

=includes

method: throw
method: try

=cut

=synopsis

  use Zing::Class;

  my $class = Zing::Class->new;

  # $class->throw;

=cut

=libraries

Zing::Types

=cut

=description

This package provides an abstract base class for L<Zing> classes.

=cut

=method throw

The throw method throws a L<Zing::Error> exception.

=signature throw

throw(Any @args) : Error

=example-1 throw

  # given: synopsis

  $class->throw(message => 'Oops');

=cut

=method try

The try method returns a tryable object based on the method and arguments
provided.

=signature try

try(Str $method, Any @args) : InstanceOf["Data::Object::Try"]

=example-1 try

  # given: synopsis

  $class->try('throw', message => 'Oops');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'throw', 'method', fun($tryable) {
  my $caught = 0;
  my $return;
  $tryable->catch('Zing::Error', fun($error) {
    $return = $error;
    $caught++;
  });
  ok !(my $result = $tryable->result);
  ok $caught;

  $return
});

$subs->example(-1, 'try', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;

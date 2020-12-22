use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Error

=cut

=tagline

Exception Class

=cut

=abstract

Generic Exception Class

=cut

=synopsis

  use Zing::Error;

  my $error = Zing::Error->new(
    message => 'Oops',
  );

  # die $error;

=cut

=libraries

Zing::Types

=cut

=inherits

Data::Object::Exception

=cut

=description

This package provides a generic L<Zing> exception class.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;

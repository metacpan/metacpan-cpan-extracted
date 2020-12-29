use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::ID

=cut

=tagline

Conditionally Unique Identifier

=cut

=abstract

Conditionally Unique Identifier

=cut

=includes

method: string

=cut

=synopsis

  use Zing::ID;

  my $id = Zing::ID->new;

  # "$id"

=cut

=libraries

Zing::Types

=cut

=attributes

host: ro, opt, Str
iota: ro, opt, Int
pid: ro, opt, Int
salt: ro, opt, Str
time: ro, opt, Int

=cut

=description

This package provides a globally unique identifier.

=cut

=method string

The string method serializes the object properties and generates a globally
unique identifier.

=signature string

string() : Str

=example-1 string

  # given: synopsis

  $id->string;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'string', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/^\w{40}$/;

  $result
});

ok 1 and done_testing;

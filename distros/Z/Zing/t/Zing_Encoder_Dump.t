use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Encoder::Dump

=cut

=tagline

Perl Serialization Abstraction

=cut

=abstract

Perl Data Serialization Abstraction

=cut

=includes

method: decode
method: encode

=cut

=synopsis

  use Zing::Encoder::Dump;

  my $encoder = Zing::Encoder::Dump->new;

  # $encoder->encode({ status => 'okay' });

=cut

=libraries

Zing::Types

=cut

=description

This package provides a L<Data::Dumper|Perl> data serialization abstraction for
use with L<Zing::Store> stores.

=cut

=method decode

The decode method decodes the data provided.

=signature decode

decode(Str $data) : HashRef

=example-1 decode

  # given: synopsis

  $encoder->decode('{ "status","okay" }');

=cut

=method encode

The encode method encodes the data provided.

=signature encode

encode(HashRef $data) : Str

=example-1 encode

  # given: synopsis

  $encoder->encode({ status => 'okay' });

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'decode', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, { status => 'okay' };

  $result
});

$subs->example(-1, 'encode', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  $result =~ s/[\n\s]//g;
  is $result, '{status=>"okay"}';

  $result
});

ok 1 and done_testing;

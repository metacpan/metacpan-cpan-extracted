use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;

=name

Zing::Encoder::Jwt

=cut

=tagline

JWT Serialization Abstraction

=cut

=abstract

JWT Data Serialization Abstraction

=cut

=includes

method: decode
method: encode

=cut

=synopsis

  use Zing::Encoder::Jwt;

  my $encoder = Zing::Encoder::Jwt->new(
    secret => '...',
  );

  # $encoder->encode({ status => 'okay' });

=cut

=libraries

Zing::Types

=cut

=description

This package provides a L<Crypt::JWT> data serialization abstraction for use
with L<Zing::Store> stores. The JWT encoding algorithm can be set using the
C<ZING_JWT_ALGO> environment variable or the I<algo> attribute, and defaults to
I<HS256>. The JWT secret can be set using the C<ZING_JWT_SECRET> environment
variable or the I<secret> attribute.

=cut

=method decode

The decode method decodes the data provided.

=signature decode

decode(Str $data) : HashRef

=example-1 decode

  # given: synopsis

  $encoder->decode('eyJhbGciOiJIUzI1NiJ9.eyJzdGF0dXMiOiJva2F5In0.tXdQmMPi25VOJZaOySFS-hM2ofIxbyFBVTA7I-GI_lU');

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
  $result =~ s/\s//g;
  is $result, 'eyJhbGciOiJIUzI1NiJ9.eyJzdGF0dXMiOiJva2F5In0.tXdQmMPi25VOJZaOySFS-hM2ofIxbyFBVTA7I-GI_lU';

  $result
});

ok 1 and done_testing;

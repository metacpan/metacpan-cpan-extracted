package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

if (require Venus::Random && Venus::Random->new(42)->range(1, 50) != 38) {
  diag "OS ($^O) rand function is undeterministic" if $ENV{VENUS_DEBUG};
  goto SKIP;
}

my $test = test(__FILE__);

sub trunc {
  map substr($_, 0, 12), ref $_[0] eq 'ARRAY' ? @$_[0] : @_
}

=name

Venus::Random

=cut

$test->for('name');

=tagline

Random Class

=cut

$test->for('tagline');

=abstract

Random Class for Perl 5

=cut

$test->for('abstract');

=includes

method: alphanumeric
method: alphanumerics
method: base64
method: bit
method: bits
method: boolean
method: byte
method: bytes
method: character
method: characters
method: collect
method: digest
method: digit
method: digits
method: float
method: hexdecimal
method: hexdecimals
method: id
method: letter
method: letters
method: lowercased
method: new
method: nonce
method: nonzero
method: number
method: numbers
method: password
method: pick
method: range
method: repeat
method: reseed
method: reset
method: restore
method: select
method: shuffle
method: symbol
method: symbols
method: token
method: uppercased
method: urlsafe
method: uuid

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Random;

  my $random = Venus::Random->new(42);

  # my $bit = $random->bit;

  # 1

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Random');

  $result
});

=description

This package provides an object-oriented interface for Perl's pseudo-random
number generator (or PRNG) which produces a deterministic sequence of bits
which approximate true randomness.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Accessible
Venus::Role::Buildable
Venus::Role::Valuable

=cut

$test->for('inherits');

=method alphanumeric

The alphanumeric method returns a random alphanumeric character, which is
either a L</digit>, or L</letter> value.

=signature alphanumeric

  alphanumeric() (string)

=metadata alphanumeric

{
  since => '4.15',
}

=example-1 alphanumeric

  # given: synopsis

  package main;

  my $alphanumeric = $random->alphanumeric;

  # "C"

  # $alphanumeric = $random->alphanumeric;

  # 0

=cut

$test->for('example', 1, 'alphanumeric', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->alphanumeric, 'C';
  is $random->alphanumeric, '0';
  is $random->alphanumeric, 'M';
  is $random->alphanumeric, 'm';
  is $random->alphanumeric, 'a';
  is $random->alphanumeric, 'x';
  is $random->alphanumeric, '5';
  is $random->alphanumeric, '4';
  is $random->alphanumeric, '9';
  is $random->alphanumeric, '8';
  is $random->alphanumeric, 'g';
  is $random->alphanumeric, '0';
  is $random->alphanumeric, '7';
  is $random->alphanumeric, '2';
  is $random->alphanumeric, '5';
  is $random->alphanumeric, 'U';
  is $random->alphanumeric, 'C';
  is $random->alphanumeric, 'w';
  is $random->alphanumeric, 'O';
  is $random->alphanumeric, 'I';
  is $random->alphanumeric, '1';
  is $random->alphanumeric, '2';
  is $random->alphanumeric, 'N';
  is $random->alphanumeric, 'r';
  is $random->alphanumeric, '2';
  is $random->alphanumeric, '6';
  is $random->alphanumeric, '4';
  is $random->alphanumeric, 'V';
  is $random->alphanumeric, '6';
  is $random->alphanumeric, '5';
  is $random->alphanumeric, '2';
  is $random->alphanumeric, 'V';
  is $random->alphanumeric, 'v';
  is $random->alphanumeric, 'Q';
  is $random->alphanumeric, '9';
  is $random->alphanumeric, '5';
  is $random->alphanumeric, 'a';
  is $random->alphanumeric, 'h';
  is $random->alphanumeric, 'c';
  is $random->alphanumeric, '5';
  is $random->alphanumeric, '8';
  is $random->alphanumeric, 'Q';
  is $random->alphanumeric, '8';
  is $random->alphanumeric, 'p';
  is $random->alphanumeric, 'p';
  is $random->alphanumeric, '9';
  is $random->alphanumeric, '2';
  is $random->alphanumeric, '7';
  is $random->alphanumeric, '5';
  is $random->alphanumeric, '4';

  $result
});

=method alphanumerics

The alphanumerics method returns C<n> L</alphanumeric> characters based on the
number (i.e. count) provided.

=signature alphanumerics

  alphanumerics(number $count) (string)

=metadata alphanumerics

{
  since => '4.15',
}

=example-1 alphanumerics

  # given: synopsis

  package main;

  my $alphanumerics = $random->alphanumerics(5);

  # "C0Mma"

  # $alphanumerics = $random->alphanumerics(5);

  # "x5498"

=cut

$test->for('example', 1, 'alphanumerics', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->alphanumerics(5), 'C0Mma';
  is $random->alphanumerics(5), 'x5498';
  is $random->alphanumerics(5), 'g0725';
  is $random->alphanumerics(5), 'UCwOI';
  is $random->alphanumerics(5), '12Nr2';
  is $random->alphanumerics(5), '64V65';
  is $random->alphanumerics(5), '2VvQ9';
  is $random->alphanumerics(5), '5ahc5';
  is $random->alphanumerics(5), '8Q8pp';
  is $random->alphanumerics(5), '92754';
  is $random->alphanumerics(5), '410K0';
  is $random->alphanumerics(5), 'Tj5V8';
  is $random->alphanumerics(5), 'bV5g0';
  is $random->alphanumerics(5), 'k7zp8';
  is $random->alphanumerics(5), '2944C';
  is $random->alphanumerics(5), 'v4m56';
  is $random->alphanumerics(5), 'q1n8s';
  is $random->alphanumerics(5), '513cQ';
  is $random->alphanumerics(5), 'r1r4A';
  is $random->alphanumerics(5), '7Wcd1';
  is $random->alphanumerics(5), 'pcM0i';
  is $random->alphanumerics(5), '2j745';
  is $random->alphanumerics(5), '1lgUl';
  is $random->alphanumerics(5), '0KA11';
  is $random->alphanumerics(5), 'eu1p8';
  is $random->alphanumerics(5), '980g8';
  is $random->alphanumerics(5), 'eqq3s';
  is $random->alphanumerics(5), '779kh';
  is $random->alphanumerics(5), 'ib4K1';
  is $random->alphanumerics(5), '4j038';
  is $random->alphanumerics(5), '0Z697';
  is $random->alphanumerics(5), '8N4j4';
  is $random->alphanumerics(5), '04a98';
  is $random->alphanumerics(5), '94dWb';
  is $random->alphanumerics(5), 'lke65';
  is $random->alphanumerics(5), 'Bq5k4';
  is $random->alphanumerics(5), '3bVhm';
  is $random->alphanumerics(5), '59J4i';
  is $random->alphanumerics(5), '1IPc8';
  is $random->alphanumerics(5), '2O61T';
  is $random->alphanumerics(5), '1e78C';
  is $random->alphanumerics(5), 'G563m';
  is $random->alphanumerics(5), 'U8d05';
  is $random->alphanumerics(5), '5U1IT';
  is $random->alphanumerics(5), '5T60A';
  is $random->alphanumerics(5), '25430';
  is $random->alphanumerics(5), '243p0';
  is $random->alphanumerics(5), '133Y8';
  is $random->alphanumerics(5), '5GpBD';
  is $random->alphanumerics(5), 'ZX4x8';

  $result
});

=method base64

The base64 method returns a unique randomly generated base64 encoded string.

=signature base64

  base64() (string)

=metadata base64

{
  since => '4.15',
}

=cut

=example-1 base64

  # given: synopsis

  package main;

  my $base64 = $random->base64;

  # "gApCFiIVBS7JHxtVDkvQmOe2CU2RsVgzauI5EMMYI9s="

  # $base64 = $random->base64;

  # "ZdxOdj268Ge18X97cKr5yH6EJqfEdbI1OeeWJVH/XFQ="

=cut

$test->for('example', 1, 'base64', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;
  isnt +($last = $random->base64), $random->base64;

  $result
});

=method bits

The bits method returns C<n> L</bit> characters based on the number (i.e.
count) provided.

=signature bits

  bits(number $count) (string)

=metadata bits

{
  since => '4.15',
}

=example-1 bits

  # given: synopsis

  package main;

  my $bits = $random->bits(5);

  # "01111"

  # $bits = $random->bits(5);

  # "01100"

=cut

$test->for('example', 1, 'bits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->bits(5), '01111';
  is $random->bits(5), '01100';
  is $random->bits(5), '10010';
  is $random->bits(5), '00101';
  is $random->bits(5), '11010';
  is $random->bits(5), '00111';
  is $random->bits(5), '10111';
  is $random->bits(5), '00100';
  is $random->bits(5), '11000';
  is $random->bits(5), '01001';
  is $random->bits(5), '11111';
  is $random->bits(5), '01000';
  is $random->bits(5), '01110';
  is $random->bits(5), '11010';
  is $random->bits(5), '10101';
  is $random->bits(5), '10100';
  is $random->bits(5), '00010';
  is $random->bits(5), '10100';
  is $random->bits(5), '01001';
  is $random->bits(5), '00110';
  is $random->bits(5), '10010';
  is $random->bits(5), '10000';
  is $random->bits(5), '00010';
  is $random->bits(5), '11101';
  is $random->bits(5), '01111';
  is $random->bits(5), '11110';
  is $random->bits(5), '11110';
  is $random->bits(5), '10001';
  is $random->bits(5), '10010';
  is $random->bits(5), '10001';
  is $random->bits(5), '01010';
  is $random->bits(5), '00111';
  is $random->bits(5), '00110';
  is $random->bits(5), '00000';
  is $random->bits(5), '01011';
  is $random->bits(5), '10111';
  is $random->bits(5), '10110';
  is $random->bits(5), '00110';
  is $random->bits(5), '01101';
  is $random->bits(5), '00001';
  is $random->bits(5), '10001';
  is $random->bits(5), '00001';
  is $random->bits(5), '01111';
  is $random->bits(5), '00101';
  is $random->bits(5), '00001';
  is $random->bits(5), '10001';
  is $random->bits(5), '10111';
  is $random->bits(5), '00100';
  is $random->bits(5), '01001';
  is $random->bits(5), '11000';

  $result
});

=method bit

The bit method returns a C<1> or C<0> value, randomly.

=signature bit

  bit() (number)

=metadata bit

{
  since => '1.11',
}

=example-1 bit

  # given: synopsis

  package main;

  my $bit = $random->bit;

  # 0

  # $bit = $random->bit;

  # 1

=cut

$test->for('example', 1, 'bit', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  my $random = Venus::Random->new(42);

  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;
  is $random->bit, 0;
  is $random->bit, 0;
  is $random->bit, 1;

  !$result
});

=method boolean

The boolean method returns a C<true> or C<false> value, randomly.

=signature boolean

  boolean() (boolean)

=metadata boolean

{
  since => '1.11',
}

=example-1 boolean

  # given: synopsis

  package main;

  my $boolean = $random->boolean;

  # 0

  # $boolean = $random->boolean;

  # 1

=cut

$test->for('example', 1, 'boolean', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  my $random = Venus::Random->new(42);

  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;
  is $random->boolean, 0;
  is $random->boolean, 0;
  is $random->boolean, 1;

  !$result
});

=method byte

The byte method returns random byte characters, randomly.

=signature byte

  byte() (string)

=metadata byte

{
  since => '1.11',
}

=example-1 byte

  # given: synopsis

  package main;

  my $byte = $random->byte;

  # "\xBE"

  # $byte = $random->byte;

  # "W"

=cut

$test->for('example', 1, 'byte', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->byte, "\xBE";
  is $random->byte, "W";
  is $random->byte, "\34";
  is $random->byte, "l";
  is $random->byte, "\24";
  is $random->byte, "\xDB";
  is $random->byte, "\x7F";
  is $random->byte, "z";
  is $random->byte, "\xB0";
  is $random->byte, "\xD5";
  is $random->byte, "v";
  is $random->byte, "\x93";
  is $random->byte, "\x88";
  is $random->byte, "\6";
  is $random->byte, "\xC5";
  is $random->byte, "\x99";
  is $random->byte, "\xE8";
  is $random->byte, "}";
  is $random->byte, "\x89";
  is $random->byte, "\x7F";
  is $random->byte, "p";
  is $random->byte, "Y";
  is $random->byte, "\xEC";
  is $random->byte, "\17";
  is $random->byte, "\xDC";
  is $random->byte, "\xF8";
  is $random->byte, "\xD9";
  is $random->byte, "\@";
  is $random->byte, 4;
  is $random->byte, "\30";
  is $random->byte, "M";
  is $random->byte, "\xBA";
  is $random->byte, "\16";
  is $random->byte, "F";
  is $random->byte, "J";
  is $random->byte, "\x90";
  is $random->byte, "\xDA";
  is $random->byte, 7;
  is $random->byte, "\xCD";
  is $random->byte, "\xD1";
  is $random->byte, 6;
  is $random->byte, "\26";
  is $random->byte, "\x8E";
  is $random->byte, "\x86";
  is $random->byte, "\xDD";
  is $random->byte, "\xEE";
  is $random->byte, "#";
  is $random->byte, "\x8B";
  is $random->byte, "\x84";
  is $random->byte, "K";

  $result
});

=method bytes

The bytes method returns C<n> L</byte> characters based on the number (i.e.
count) provided.

=signature bytes

  bytes(number $count) (string)

=metadata bytes

{
  since => '4.15',
}

=example-1 bytes

  # given: synopsis

  package main;

  my $bytes = $random->bytes(5);

  # "\xBE\x57\x1C\x6C\x14"

  # $bytes = $random->bytes(5);

  # "\xDB\x7F\x7A\xB0\xD5"

=cut

$test->for('example', 1, 'bytes', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->bytes(5), "\xBE\x57\x1C\x6C\x14";
  is $random->bytes(5), "\xDB\x7F\x7A\xB0\xD5";
  is $random->bytes(5), "\x76\x93\x88\x06\xC5";
  is $random->bytes(5), "\x99\xE8\x7D\x89\x7F";
  is $random->bytes(5), "\x70\x59\xEC\x0F\xDC";
  is $random->bytes(5), "\xF8\xD9\x40\x34\x18";
  is $random->bytes(5), "\x4D\xBA\x0E\x46\x4A";
  is $random->bytes(5), "\x90\xDA\x37\xCD\xD1";
  is $random->bytes(5), "\x36\x16\x8E\x86\xDD";
  is $random->bytes(5), "\xEE\x23\x8B\x84\x4B";
  is $random->bytes(5), "\x4F\x75\x30\x22\x40";
  is $random->bytes(5), "\x89\x11\x81\xD0\xF1";
  is $random->bytes(5), "\xAF\x48\x42\x02\x9E";
  is $random->bytes(5), "\x67\x7D\x8A\x3B\xD6";
  is $random->bytes(5), "\x58\x9E\x25\x93\x27";
  is $random->bytes(5), "\x3F\xED\x36\xD1\xC6";
  is $random->bytes(5), "\x9D\xD2\x9E\x40\x9D";
  is $random->bytes(5), "\x1A\xF1\x20\x8B\x9D";
  is $random->bytes(5), "\xFC\x09\xBD\x98\x48";
  is $random->bytes(5), "\xD5\x9C\x17\x44\x95";
  is $random->bytes(5), "\x64\xE5\xED\x42\xA1";
  is $random->bytes(5), "\x37\xD8\xF4\xF3\x99";
  is $random->bytes(5), "\x81\xBD\x9C\x21\xF1";
  is $random->bytes(5), "\x35\x33\x6C\xB6\x0C";
  is $random->bytes(5), "\x97\x5E\x72\x50\x74";
  is $random->bytes(5), "\x06\x1F\x59\x15\xBC";
  is $random->bytes(5), "\x63\x64\x4A\x01\xF1";
  is $random->bytes(5), "\x72\xBB\xC0\xE7\x5F";
  is $random->bytes(5), "\x02\x8A\xEA\x55\xD2";
  is $random->bytes(5), "\x32\xCF\xFE\xE7\x0B";
  is $random->bytes(5), "\xB9\x2B\xD0\x27\x97";
  is $random->bytes(5), "\xB3\x9D\x3F\x09\x06";
  is $random->bytes(5), "\xE5\xF4\x66\x1E\xBD";
  is $random->bytes(5), "\x8D\xE7\xF7\xF5\xED";
  is $random->bytes(5), "\x9B\x4C\xCF\x15\x40";
  is $random->bytes(5), "\x4D\xFA\x74\x77\x34";
  is $random->bytes(5), "\x7A\xEA\x1C\x1C\xFE";
  is $random->bytes(5), "\xD3\xD2\x75\x7F\xFB";
  is $random->bytes(5), "\x90\x7F\x69\x98\x03";
  is $random->bytes(5), "\xB1\xA1\xF4\xA1\x55";
  is $random->bytes(5), "\x29\xB9\xEB\x86\x2B";
  is $random->bytes(5), "\xD7\xE7\xAE\xB8\x73";
  is $random->bytes(5), "\x98\x7D\x28\x69\x61";
  is $random->bytes(5), "\x81\xA5\x14\xEE\x01";
  is $random->bytes(5), "\xA6\xAA\xC2\xAA\x78";
  is $random->bytes(5), "\x25\xC7\xE5\xAE\x62";
  is $random->bytes(5), "\x7A\xBE\x55\x08\x2D";
  is $random->bytes(5), "\xB8\xB1\x7F\xE0\xAC";
  is $random->bytes(5), "\xAC\x1B\x93\xB8\x25";
  is $random->bytes(5), "\x73\x2F\xCF\xB4\x9B";

  $result
});

=method character

The character method returns a random character, which is either a L</digit>,
L</letter>, or L</symbol> value.

=signature character

  character() (string)

=metadata character

{
  since => '1.11',
}

=example-1 character

  # given: synopsis

  package main;

  my $character = $random->character;

  # ")"

  # $character = $random->character;

  # 4

=cut

$test->for('example', 1, 'character', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->character, ")";
  is $random->character, 4;
  is $random->character, 8;
  is $random->character, "R";
  is $random->character, "+";
  is $random->character, "a";
  is $random->character, "}";
  is $random->character, "[";
  is $random->character, "L";
  is $random->character, "b";
  is $random->character, "?";
  is $random->character, "&";
  is $random->character, 0;
  is $random->character, 7;
  is $random->character, 2;
  is $random->character, 5;
  is $random->character, "^";
  is $random->character, ",";
  is $random->character, 0;
  is $random->character, "w";
  is $random->character, "\$";
  is $random->character, "h";
  is $random->character, 4;
  is $random->character, 1;
  is $random->character, 5;
  is $random->character, 5;
  is $random->character, ">";
  is $random->character, "*";
  is $random->character, 0;
  is $random->character, "M";
  is $random->character, "V";
  is $random->character, "d";
  is $random->character, "G";
  is $random->character, "^";
  is $random->character, "'";
  is $random->character, "q";
  is $random->character, 6;
  is $random->character, 9;
  is $random->character, 5;
  is $random->character, "a";
  is $random->character, "}";
  is $random->character, 8;
  is $random->character, "G";
  is $random->character, "X";
  is $random->character, "*";
  is $random->character, "V";
  is $random->character, ">";
  is $random->character, "t";
  is $random->character, "Y";
  is $random->character, 2;

  $result
});

=method characters

The characters method returns C<n> L</character> characters based on the number
(i.e. count) provided.

=signature characters

  characters(number $count) (string)

=metadata characters

{
  since => '4.15',
}

=example-1 characters

  # given: synopsis

  package main;

  my $characters = $random->characters(5);

  # ")48R+"

  # $characters = $random->characters(5);

  # "a}[Lb"

=cut

$test->for('example', 1, 'characters', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->characters(5), ')48R+';
  is $random->characters(5), 'a}[Lb';
  is $random->characters(5), '?&072';
  is $random->characters(5), '5^,0w';
  is $random->characters(5), '$h415';
  is $random->characters(5), '5>*0M';
  is $random->characters(5), 'VdG^\'';
  is $random->characters(5), 'q695a';
  is $random->characters(5), '}8GX*';
  is $random->characters(5), 'V>tY2';
  is $random->characters(5), 'bL41T';
  is $random->characters(5), 'H9t-5';
  is $random->characters(5), ')^?!%';
  is $random->characters(5), '$p08_';
  is $random->characters(5), '7z<V2';
  is $random->characters(5), '9Fc9,';
  is $random->characters(5), 'ZKRqS';
  is $random->characters(5), ']8;=E';
  is $random->characters(5), 'NY6rU';
  is $random->characters(5), ';TE;r';
  is $random->characters(5), '#dV}c';
  is $random->characters(5), '+AiX-';
  is $random->characters(5), '74m8+';
  is $random->characters(5), '>8sA7';
  is $random->characters(5), '3A1YT';
  is $random->characters(5), '"P}8j';
  is $random->characters(5), '_5&w%';
  is $random->characters(5), '{rI?~';
  is $random->characters(5), '~[{U*';
  is $random->characters(5), 'i"2iD';
  is $random->characters(5), '4>A3l';
  is $random->characters(5), '8lZ78';
  is $random->characters(5), '#M\'LK';
  is $random->characters(5), 'u1%~@';
  is $random->characters(5), 'w58{6';
  is $random->characters(5), 'O_}0O';
  is $random->characters(5), '^8|5.';
  is $random->characters(5), 'K3<88';
  is $random->characters(5), 'h\Px3';
  is $random->characters(5), '4i1I*';
  is $random->characters(5), 'w4&75';
  is $random->characters(5), '61&%6';
  is $random->characters(5), '%78+8';
  is $random->characters(5), '2fIm=';
  is $random->characters(5), '-<$BO';
  is $random->characters(5), '=_9P7';
  is $random->characters(5), 'qhCAC';
  is $random->characters(5), 'M3L4J';
  is $random->characters(5), ']A133';
  is $random->characters(5), '!##l6';

  $result
});

=method collect

The collect method dispatches to the specified method or coderef, repeatedly
based on the number of C<$times> specified, and returns the random concatenated
results from each dispatched call. By default, if no arguments are provided,
this method dispatches to L</digit>.

=signature collect

  collect(number $times, string | coderef $code, any @args) (number | string)

=metadata collect

{
  since => '1.11',
}

=example-1 collect

  # given: synopsis

  package main;

  my $collect = $random->collect;

  # 7

  # $collect = $random->collect;

  # 3

=cut

$test->for('example', 1, 'collect', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->collect, 7;
  is $random->collect, 3;
  is $random->collect, 1;
  is $random->collect, 4;
  is $random->collect, 0;
  is $random->collect, 8;
  is $random->collect, 4;
  is $random->collect, 4;
  is $random->collect, 6;
  is $random->collect, 8;
  is $random->collect, 4;
  is $random->collect, 5;
  is $random->collect, 5;
  is $random->collect, 0;
  is $random->collect, 7;
  is $random->collect, 6;
  is $random->collect, 9;
  is $random->collect, 4;
  is $random->collect, 5;
  is $random->collect, 4;
  is $random->collect, 4;
  is $random->collect, 3;
  is $random->collect, 9;
  is $random->collect, 0;
  is $random->collect, 8;
  is $random->collect, 9;
  is $random->collect, 8;
  is $random->collect, 2;
  is $random->collect, 2;
  is $random->collect, 0;
  is $random->collect, 3;
  is $random->collect, 7;
  is $random->collect, 0;
  is $random->collect, 2;
  is $random->collect, 2;
  is $random->collect, 5;
  is $random->collect, 8;
  is $random->collect, 2;
  is $random->collect, 8;
  is $random->collect, 8;
  is $random->collect, 2;
  is $random->collect, 0;
  is $random->collect, 5;
  is $random->collect, 5;
  is $random->collect, 8;
  is $random->collect, 9;
  is $random->collect, 1;
  is $random->collect, 5;
  is $random->collect, 5;
  is $random->collect, 2;

  $result
});

=example-2 collect

  # given: synopsis

  package main;

  my $collect = $random->collect(2);

  # 73

  # $collect = $random->collect(2);

  # 14

=cut

$test->for('example', 2, 'collect', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->collect(2), 73;
  is $random->collect(2), 14;
  is $random->collect(2), "08";
  is $random->collect(2), 44;
  is $random->collect(2), 68;
  is $random->collect(2), 45;
  is $random->collect(2), 50;
  is $random->collect(2), 76;
  is $random->collect(2), 94;
  is $random->collect(2), 54;
  is $random->collect(2), 43;
  is $random->collect(2), 90;
  is $random->collect(2), 89;
  is $random->collect(2), 82;
  is $random->collect(2), 20;
  is $random->collect(2), 37;
  is $random->collect(2), "02";
  is $random->collect(2), 25;
  is $random->collect(2), 82;
  is $random->collect(2), 88;
  is $random->collect(2), 20;
  is $random->collect(2), 55;
  is $random->collect(2), 89;
  is $random->collect(2), 15;
  is $random->collect(2), 52;
  is $random->collect(2), 34;
  is $random->collect(2), 11;
  is $random->collect(2), 25;
  is $random->collect(2), "05";
  is $random->collect(2), 89;
  is $random->collect(2), 62;
  is $random->collect(2), 20;
  is $random->collect(2), 64;
  is $random->collect(2), 45;
  is $random->collect(2), 28;
  is $random->collect(2), 36;
  is $random->collect(2), 15;
  is $random->collect(2), 12;
  is $random->collect(2), 92;
  is $random->collect(2), 87;
  is $random->collect(2), 68;
  is $random->collect(2), 62;
  is $random->collect(2), 61;
  is $random->collect(2), 91;
  is $random->collect(2), 56;
  is $random->collect(2), 90;
  is $random->collect(2), 75;
  is $random->collect(2), 28;
  is $random->collect(2), 60;
  is $random->collect(2), 25;

  $result
});

=example-3 collect

  # given: synopsis

  package main;

  my $collect = $random->collect(5, "letter");

  # "iKWMv"

  # $collect = $random->collect(5, "letter");

  # "Papmm"


=cut

$test->for('example', 3, 'collect', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->collect(5, "letter"), "iKWMv";
  is $random->collect(5, "letter"), "Papmm";
  is $random->collect(5, "letter"), "JbzgC";
  is $random->collect(5, "letter"), "SHOfv";
  is $random->collect(5, "letter"), "CnyOh";
  is $random->collect(5, "letter"), "LDNNy";
  is $random->collect(5, "letter"), "hAkOV";
  is $random->collect(5, "letter"), "QPGfu";
  is $random->collect(5, "letter"), "vgcdp";
  is $random->collect(5, "letter"), "apVcP";
  is $random->collect(5, "letter"), "Xgfyp";
  is $random->collect(5, "letter"), "tdfLb";
  is $random->collect(5, "letter"), "jIAJT";
  is $random->collect(5, "letter"), "KAltj";
  is $random->collect(5, "letter"), "Oifzb";
  is $random->collect(5, "letter"), "eesgA";
  is $random->collect(5, "letter"), "yDozy";
  is $random->collect(5, "letter"), "hcHlF";
  is $random->collect(5, "letter"), "XCvlZ";
  is $random->collect(5, "letter"), "mPRyi";
  is $random->collect(5, "letter"), "SnVrl";
  is $random->collect(5, "letter"), "mKNca";
  is $random->collect(5, "letter"), "rrDxj";
  is $random->collect(5, "letter"), "TASmr";
  is $random->collect(5, "letter"), "csLVp";
  is $random->collect(5, "letter"), "yYMAt";
  is $random->collect(5, "letter"), "KXjSK";
  is $random->collect(5, "letter"), "NEsUg";
  is $random->collect(5, "letter"), "mslBf";
  is $random->collect(5, "letter"), "QAECp";
  is $random->collect(5, "letter"), "TuFxc";
  is $random->collect(5, "letter"), "jjkNg";
  is $random->collect(5, "letter"), "VtVqr";
  is $random->collect(5, "letter"), "mSsUT";
  is $random->collect(5, "letter"), "ZoUhz";
  is $random->collect(5, "letter"), "WbLiJ";
  is $random->collect(5, "letter"), "FUjAJ";
  is $random->collect(5, "letter"), "WAklk";
  is $random->collect(5, "letter"), "deyNM";
  is $random->collect(5, "letter"), "tLJKO";
  is $random->collect(5, "letter"), "aZUYM";
  is $random->collect(5, "letter"), "wNWoS";
  is $random->collect(5, "letter"), "lyUeQ";
  is $random->collect(5, "letter"), "OfUqO";
  is $random->collect(5, "letter"), "wJCWb";
  is $random->collect(5, "letter"), "dohqM";
  is $random->collect(5, "letter"), "mxJLp";
  is $random->collect(5, "letter"), "ANIhy";
  is $random->collect(5, "letter"), "cVGea";
  is $random->collect(5, "letter"), "gZTEt";

  $result
});

=example-4 collect

  # given: synopsis

  package main;

  my $collect = $random->collect(10, "character");

  # ")48R+a}[Lb"

  # $collect = $random->collect(10, "character");

  # "?&0725^,0w"

=cut

$test->for('example', 4, 'collect', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->collect(10, "character"), ")48R+a}[Lb";
  is $random->collect(10, "character"), "?&0725^,0w";
  is $random->collect(10, "character"), "\$h4155>*0M";
  is $random->collect(10, "character"), "VdG^'q695a";
  is $random->collect(10, "character"), "}8GX*V>tY2";
  is $random->collect(10, "character"), "bL41TH9t-5";
  is $random->collect(10, "character"), ")^?!%\$p08_";
  is $random->collect(10, "character"), "7z<V29Fc9,";
  is $random->collect(10, "character"), "ZKRqS]8;=E";
  is $random->collect(10, "character"), "NY6rU;TE;r";
  is $random->collect(10, "character"), "#dV}c+AiX-";
  is $random->collect(10, "character"), "74m8+>8sA7";
  is $random->collect(10, "character"), "3A1YT\"P}8j";
  is $random->collect(10, "character"), "_5&w%{rI?~";
  is $random->collect(10, "character"), "~[{U*i\"2iD";
  is $random->collect(10, "character"), "4>A3l8lZ78";
  is $random->collect(10, "character"), "#M'LKu1%~\@";
  is $random->collect(10, "character"), "w58{6O_}0O";
  is $random->collect(10, "character"), "^8|5.K3<88";
  is $random->collect(10, "character"), "h\\Px34i1I*";
  is $random->collect(10, "character"), "w4&7561&%6";
  is $random->collect(10, "character"), "%78+82fIm=";
  is $random->collect(10, "character"), "-<\$BO=_9P7";
  is $random->collect(10, "character"), "qhCACM3L4J";
  is $random->collect(10, "character"), "]A133!##l6";
  is $random->collect(10, "character"), "}B#89X4}\$(";
  is $random->collect(10, "character"), "4:]5*2r!89";
  is $random->collect(10, "character"), "3~fq3'181{";
  is $random->collect(10, "character"), "I4#21VU'6:";
  is $random->collect(10, "character"), "40J.;aY1.0";
  is $random->collect(10, "character"), "f!'6&34*Zm";
  is $random->collect(10, "character"), "xj6/8j1|./";
  is $random->collect(10, "character"), "61gT57414E";
  is $random->collect(10, "character"), "p867-k&c,2";
  is $random->collect(10, "character"), ">\@.zjW:u+m";
  is $random->collect(10, "character"), "7E08;A2894";
  is $random->collect(10, "character"), "F03/{/7%kR";
  is $random->collect(10, "character"), "{[91lI+(Ot";
  is $random->collect(10, "character"), "5~q82PB6v3";
  is $random->collect(10, "character"), "5(\@,]\$\\D(6";
  is $random->collect(10, "character"), "mn3d20NCyk";
  is $random->collect(10, "character"), "&X}R629c3H";
  is $random->collect(10, "character"), "~\@3(AS>\",o";
  is $random->collect(10, "character"), "L4~A361x+6";
  is $random->collect(10, "character"), "zU59U2|f9?";
  is $random->collect(10, "character"), "\$766uU^H1x";
  is $random->collect(10, "character"), "|M5O6-2847";
  is $random->collect(10, "character"), "zN}3yK7~N/";
  is $random->collect(10, "character"), "U8400/50rU";
  is $random->collect(10, "character"), "323?n46&0-";

  $result
});

=method digest

The digest method returns a unique randomly generated L<"md5"|Digest::MD5>
digest.

=signature digest

  digest() (string)

=metadata digest

{
  since => '4.15',
}

=cut

=example-1 digest

  # given: synopsis

  package main;

  my $digest = $random->digest;

  # "86eb5865c3e4a1457fbefcc93e037459"

  # $digest = $random->digest;

  # "9be02d56ece7efe68bc59d2ebf3c4ed7"

=cut

$test->for('example', 1, 'digest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok length($result) > 30;
  like $result, qr/^\w+$/;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;
  isnt +($last = $random->digest), $random->digest;

  $result
});

=method digit

The digit method returns a random digit between C<0> and C<9>.

=signature digit

  digit() (number)

=metadata digit

{
  since => '1.11',
}

=example-1 digit

  # given: synopsis

  package main;

  my $digit = $random->digit;

  # 7

  # $digit = $random->digit;

  # 3

=cut

$test->for('example', 1, 'digit', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->digit, 7;
  is $random->digit, 3;
  is $random->digit, 1;
  is $random->digit, 4;
  is $random->digit, 0;
  is $random->digit, 8;
  is $random->digit, 4;
  is $random->digit, 4;
  is $random->digit, 6;
  is $random->digit, 8;
  is $random->digit, 4;
  is $random->digit, 5;
  is $random->digit, 5;
  is $random->digit, 0;
  is $random->digit, 7;
  is $random->digit, 6;
  is $random->digit, 9;
  is $random->digit, 4;
  is $random->digit, 5;
  is $random->digit, 4;
  is $random->digit, 4;
  is $random->digit, 3;
  is $random->digit, 9;
  is $random->digit, 0;
  is $random->digit, 8;
  is $random->digit, 9;
  is $random->digit, 8;
  is $random->digit, 2;
  is $random->digit, 2;
  is $random->digit, 0;
  is $random->digit, 3;
  is $random->digit, 7;
  is $random->digit, 0;
  is $random->digit, 2;
  is $random->digit, 2;
  is $random->digit, 5;
  is $random->digit, 8;
  is $random->digit, 2;
  is $random->digit, 8;
  is $random->digit, 8;
  is $random->digit, 2;
  is $random->digit, 0;
  is $random->digit, 5;
  is $random->digit, 5;
  is $random->digit, 8;
  is $random->digit, 9;
  is $random->digit, 1;
  is $random->digit, 5;
  is $random->digit, 5;
  is $random->digit, 2;

  $result
});

=method digits

The digits method returns C<n> L</digit> characters based on the number (i.e.
count) provided.

=signature digits

  digits(number $count) (string)

=metadata digits

{
  since => '4.15',
}

=example-1 digits

  # given: synopsis

  package main;

  my $digits = $random->digits(5);

  # 73140

  # $digits = $random->digits(5);

  # 84468

=cut

$test->for('example', 1, 'digits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->digits(5), '73140';
  is $random->digits(5), '84468';
  is $random->digits(5), '45507';
  is $random->digits(5), '69454';
  is $random->digits(5), '43908';
  is $random->digits(5), '98220';
  is $random->digits(5), '37022';
  is $random->digits(5), '58288';
  is $random->digits(5), '20558';
  is $random->digits(5), '91552';
  is $random->digits(5), '34112';
  is $random->digits(5), '50589';
  is $random->digits(5), '62206';
  is $random->digits(5), '44528';
  is $random->digits(5), '36151';
  is $random->digits(5), '29287';
  is $random->digits(5), '68626';
  is $random->digits(5), '19156';
  is $random->digits(5), '90752';
  is $random->digits(5), '86025';
  is $random->digits(5), '38926';
  is $random->digits(5), '28996';
  is $random->digits(5), '57619';
  is $random->digits(5), '22470';
  is $random->digits(5), '53434';
  is $random->digits(5), '01307';
  is $random->digits(5), '33209';
  is $random->digits(5), '47793';
  is $random->digits(5), '05938';
  is $random->digits(5), '18990';
  is $random->digits(5), '71815';
  is $random->digits(5), '76200';
  is $random->digits(5), '89317';
  is $random->digits(5), '59999';
  is $random->digits(5), '62802';
  is $random->digits(5), '39442';
  is $random->digits(5), '49119';
  is $random->digits(5), '88449';
  is $random->digits(5), '54450';
  is $random->digits(5), '66963';
  is $random->digits(5), '17951';
  is $random->digits(5), '89674';
  is $random->digits(5), '54143';
  is $random->digits(5), '56090';
  is $random->digits(5), '66764';
  is $random->digits(5), '17863';
  is $random->digits(5), '47301';
  is $random->digits(5), '76486';
  is $random->digits(5), '61571';
  is $random->digits(5), '41876';

  $result
});

=method float

The float method returns a random float.

=signature float

  float(number $place, number $from, number $upto) (number)

=metadata float

{
  since => '1.11',
}

=example-1 float

  # given: synopsis

  package main;

  my $float = $random->float;

  # 1447361.5

  # $float = $random->float;

  # "0.0000"

=cut

$test->for('example', 1, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->float), trunc("1447361.5");
  is trunc($random->float), trunc("0.0000");
  is trunc($random->float), trunc("482092.1040");
  is trunc($random->float), trunc("1555.7410393");
  is trunc($random->float), trunc("243073010.62968");
  is trunc($random->float), trunc("211.129029505");
  is trunc($random->float), trunc("24482222.86154329");
  is trunc($random->float), trunc("6.556");
  is trunc($random->float), trunc("0.00");
  is trunc($random->float), trunc("17652140.46803842");
  is trunc($random->float), trunc("4.19828");
  is trunc($random->float), trunc("50807265.7");
  is trunc($random->float), trunc("13521.258");
  is trunc($random->float), trunc("0.54");
  is trunc($random->float), trunc("0.00000000");
  is trunc($random->float), trunc("2996.60");
  is trunc($random->float), trunc("219329.0876");
  is trunc($random->float), trunc("51.256");
  is trunc($random->float), trunc("1.2");
  is trunc($random->float), trunc("165823309.60632405");
  is trunc($random->float), trunc("207785.414616");
  is trunc($random->float), trunc("12976.090746608");
  is trunc($random->float), trunc("2184.285870579");
  is trunc($random->float), trunc("4962126.07");
  is trunc($random->float), trunc("52996.93");
  is trunc($random->float), trunc("233.659434202");
  is trunc($random->float), trunc("208182.10328548");
  is trunc($random->float), trunc("446099950.92124");
  is trunc($random->float), trunc("27197.291840737");
  is trunc($random->float), trunc("2.1292108");
  is trunc($random->float), trunc("11504.2135");
  is trunc($random->float), trunc("86.1");
  is trunc($random->float), trunc("0.000");
  is trunc($random->float), trunc("0.000000000");
  is trunc($random->float), trunc("2814337.555595279");
  is trunc($random->float), trunc("0.000000000");
  is trunc($random->float), trunc("19592108.75910050");
  is trunc($random->float), trunc("7955940.0889820");
  is trunc($random->float), trunc("10842452.67346");
  is trunc($random->float), trunc("236808.75850632");
  is trunc($random->float), trunc("65.1309632");
  is trunc($random->float), trunc("898218603.151974320");
  is trunc($random->float), trunc("25368.54295825");
  is trunc($random->float), trunc("13.232559545");
  is trunc($random->float), trunc("1884.0766");
  is trunc($random->float), trunc("0.824919221");
  is trunc($random->float), trunc("45112657.8201");
  is trunc($random->float), trunc("29867.7308");
  is trunc($random->float), trunc("0.000000");
  is trunc($random->float), trunc("242355.0");

  $result
});

=example-2 float

  # given: synopsis

  package main;

  my $float = $random->float(2);

  # 380690.82

  # $float = $random->float(2);

  # 694.57

=cut

$test->for('example', 2, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->float(2)), trunc("380690.82");
  is trunc($random->float(2)), trunc("694.57");
  is trunc($random->float(2)), trunc("3306.92");
  is trunc($random->float(2)), trunc("26738855.41");
  is trunc($random->float(2)), trunc("1992.27");
  is trunc($random->float(2)), trunc("444768.09");
  is trunc($random->float(2)), trunc("21736.58");
  is trunc($random->float(2)), trunc("55.62");
  is trunc($random->float(2)), trunc("82512590.60");
  is trunc($random->float(2)), trunc("1.94");
  is trunc($random->float(2)), trunc("40.27");
  is trunc($random->float(2)), trunc("15.84");
  is trunc($random->float(2)), trunc("17325459.15");
  is trunc($random->float(2)), trunc("1896115.91");
  is trunc($random->float(2)), trunc("45346.49");
  is trunc($random->float(2)), trunc("75658691.16");
  is trunc($random->float(2)), trunc("9128.13");
  is trunc($random->float(2)), trunc("259.37");
  is trunc($random->float(2)), trunc("3.71");
  is trunc($random->float(2)), trunc("76656.85");
  is trunc($random->float(2)), trunc("74168.40");
  is trunc($random->float(2)), trunc("0.00");
  is trunc($random->float(2)), trunc("1249.76");
  is trunc($random->float(2)), trunc("21344208.40");
  is trunc($random->float(2)), trunc("0.77");
  is trunc($random->float(2)), trunc("19.51");
  is trunc($random->float(2)), trunc("47493144.38");
  is trunc($random->float(2)), trunc("15672283.68");
  is trunc($random->float(2)), trunc("96970.04");
  is trunc($random->float(2)), trunc("2.46");
  is trunc($random->float(2)), trunc("26264064.08");
  is trunc($random->float(2)), trunc("23515.13");
  is trunc($random->float(2)), trunc("24106.51");
  is trunc($random->float(2)), trunc("35366.70");
  is trunc($random->float(2)), trunc("164118589.68");
  is trunc($random->float(2)), trunc("79.12");
  is trunc($random->float(2)), trunc("303408540.24");
  is trunc($random->float(2)), trunc("794078.78");
  is trunc($random->float(2)), trunc("42119354.52");
  is trunc($random->float(2)), trunc("362.02");
  is trunc($random->float(2)), trunc("16504.73");
  is trunc($random->float(2)), trunc("11.17");
  is trunc($random->float(2)), trunc("0.26");
  is trunc($random->float(2)), trunc("1516813.10");
  is trunc($random->float(2)), trunc("0.00");
  is trunc($random->float(2)), trunc("5503.21");
  is trunc($random->float(2)), trunc("3210731.64");
  is trunc($random->float(2)), trunc("30470.18");
  is trunc($random->float(2)), trunc("15951197.43");
  is trunc($random->float(2)), trunc("42222726.33");

  $result
});

=example-3 float

  # given: synopsis

  package main;

  my $float = $random->float(2, 1, 5);

  # 3.98

  # $float = $random->float(2, 1, 5);

  # 2.37

=cut

$test->for('example', 3, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->float(2, 1, 5), 3.98;
  is $random->float(2, 1, 5), 2.37;
  is $random->float(2, 1, 5), 1.44;
  is $random->float(2, 1, 5), 2.69;
  is $random->float(2, 1, 5), 1.32;
  is $random->float(2, 1, 5), 4.43;
  is $random->float(2, 1, 5), "3.00";
  is $random->float(2, 1, 5), 2.92;
  is $random->float(2, 1, 5), 3.76;
  is $random->float(2, 1, 5), 4.34;
  is $random->float(2, 1, 5), 2.85;
  is $random->float(2, 1, 5), 3.31;
  is $random->float(2, 1, 5), 3.14;
  is $random->float(2, 1, 5), "1.10";
  is $random->float(2, 1, 5), 4.08;
  is $random->float(2, 1, 5), "3.40";
  is $random->float(2, 1, 5), 4.64;
  is $random->float(2, 1, 5), 2.96;
  is $random->float(2, 1, 5), 3.14;
  is $random->float(2, 1, 5), 2.99;
  is $random->float(2, 1, 5), 2.75;
  is $random->float(2, 1, 5), "2.40";
  is $random->float(2, 1, 5), 4.69;
  is $random->float(2, 1, 5), 1.24;
  is $random->float(2, 1, 5), 4.44;
  is $random->float(2, 1, 5), 4.89;
  is $random->float(2, 1, 5), "4.40";
  is $random->float(2, 1, 5), 2.01;
  is $random->float(2, 1, 5), 1.82;
  is $random->float(2, 1, 5), 1.39;
  is $random->float(2, 1, 5), 2.21;
  is $random->float(2, 1, 5), 3.91;
  is $random->float(2, 1, 5), 1.22;
  is $random->float(2, 1, 5), "2.10";
  is $random->float(2, 1, 5), 2.16;
  is $random->float(2, 1, 5), 3.26;
  is $random->float(2, 1, 5), 4.42;
  is $random->float(2, 1, 5), 1.86;
  is $random->float(2, 1, 5), 4.21;
  is $random->float(2, 1, 5), 4.27;
  is $random->float(2, 1, 5), 1.85;
  is $random->float(2, 1, 5), 1.35;
  is $random->float(2, 1, 5), 3.23;
  is $random->float(2, 1, 5), "3.10";
  is $random->float(2, 1, 5), 4.46;
  is $random->float(2, 1, 5), 4.73;
  is $random->float(2, 1, 5), 1.56;
  is $random->float(2, 1, 5), 3.18;
  is $random->float(2, 1, 5), 3.08;
  is $random->float(2, 1, 5), 2.17;

  $result
});

=example-4 float

  # given: synopsis

  package main;

  my $float = $random->float(3, 1, 2);

  # 1.745

  # $float = $random->float(3, 1, 2);

  # 1.343

=cut

$test->for('example', 4, 'float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->float(3, 1, 2), 1.745;
  is $random->float(3, 1, 2), 1.343;
  is $random->float(3, 1, 2), 1.111;
  is $random->float(3, 1, 2), 1.422;
  is $random->float(3, 1, 2), 1.081;
  is $random->float(3, 1, 2), 1.856;
  is $random->float(3, 1, 2), 1.499;
  is $random->float(3, 1, 2), 1.479;
  is $random->float(3, 1, 2), 1.691;
  is $random->float(3, 1, 2), 1.835;
  is $random->float(3, 1, 2), 1.463;
  is $random->float(3, 1, 2), 1.578;
  is $random->float(3, 1, 2), 1.534;
  is $random->float(3, 1, 2), 1.026;
  is $random->float(3, 1, 2), "1.770";
  is $random->float(3, 1, 2), 1.601;
  is $random->float(3, 1, 2), 1.909;
  is $random->float(3, 1, 2), 1.489;
  is $random->float(3, 1, 2), 1.536;
  is $random->float(3, 1, 2), 1.497;
  is $random->float(3, 1, 2), 1.438;
  is $random->float(3, 1, 2), "1.350";
  is $random->float(3, 1, 2), 1.922;
  is $random->float(3, 1, 2), "1.060";
  is $random->float(3, 1, 2), "1.860";
  is $random->float(3, 1, 2), 1.972;
  is $random->float(3, 1, 2), 1.849;
  is $random->float(3, 1, 2), 1.252;
  is $random->float(3, 1, 2), 1.206;
  is $random->float(3, 1, 2), 1.097;
  is $random->float(3, 1, 2), 1.302;
  is $random->float(3, 1, 2), 1.728;
  is $random->float(3, 1, 2), 1.055;
  is $random->float(3, 1, 2), 1.274;
  is $random->float(3, 1, 2), "1.290";
  is $random->float(3, 1, 2), 1.566;
  is $random->float(3, 1, 2), 1.855;
  is $random->float(3, 1, 2), 1.216;
  is $random->float(3, 1, 2), 1.802;
  is $random->float(3, 1, 2), 1.817;
  is $random->float(3, 1, 2), 1.214;
  is $random->float(3, 1, 2), 1.089;
  is $random->float(3, 1, 2), 1.557;
  is $random->float(3, 1, 2), 1.525;
  is $random->float(3, 1, 2), 1.864;
  is $random->float(3, 1, 2), 1.933;
  is $random->float(3, 1, 2), 1.139;
  is $random->float(3, 1, 2), 1.544;
  is $random->float(3, 1, 2), 1.519;
  is $random->float(3, 1, 2), 1.293;

  $result
});

=method hexdecimal

The hexdecimal method returns a hexdecimal character.

=signature hexdecimal

  hexdecimal() (string)

=metadata hexdecimal

{
  since => '4.15',
}

=cut

=example-1 hexdecimal

  # given: synopsis

  package main;

  my $hexdecimal = $random->hexdecimal;

  # "b"

  # $hexdecimal = $random->hexdecimal;

  # 5

=cut

$test->for('example', 1, 'hexdecimal', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->hexdecimal, 'b';
  is $random->hexdecimal, '5';
  is $random->hexdecimal, '1';
  is $random->hexdecimal, '6';
  is $random->hexdecimal, '1';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, '7';
  is $random->hexdecimal, '7';
  is $random->hexdecimal, 'b';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, '7';
  is $random->hexdecimal, '9';
  is $random->hexdecimal, '8';
  is $random->hexdecimal, '0';
  is $random->hexdecimal, 'c';
  is $random->hexdecimal, '9';
  is $random->hexdecimal, 'e';
  is $random->hexdecimal, '7';
  is $random->hexdecimal, '8';
  is $random->hexdecimal, '7';
  is $random->hexdecimal, '7';
  is $random->hexdecimal, '5';
  is $random->hexdecimal, 'e';
  is $random->hexdecimal, '0';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, 'f';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, '4';
  is $random->hexdecimal, '3';
  is $random->hexdecimal, '1';
  is $random->hexdecimal, '4';
  is $random->hexdecimal, 'b';
  is $random->hexdecimal, '0';
  is $random->hexdecimal, '4';
  is $random->hexdecimal, '4';
  is $random->hexdecimal, '9';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, '3';
  is $random->hexdecimal, 'c';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, '3';
  is $random->hexdecimal, '1';
  is $random->hexdecimal, '8';
  is $random->hexdecimal, '8';
  is $random->hexdecimal, 'd';
  is $random->hexdecimal, 'e';
  is $random->hexdecimal, '2';
  is $random->hexdecimal, '8';
  is $random->hexdecimal, '8';
  is $random->hexdecimal, '4';

  $result
});

=method hexdecimals

The hexdecimals method returns C<n> L</hexdecimal> characters based on the
number (i.e. count) provided.

=signature hexdecimals

  hexdecimals(number $count) (string)

=metadata hexdecimals

{
  since => '4.15',
}

=example-1 hexdecimals

  # given: synopsis

  package main;

  my $hexdecimals = $random->hexdecimals(5);

  # "b5161"

  # $hexdecimals = $random->hexdecimals(5);

  # "d77bd"

=cut

$test->for('example', 1, 'hexdecimals', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->hexdecimals(5), 'b5161';
  is $random->hexdecimals(5), 'd77bd';
  is $random->hexdecimals(5), '7980c';
  is $random->hexdecimals(5), '9e787';
  is $random->hexdecimals(5), '75e0d';
  is $random->hexdecimals(5), 'fd431';
  is $random->hexdecimals(5), '4b044';
  is $random->hexdecimals(5), '9d3cd';
  is $random->hexdecimals(5), '3188d';
  is $random->hexdecimals(5), 'e2884';
  is $random->hexdecimals(5), '47324';
  is $random->hexdecimals(5), '818df';
  is $random->hexdecimals(5), 'a4409';
  is $random->hexdecimals(5), '6783d';
  is $random->hexdecimals(5), '59292';
  is $random->hexdecimals(5), '3e3dc';
  is $random->hexdecimals(5), '9d949';
  is $random->hexdecimals(5), '1f289';
  is $random->hexdecimals(5), 'f0b94';
  is $random->hexdecimals(5), 'd9149';
  is $random->hexdecimals(5), '6ee4a';
  is $random->hexdecimals(5), '3dff9';
  is $random->hexdecimals(5), '8b92f';
  is $random->hexdecimals(5), '336b0';
  is $random->hexdecimals(5), '95757';
  is $random->hexdecimals(5), '0151b';
  is $random->hexdecimals(5), '6640f';
  is $random->hexdecimals(5), '7bce5';
  is $random->hexdecimals(5), '08e5d';
  is $random->hexdecimals(5), '3cfe0';
  is $random->hexdecimals(5), 'b2d29';
  is $random->hexdecimals(5), 'b9300';
  is $random->hexdecimals(5), 'ef61b';
  is $random->hexdecimals(5), '8effe';
  is $random->hexdecimals(5), '94c14';
  is $random->hexdecimals(5), '4f773';
  is $random->hexdecimals(5), '7e11f';
  is $random->hexdecimals(5), 'dd77f';
  is $random->hexdecimals(5), '97690';
  is $random->hexdecimals(5), 'bafa5';
  is $random->hexdecimals(5), '2be82';
  is $random->hexdecimals(5), 'deab7';
  is $random->hexdecimals(5), '97266';
  is $random->hexdecimals(5), '8a1e0';
  is $random->hexdecimals(5), 'aaca7';
  is $random->hexdecimals(5), '2cea6';
  is $random->hexdecimals(5), '7b502';
  is $random->hexdecimals(5), 'bb7ea';
  is $random->hexdecimals(5), 'a19b2';
  is $random->hexdecimals(5), '72cb9';

  $result
});

=method id

The id method returns a machine unique thread-safe random numerical identifier.

=signature id

  id() (number)

=metadata id

{
  since => '4.15',
}

=cut

=example-1 id

  # given: synopsis

  package main;

  my $id = $random->id;

  # 1729257495154941

=cut

$test->for('example', 1, 'id', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok length($result) > 10;
  like $result, qr/^\d+$/;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;
  isnt +($last = $random->id), $random->id;

  $result
});

=method letter

The letter method returns a random letter, which is either an L</uppercased> or
L</lowercased> value.

=signature letter

  letter() (string)

=metadata letter

{
  since => '1.11',
}

=example-1 letter

  # given: synopsis

  package main;

  my $letter = $random->letter;

  # "i"

  # $letter = $random->letter;

  # "K"

=cut

$test->for('example', 1, 'letter', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->letter, "i";
  is $random->letter, "K";
  is $random->letter, "W";
  is $random->letter, "M";
  is $random->letter, "v";
  is $random->letter, "P";
  is $random->letter, "a";
  is $random->letter, "p";
  is $random->letter, "m";
  is $random->letter, "m";
  is $random->letter, "J";
  is $random->letter, "b";
  is $random->letter, "z";
  is $random->letter, "g";
  is $random->letter, "C";
  is $random->letter, "S";
  is $random->letter, "H";
  is $random->letter, "O";
  is $random->letter, "f";
  is $random->letter, "v";
  is $random->letter, "C";
  is $random->letter, "n";
  is $random->letter, "y";
  is $random->letter, "O";
  is $random->letter, "h";
  is $random->letter, "L";
  is $random->letter, "D";
  is $random->letter, "N";
  is $random->letter, "N";
  is $random->letter, "y";
  is $random->letter, "h";
  is $random->letter, "A";
  is $random->letter, "k";
  is $random->letter, "O";
  is $random->letter, "V";
  is $random->letter, "Q";
  is $random->letter, "P";
  is $random->letter, "G";
  is $random->letter, "f";
  is $random->letter, "u";
  is $random->letter, "v";
  is $random->letter, "g";
  is $random->letter, "c";
  is $random->letter, "d";
  is $random->letter, "p";
  is $random->letter, "a";
  is $random->letter, "p";
  is $random->letter, "V";
  is $random->letter, "c";
  is $random->letter, "P";

  $result
});

=method letters

The letters method returns C<n> L</letter> characters based on the number (i.e.
count) provided.

=signature letters

  letters(number $count) (string)

=metadata letters

{
  since => '4.15',
}

=example-1 letters

  # given: synopsis

  package main;

  my $letters = $random->letters(5);

  # "iKWMv"

  # $letters = $random->letters(5);

  # "Papmm"

=cut

$test->for('example', 1, 'letters', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->letters(5), 'iKWMv';
  is $random->letters(5), 'Papmm';
  is $random->letters(5), 'JbzgC';
  is $random->letters(5), 'SHOfv';
  is $random->letters(5), 'CnyOh';
  is $random->letters(5), 'LDNNy';
  is $random->letters(5), 'hAkOV';
  is $random->letters(5), 'QPGfu';
  is $random->letters(5), 'vgcdp';
  is $random->letters(5), 'apVcP';
  is $random->letters(5), 'Xgfyp';
  is $random->letters(5), 'tdfLb';
  is $random->letters(5), 'jIAJT';
  is $random->letters(5), 'KAltj';
  is $random->letters(5), 'Oifzb';
  is $random->letters(5), 'eesgA';
  is $random->letters(5), 'yDozy';
  is $random->letters(5), 'hcHlF';
  is $random->letters(5), 'XCvlZ';
  is $random->letters(5), 'mPRyi';
  is $random->letters(5), 'SnVrl';
  is $random->letters(5), 'mKNca';
  is $random->letters(5), 'rrDxj';
  is $random->letters(5), 'TASmr';
  is $random->letters(5), 'csLVp';
  is $random->letters(5), 'yYMAt';
  is $random->letters(5), 'KXjSK';
  is $random->letters(5), 'NEsUg';
  is $random->letters(5), 'mslBf';
  is $random->letters(5), 'QAECp';
  is $random->letters(5), 'TuFxc';
  is $random->letters(5), 'jjkNg';
  is $random->letters(5), 'VtVqr';
  is $random->letters(5), 'mSsUT';
  is $random->letters(5), 'ZoUhz';
  is $random->letters(5), 'WbLiJ';
  is $random->letters(5), 'FUjAJ';
  is $random->letters(5), 'WAklk';
  is $random->letters(5), 'deyNM';
  is $random->letters(5), 'tLJKO';
  is $random->letters(5), 'aZUYM';
  is $random->letters(5), 'wNWoS';
  is $random->letters(5), 'lyUeQ';
  is $random->letters(5), 'OfUqO';
  is $random->letters(5), 'wJCWb';
  is $random->letters(5), 'dohqM';
  is $random->letters(5), 'mxJLp';
  is $random->letters(5), 'ANIhy';
  is $random->letters(5), 'cVGea';
  is $random->letters(5), 'gZTEt';

  $result
});

=method lowercased

The lowercased method returns a random lowercased letter.

=signature lowercased

  lowercased() (string)

=metadata lowercased

{
  since => '1.11',
}

=example-1 lowercased

  # given: synopsis

  package main;

  my $lowercased = $random->lowercased;

  # "t"

  # $lowercased = $random->lowercased;

  # "i"

=cut

$test->for('example', 1, 'lowercased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->lowercased, "t";
  is $random->lowercased, "i";
  is $random->lowercased, "c";
  is $random->lowercased, "k";
  is $random->lowercased, "c";
  is $random->lowercased, "w";
  is $random->lowercased, "m";
  is $random->lowercased, "m";
  is $random->lowercased, "r";
  is $random->lowercased, "v";
  is $random->lowercased, "m";
  is $random->lowercased, "p";
  is $random->lowercased, "n";
  is $random->lowercased, "a";
  is $random->lowercased, "u";
  is $random->lowercased, "p";
  is $random->lowercased, "x";
  is $random->lowercased, "m";
  is $random->lowercased, "n";
  is $random->lowercased, "m";
  is $random->lowercased, "l";
  is $random->lowercased, "j";
  is $random->lowercased, "x";
  is $random->lowercased, "b";
  is $random->lowercased, "w";
  is $random->lowercased, "z";
  is $random->lowercased, "w";
  is $random->lowercased, "g";
  is $random->lowercased, "f";
  is $random->lowercased, "c";
  is $random->lowercased, "h";
  is $random->lowercased, "s";
  is $random->lowercased, "b";
  is $random->lowercased, "h";
  is $random->lowercased, "h";
  is $random->lowercased, "o";
  is $random->lowercased, "w";
  is $random->lowercased, "f";
  is $random->lowercased, "u";
  is $random->lowercased, "v";
  is $random->lowercased, "f";
  is $random->lowercased, "c";
  is $random->lowercased, "o";
  is $random->lowercased, "n";
  is $random->lowercased, "w";
  is $random->lowercased, "y";
  is $random->lowercased, "d";
  is $random->lowercased, "o";
  is $random->lowercased, "n";
  is $random->lowercased, "h";

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Random)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Random;

  my $new = Venus::Random->new;

  # bless(..., "Venus::Random")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Random');

  $result
});

=example-2 new

  package main;

  use Venus::Random;

  my $new = Venus::Random->new(42);

  # bless(..., "Venus::Random")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Random');
  is $result->value, 42;

  $result
});

=example-3 new

  package main;

  use Venus::Random;

  my $new = Venus::Random->new(value => 42);

  # bless(..., "Venus::Random")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Random');
  is $result->value, 42;

  $result
});

=method nonce

The nonce method returns a 10-character L</alphanumeric> string.

=signature nonce

  nonce() (string)

=metadata nonce

{
  since => '4.15',
}

=cut

=example-1 nonce

  # given: synopsis

  package main;

  my $nonce = $random->nonce;

  # "j2q1G45903"

  # $nonce = $random->nonce;

  # "7nmi8mT5Io"

=cut

$test->for('example', 1, 'nonce', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok length($result) == 10;
  like $result, qr/^\w+$/;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->nonce), $random->nonce;

  $result
});

=method nonzero

The nonzero method dispatches to the specified method or coderef and returns
the random value ensuring that it's never zero, not even a percentage of zero.
By default, if no arguments are provided, this method dispatches to L</digit>.

=signature nonzero

  nonzero(string | coderef $code, any @args) (number | string)

=metadata nonzero

{
  since => '1.11',
}

=example-1 nonzero

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero;

  # 7

  # $nonzero = $random->nonzero;

  # 3

=cut

$test->for('example', 1, 'nonzero', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->nonzero, 7;
  is $random->nonzero, 3;
  is $random->nonzero, 1;
  is $random->nonzero, 4;
  is $random->nonzero, 8;
  is $random->nonzero, 4;
  is $random->nonzero, 4;
  is $random->nonzero, 6;
  is $random->nonzero, 8;
  is $random->nonzero, 4;
  is $random->nonzero, 5;
  is $random->nonzero, 5;
  is $random->nonzero, 7;
  is $random->nonzero, 6;
  is $random->nonzero, 9;
  is $random->nonzero, 4;
  is $random->nonzero, 5;
  is $random->nonzero, 4;
  is $random->nonzero, 4;
  is $random->nonzero, 3;
  is $random->nonzero, 9;
  is $random->nonzero, 8;
  is $random->nonzero, 9;
  is $random->nonzero, 8;
  is $random->nonzero, 2;
  is $random->nonzero, 2;
  is $random->nonzero, 3;
  is $random->nonzero, 7;
  is $random->nonzero, 2;
  is $random->nonzero, 2;
  is $random->nonzero, 5;
  is $random->nonzero, 8;
  is $random->nonzero, 2;
  is $random->nonzero, 8;
  is $random->nonzero, 8;
  is $random->nonzero, 2;
  is $random->nonzero, 5;
  is $random->nonzero, 5;
  is $random->nonzero, 8;
  is $random->nonzero, 9;
  is $random->nonzero, 1;
  is $random->nonzero, 5;
  is $random->nonzero, 5;
  is $random->nonzero, 2;
  is $random->nonzero, 3;
  is $random->nonzero, 4;
  is $random->nonzero, 1;
  is $random->nonzero, 1;
  is $random->nonzero, 2;
  is $random->nonzero, 5;

  $result
});

=example-2 nonzero

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero("pick");

  # 1.74452500006101

  # $nonzero = $random->nonzero("pick");

  # 1.34270147871891

=cut

$test->for('example', 2, 'nonzero', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->nonzero("pick")), trunc("1.74452500006101");
  is trunc($random->nonzero("pick")), trunc("1.34270147871891");
  is trunc($random->nonzero("pick")), trunc("1.11108528244416");
  is trunc($random->nonzero("pick")), trunc("1.42233895798831");
  is trunc($random->nonzero("pick")), trunc("1.08111117117831");
  is trunc($random->nonzero("pick")), trunc("1.85644070802662");
  is trunc($random->nonzero("pick")), trunc("1.49879942219408");
  is trunc($random->nonzero("pick")), trunc("1.47881429064463");
  is trunc($random->nonzero("pick")), trunc("1.69081244430564");
  is trunc($random->nonzero("pick")), trunc("1.83459376596215");
  is trunc($random->nonzero("pick")), trunc("1.46289983439946");
  is trunc($random->nonzero("pick")), trunc("1.5776380603106");
  is trunc($random->nonzero("pick")), trunc("1.53397276092527");
  is trunc($random->nonzero("pick")), trunc("1.02588992248072");
  is trunc($random->nonzero("pick")), trunc("1.76981204150115");
  is trunc($random->nonzero("pick")), trunc("1.60113641395593");
  is trunc($random->nonzero("pick")), trunc("1.90883275351445");
  is trunc($random->nonzero("pick")), trunc("1.48938481428107");
  is trunc($random->nonzero("pick")), trunc("1.53598974721394");
  is trunc($random->nonzero("pick")), trunc("1.49669095601804");
  is trunc($random->nonzero("pick")), trunc("1.43763751683027");
  is trunc($random->nonzero("pick")), trunc("1.34967725286383");
  is trunc($random->nonzero("pick")), trunc("1.92192218572714");
  is trunc($random->nonzero("pick")), trunc("1.06039159882871");
  is trunc($random->nonzero("pick")), trunc("1.85989410236673");
  is trunc($random->nonzero("pick")), trunc("1.97198998677624");
  is trunc($random->nonzero("pick")), trunc("1.84890372478558");
  is trunc($random->nonzero("pick")), trunc("1.25187731990221");
  is trunc($random->nonzero("pick")), trunc("1.20578560434642");
  is trunc($random->nonzero("pick")), trunc("1.09677224923537");
  is trunc($random->nonzero("pick")), trunc("1.30186990851854");
  is trunc($random->nonzero("pick")), trunc("1.72848495280885");
  is trunc($random->nonzero("pick")), trunc("1.05539717362683");
  is trunc($random->nonzero("pick")), trunc("1.27396181123785");
  is trunc($random->nonzero("pick")), trunc("1.28977139272935");
  is trunc($random->nonzero("pick")), trunc("1.56573009953997");
  is trunc($random->nonzero("pick")), trunc("1.85517543970009");
  is trunc($random->nonzero("pick")), trunc("1.21610080933634");
  is trunc($random->nonzero("pick")), trunc("1.80173044923592");
  is trunc($random->nonzero("pick")), trunc("1.81684752985822");
  is trunc($random->nonzero("pick")), trunc("1.21368445304509");
  is trunc($random->nonzero("pick")), trunc("1.08873438899161");
  is trunc($random->nonzero("pick")), trunc("1.55717420926014");
  is trunc($random->nonzero("pick")), trunc("1.52478508962086");
  is trunc($random->nonzero("pick")), trunc("1.8641211929522");
  is trunc($random->nonzero("pick")), trunc("1.93316076129385");
  is trunc($random->nonzero("pick")), trunc("1.13895989130389");
  is trunc($random->nonzero("pick")), trunc("1.54446423796457");
  is trunc($random->nonzero("pick")), trunc("1.5192197320834");
  is trunc($random->nonzero("pick")), trunc("1.29349717538767");

  $result
});

=example-3 nonzero

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero("number");

  # 3427014

  # $nonzero = $random->nonzero("number");

  # 3

=cut

$test->for('example', 3, 'nonzero', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->nonzero("number")), trunc("3427014");
  is trunc($random->nonzero("number")), trunc(3);
  is trunc($random->nonzero("number")), trunc(4);
  is trunc($random->nonzero("number")), trunc("6907");
  is trunc($random->nonzero("number")), trunc("46289982");
  is trunc($random->nonzero("number")), trunc("53396");
  is trunc($random->nonzero("number")), trunc(6);
  is trunc($random->nonzero("number")), trunc("489384813");
  is trunc($random->nonzero("number")), trunc("49668");
  is trunc($random->nonzero("number")), trunc("3496");
  is trunc($random->nonzero("number")), trunc("60391598");
  is trunc($random->nonzero("number")), trunc("97198997");
  is trunc($random->nonzero("number")), trunc("25187731");
  is trunc($random->nonzero("number")), trunc(9);
  is trunc($random->nonzero("number")), trunc("727");
  is trunc($random->nonzero("number")), trunc(2);
  is trunc($random->nonzero("number")), trunc("85516");
  is trunc($random->nonzero("number")), trunc("79");
  is trunc($random->nonzero("number")), trunc("21368445");
  is trunc($random->nonzero("number")), trunc(5);
  is trunc($random->nonzero("number")), trunc("93316075");
  is trunc($random->nonzero("number")), trunc(4);
  is trunc($random->nonzero("number")), trunc("29349");
  is trunc($random->nonzero("number")), trunc("460");
  is trunc($random->nonzero("number")), trunc(1);
  is trunc($random->nonzero("number")), trunc("53");
  is trunc($random->nonzero("number")), trunc(8);
  is trunc($random->nonzero("number")), trunc("687274333");
  is trunc($random->nonzero("number")), trunc("25");
  is trunc($random->nonzero("number")), trunc(4);
  is trunc($random->nonzero("number")), trunc("5399");
  is trunc($random->nonzero("number")), trunc("83");
  is trunc($random->nonzero("number")), trunc("616");
  is trunc($random->nonzero("number")), trunc(5);
  is trunc($random->nonzero("number")), trunc(2);
  is trunc($random->nonzero("number")), trunc("214385396");
  is trunc($random->nonzero("number")), trunc("77348229");
  is trunc($random->nonzero("number")), trunc("822785");
  is trunc($random->nonzero("number")), trunc("252538");
  is trunc($random->nonzero("number")), trunc("102945");
  is trunc($random->nonzero("number")), trunc("126048771");
  is trunc($random->nonzero("number")), trunc("61415");
  is trunc($random->nonzero("number")), trunc("35565999");
  is trunc($random->nonzero("number")), trunc("5959162");
  is trunc($random->nonzero("number")), trunc("82");
  is trunc($random->nonzero("number")), trunc("90573");
  is trunc($random->nonzero("number")), trunc("57");
  is trunc($random->nonzero("number")), trunc("896");
  is trunc($random->nonzero("number")), trunc("260780618");
  is trunc($random->nonzero("number")), trunc("218398");

  $result
});

=example-4 nonzero

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero("number", 0, 10);

  # 8

  # $nonzero = $random->nonzero("number", 0, 10);

  # 3

=cut

$test->for('example', 4, 'nonzero', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->nonzero("number", 0, 10), 8;
  is $random->nonzero("number", 0, 10), 3;
  is $random->nonzero("number", 0, 10), 1;
  is $random->nonzero("number", 0, 10), 4;
  is $random->nonzero("number", 0, 10), 8;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 7;
  is $random->nonzero("number", 0, 10), 9;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 6;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 7;
  is $random->nonzero("number", 0, 10), 6;
  is $random->nonzero("number", 0, 10), 9;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 4;
  is $random->nonzero("number", 0, 10), 3;
  is $random->nonzero("number", 0, 10), 10;
  is $random->nonzero("number", 0, 10), 8;
  is $random->nonzero("number", 0, 10), 10;
  is $random->nonzero("number", 0, 10), 9;
  is $random->nonzero("number", 0, 10), 2;
  is $random->nonzero("number", 0, 10), 2;
  is $random->nonzero("number", 0, 10), 1;
  is $random->nonzero("number", 0, 10), 3;
  is $random->nonzero("number", 0, 10), 8;
  is $random->nonzero("number", 0, 10), 2;
  is $random->nonzero("number", 0, 10), 3;
  is $random->nonzero("number", 0, 10), 6;
  is $random->nonzero("number", 0, 10), 9;
  is $random->nonzero("number", 0, 10), 2;
  is $random->nonzero("number", 0, 10), 8;
  is $random->nonzero("number", 0, 10), 8;
  is $random->nonzero("number", 0, 10), 2;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 9;
  is $random->nonzero("number", 0, 10), 10;
  is $random->nonzero("number", 0, 10), 1;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 3;
  is $random->nonzero("number", 0, 10), 3;
  is $random->nonzero("number", 0, 10), 5;
  is $random->nonzero("number", 0, 10), 2;
  is $random->nonzero("number", 0, 10), 1;
  is $random->nonzero("number", 0, 10), 2;

  $result
});

=method number

The number method returns a random number within the range provided. If no
arguments are provided, the range is from C<0> to C<2147483647>. If only the
first argument is provided, it's treated as the desired length of the number.

=signature number

  number(number $from, number $upto) (number)

=metadata number

{
  since => '1.11',
}

=example-1 number

  # given: synopsis

  package main;

  my $number = $random->number;

  # 3427014

  # $number = $random->number;

  # 3

=cut

$test->for('example', 1, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->number), trunc("3427014");
  is trunc($random->number), trunc("3");
  is trunc($random->number), trunc("0");
  is trunc($random->number), trunc("4787");
  is trunc($random->number), trunc("834592");
  is trunc($random->number), trunc("5775");
  is trunc($random->number), trunc("2588");
  is trunc($random->number), trunc("6011363");
  is trunc($random->number), trunc("489384813");
  is trunc($random->number), trunc("49668");
  is trunc($random->number), trunc("3496");
  is trunc($random->number), trunc("60391598");
  is trunc($random->number), trunc("97198997");
  is trunc($random->number), trunc("25187731");
  is trunc($random->number), trunc("9");
  is trunc($random->number), trunc("727");
  is trunc($random->number), trunc("0");
  is trunc($random->number), trunc("56");
  is trunc($random->number), trunc("21610080");
  is trunc($random->number), trunc("81684752");
  is trunc($random->number), trunc("8");
  is trunc($random->number), trunc("52477");
  is trunc($random->number), trunc("93316075");
  is trunc($random->number), trunc("4");
  is trunc($random->number), trunc("29349");
  is trunc($random->number), trunc("460");
  is trunc($random->number), trunc("1");
  is trunc($random->number), trunc("53");
  is trunc($random->number), trunc("0");
  is trunc($random->number), trunc("94305100");
  is trunc($random->number), trunc("284745");
  is trunc($random->number), trunc("1");
  is trunc($random->number), trunc("406193");
  is trunc($random->number), trunc("5399");
  is trunc($random->number), trunc("83");
  is trunc($random->number), trunc("616");
  is trunc($random->number), trunc("5");
  is trunc($random->number), trunc("2");
  is trunc($random->number), trunc("214385396");
  is trunc($random->number), trunc("77348229");
  is trunc($random->number), trunc("822785");
  is trunc($random->number), trunc("252538");
  is trunc($random->number), trunc("102945");
  is trunc($random->number), trunc("126048771");
  is trunc($random->number), trunc("61415");
  is trunc($random->number), trunc("35565999");
  is trunc($random->number), trunc("5959162");
  is trunc($random->number), trunc("82");
  is trunc($random->number), trunc("90573");
  is trunc($random->number), trunc("57");

  $result
});

=example-2 number

  # given: synopsis

  package main;

  my $number = $random->number(5, 50);

  # 39

  # $number = $random->number(5, 50);

  # 20

=cut

$test->for('example', 2, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->number(5, 50), 39;
  is $random->number(5, 50), 20;
  is $random->number(5, 50), 10;
  is $random->number(5, 50), 24;
  is $random->number(5, 50), 8;
  is $random->number(5, 50), 44;
  is $random->number(5, 50), 27;
  is $random->number(5, 50), 27;
  is $random->number(5, 50), 36;
  is $random->number(5, 50), 43;
  is $random->number(5, 50), 26;
  is $random->number(5, 50), 31;
  is $random->number(5, 50), 29;
  is $random->number(5, 50), 6;
  is $random->number(5, 50), 40;
  is $random->number(5, 50), 32;
  is $random->number(5, 50), 46;
  is $random->number(5, 50), 27;
  is $random->number(5, 50), 29;
  is $random->number(5, 50), 27;
  is $random->number(5, 50), 25;
  is $random->number(5, 50), 21;
  is $random->number(5, 50), 47;
  is $random->number(5, 50), 7;
  is $random->number(5, 50), 44;
  is $random->number(5, 50), 49;
  is $random->number(5, 50), 44;
  is $random->number(5, 50), 16;
  is $random->number(5, 50), 14;
  is $random->number(5, 50), 9;
  is $random->number(5, 50), 18;
  is $random->number(5, 50), 38;
  is $random->number(5, 50), 7;
  is $random->number(5, 50), 17;
  is $random->number(5, 50), 18;
  is $random->number(5, 50), 31;
  is $random->number(5, 50), 44;
  is $random->number(5, 50), 14;
  is $random->number(5, 50), 41;
  is $random->number(5, 50), 42;
  is $random->number(5, 50), 14;
  is $random->number(5, 50), 9;
  is $random->number(5, 50), 30;
  is $random->number(5, 50), 29;
  is $random->number(5, 50), 44;
  is $random->number(5, 50), 47;
  is $random->number(5, 50), 11;
  is $random->number(5, 50), 30;
  is $random->number(5, 50), 28;
  is $random->number(5, 50), 18;

  $result
});

=example-3 number

  # given: synopsis

  package main;

  my $number = $random->number(100, 20);

  # 42

  # $number = $random->number(100, 20);

  # 73

=cut

$test->for('example', 3, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->number(100, 20), 42;
  is $random->number(100, 20), 73;
  is $random->number(100, 20), 92;
  is $random->number(100, 20), 67;
  is $random->number(100, 20), 94;
  is $random->number(100, 20), 33;
  is $random->number(100, 20), 61;
  is $random->number(100, 20), 63;
  is $random->number(100, 20), 46;
  is $random->number(100, 20), 35;
  is $random->number(100, 20), 64;
  is $random->number(100, 20), 55;
  is $random->number(100, 20), 58;
  is $random->number(100, 20), 98;
  is $random->number(100, 20), 40;
  is $random->number(100, 20), 53;
  is $random->number(100, 20), 29;
  is $random->number(100, 20), 62;
  is $random->number(100, 20), 58;
  is $random->number(100, 20), 61;
  is $random->number(100, 20), 66;
  is $random->number(100, 20), 73;
  is $random->number(100, 20), 28;
  is $random->number(100, 20), 96;
  is $random->number(100, 20), 33;
  is $random->number(100, 20), 24;
  is $random->number(100, 20), 33;
  is $random->number(100, 20), 81;
  is $random->number(100, 20), 84;
  is $random->number(100, 20), 93;
  is $random->number(100, 20), 77;
  is $random->number(100, 20), 43;
  is $random->number(100, 20), 96;
  is $random->number(100, 20), 79;
  is $random->number(100, 20), 78;
  is $random->number(100, 20), 56;
  is $random->number(100, 20), 33;
  is $random->number(100, 20), 83;
  is $random->number(100, 20), 37;
  is $random->number(100, 20), 36;
  is $random->number(100, 20), 84;
  is $random->number(100, 20), 93;
  is $random->number(100, 20), 56;
  is $random->number(100, 20), 59;
  is $random->number(100, 20), 32;
  is $random->number(100, 20), 27;
  is $random->number(100, 20), 90;
  is $random->number(100, 20), 57;
  is $random->number(100, 20), 59;
  is $random->number(100, 20), 77;

  $result
});

=example-4 number

  # given: synopsis

  package main;

  my $number = $random->number(5);

  # 74451

  # $number = $random->number(5);

  # 34269

=cut

$test->for('example', 4, 'number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->number(5), 74451;
  is $random->number(5), 34269;
  is $random->number(5), 11108;
  is $random->number(5), 42233;
  is $random->number(5), 8111;
  is $random->number(5), 85643;
  is $random->number(5), 49879;
  is $random->number(5), 47880;
  is $random->number(5), 69080;
  is $random->number(5), 83458;
  is $random->number(5), 46289;
  is $random->number(5), 57763;
  is $random->number(5), 53396;
  is $random->number(5), 2588;
  is $random->number(5), 76980;
  is $random->number(5), 60113;
  is $random->number(5), 90882;
  is $random->number(5), 48937;
  is $random->number(5), 53598;
  is $random->number(5), 49668;
  is $random->number(5), 43763;
  is $random->number(5), 34967;
  is $random->number(5), 92191;
  is $random->number(5), 6039;
  is $random->number(5), 85988;
  is $random->number(5), 97198;
  is $random->number(5), 84889;
  is $random->number(5), 25187;
  is $random->number(5), 20578;
  is $random->number(5), 9677;
  is $random->number(5), 30186;
  is $random->number(5), 72847;
  is $random->number(5), 5539;
  is $random->number(5), 27395;
  is $random->number(5), 28976;
  is $random->number(5), 56572;
  is $random->number(5), 85516;
  is $random->number(5), 21609;
  is $random->number(5), 80172;
  is $random->number(5), 81683;
  is $random->number(5), 21368;
  is $random->number(5), 8873;
  is $random->number(5), 55716;
  is $random->number(5), 52477;
  is $random->number(5), 86411;
  is $random->number(5), 93315;
  is $random->number(5), 13895;
  is $random->number(5), 54445;
  is $random->number(5), 51921;
  is $random->number(5), 29349;

  $result
});

=method numbers

The numbers method returns C<n> L</number> characters (between C<1> and C<9>)
based on the number (i.e.  count) provided.

=signature numbers

  numbers(number $count) (string)

=metadata numbers

{
  since => '4.15',
}

=example-1 numbers

  # given: synopsis

  package main;

  my $numbers = $random->numbers(5);

  # 74141

  # $numbers = $random->numbers(5);

  # 85578

=cut

$test->for('example', 1, 'numbers', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->numbers(5), '74141';
  is $random->numbers(5), '85578';
  is $random->numbers(5), '56517';
  is $random->numbers(5), '69555';
  is $random->numbers(5), '44918';
  is $random->numbers(5), '98321';
  is $random->numbers(5), '37133';
  is $random->numbers(5), '68288';
  is $random->numbers(5), '21658';
  is $random->numbers(5), '92553';
  is $random->numbers(5), '35223';
  is $random->numbers(5), '51589';
  is $random->numbers(5), '73316';
  is $random->numbers(5), '45538';
  is $random->numbers(5), '46262';
  is $random->numbers(5), '39287';
  is $random->numbers(5), '68636';
  is $random->numbers(5), '19256';
  is $random->numbers(5), '91763';
  is $random->numbers(5), '86136';
  is $random->numbers(5), '49936';
  is $random->numbers(5), '28996';
  is $random->numbers(5), '57629';
  is $random->numbers(5), '22471';
  is $random->numbers(5), '64535';
  is $random->numbers(5), '12417';
  is $random->numbers(5), '44319';
  is $random->numbers(5), '57794';
  is $random->numbers(5), '15938';
  is $random->numbers(5), '28991';
  is $random->numbers(5), '72826';
  is $random->numbers(5), '76311';
  is $random->numbers(5), '99427';
  is $random->numbers(5), '59999';
  is $random->numbers(5), '63813';
  is $random->numbers(5), '39552';
  is $random->numbers(5), '59129';
  is $random->numbers(5), '88559';
  is $random->numbers(5), '65461';
  is $random->numbers(5), '76964';
  is $random->numbers(5), '27952';
  is $random->numbers(5), '89775';
  is $random->numbers(5), '65244';
  is $random->numbers(5), '56191';
  is $random->numbers(5), '66775';
  is $random->numbers(5), '28974';
  is $random->numbers(5), '57412';
  is $random->numbers(5), '77587';
  is $random->numbers(5), '71672';
  is $random->numbers(5), '52876';

  $result
});

=method password

The password method returns C<n> L<"characters"|/character> based on the number
(i.e. count) provided. The default length is 16.

=signature password

  password(number $count) (string)

=metadata password

{
  since => '4.15',
}

=example-1 password

  # given: synopsis

  package main;

  my $password = $random->password;

  # "0*89{745axCMg0m2"

  # $password = $random->password;

  # "5rV22V24>6Q1v#6N"

=cut

$test->for('example', 1, 'password', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is length($result), 16;

  my $random = Venus::Random->new(42);

  is $random->password, '0*89{745axCMg0m2';
  is $random->password, '5rV22V24>6Q1v#6N';
  is $random->password, '45>p1087p42Q9K=0';
  is $random->password, '8p5g40289k7,4?zC';
  is $random->password, '[n4s5r371AQc81r;';
  is $random->password, '07^g21;5ljUiM0l4';
  is $random->password, 'se7c508Z[78?3gqq';
  is $random->password, '184$690Zj4+8307N';
  is $random->password, 'Wqkd6B-be_5Yk5l4';
  is $random->password, 'ITcO$11iP%J8X462';
  is $random->password, '\150m53U)UT6d58I';
  is $random->password, '84|g/G2529484117';
  is $random->password, '7\'LIvn\Y4L0x2358';
  is $random->password, '6{ueWDt8441323~4';
  is $random->password, 'k944AH26179<$88x';
  is $random->password, '4377E1X7$6K5VU,4';
  is $random->password, 'FK0s02@Y11s40^Ju';
  is $random->password, '4453R665O6]D0\Ov';
  is $random->password, '1X5(n9e6F3V8^VI5';
  is $random->password, '62Xp3~63%49187c9';
  is $random->password, '361PL#U&7640l6g9';
  is $random->password, '%B66.fQ2H120Ei6z';
  is $random->password, '84Bda80!K0cj1"N7';
  is $random->password, '67+6O090y181f,4n';
  is $random->password, 'r\3PD8h]48qW8f0Y';
  is $random->password, 'edGz0y4y3;[b34U2';
  is $random->password, '12<545Kl5=65XUYb';
  is $random->password, '7J:Ah9%13665HYvN';
  is $random->password, 'R72=6dw0A516a$j1';
  is $random->password, 'nXz734(f)p47230l';
  is $random->password, 'BZb320uMQ%fE56d#';
  is $random->password, '91Z.4PfwRJQc1%46';
  is $random->password, 'Q!0VE%Os8X51L1r6';
  is $random->password, '7113<97k3g7tdJ3)';
  is $random->password, 'm\'e3uf51.31OY068';
  is $random->password, '47SF.EG82:T6T23B';
  is $random->password, 'Bo1n8_L959;32zAo';
  is $random->password, 'y764]t26R9uJQp@0';
  is $random->password, '41062581I1)D3>M2';
  is $random->password, '2iw55Fwpz#=ezD49';
  is $random->password, '7ho;5E253~Uw7825';
  is $random->password, '$807>3KT656lSz33';
  is $random->password, '{R4x?9265WBXh24p';
  is $random->password, 'EcC{i9s*Pd61q3m8';
  is $random->password, '!88Y910(8UA86MY9';
  is $random->password, 'QksL0J2Kv3uoo!r!';
  is $random->password, '2L-(Q37Yy0a58n21';
  is $random->password, 'i619ryZ21}80T1(7';
  is $random->password, '40:e81beSb&95ato';
  is $random->password, '97Hx6jUpU0,6Fm|R';

  $result
});

=method pick

The pick method is the random number generator and returns a random number. By
default, calling this method is equivalent to call L<perlfunc/rand>. This
method can be overridden in a subclass to provide a custom generator, e.g. a
more cyptographically secure generator.

=signature pick

  pick(Num $data) (Num)

=metadata pick

{
  since => '1.23',
}

=example-1 pick

  # given: synopsis

  package main;

  my $pick = $random->pick;

  # 0.744525000061007

  # $pick = $random->pick;

  # 0.342701478718908

=cut

$test->for('example', 1, 'pick', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->pick), trunc("0.74452500006100");
  is trunc($random->pick), trunc("0.342701478718908");
  is trunc($random->pick), trunc("0.111085282444161");
  is trunc($random->pick), trunc("0.422338957988309");
  is trunc($random->pick), trunc("0.0811111711783106");
  is trunc($random->pick), trunc("0.856440708026625");
  is trunc($random->pick), trunc("0.498799422194079");
  is trunc($random->pick), trunc("0.478814290644628");
  is trunc($random->pick), trunc("0.690812444305639");
  is trunc($random->pick), trunc("0.834593765962154");
  is trunc($random->pick), trunc("0.462899834399462");
  is trunc($random->pick), trunc("0.577638060310598");
  is trunc($random->pick), trunc("0.53397276092527");
  is trunc($random->pick), trunc("0.0258899224807152");
  is trunc($random->pick), trunc("0.769812041501151");
  is trunc($random->pick), trunc("0.601136413955935");
  is trunc($random->pick), trunc("0.908832753514449");
  is trunc($random->pick), trunc("0.489384814281067");
  is trunc($random->pick), trunc("0.535989747213943");
  is trunc($random->pick), trunc("0.496690956018035");
  is trunc($random->pick), trunc("0.437637516830268");
  is trunc($random->pick), trunc("0.349677252863827");
  is trunc($random->pick), trunc("0.921922185727137");
  is trunc($random->pick), trunc("0.0603915988287085");
  is trunc($random->pick), trunc("0.859894102366727");
  is trunc($random->pick), trunc("0.971989986776236");
  is trunc($random->pick), trunc("0.848903724785583");
  is trunc($random->pick), trunc("0.251877319902214");
  is trunc($random->pick), trunc("0.205785604346421");
  is trunc($random->pick), trunc("0.0967722492353715");
  is trunc($random->pick), trunc("0.301869908518537");
  is trunc($random->pick), trunc("0.728484952808849");
  is trunc($random->pick), trunc("0.0553971736268331");
  is trunc($random->pick), trunc("0.273961811237854");
  is trunc($random->pick), trunc("0.289771392729346");
  is trunc($random->pick), trunc("0.565730099539969");
  is trunc($random->pick), trunc("0.855175439700094");
  is trunc($random->pick), trunc("0.216100809336339");
  is trunc($random->pick), trunc("0.801730449235915");
  is trunc($random->pick), trunc("0.816847529858215");
  is trunc($random->pick), trunc("0.213684453045094");
  is trunc($random->pick), trunc("0.088734388991611");
  is trunc($random->pick), trunc("0.557174209260136");
  is trunc($random->pick), trunc("0.524785089620856");
  is trunc($random->pick), trunc("0.864121192952201");
  is trunc($random->pick), trunc("0.933160761293848");
  is trunc($random->pick), trunc("0.138959891303895");
  is trunc($random->pick), trunc("0.544464237964569");
  is trunc($random->pick), trunc("0.519219732083403");
  is trunc($random->pick), trunc("0.293497175387671");

  $result
});

=example-2 pick

  # given: synopsis

  package main;

  my $pick = $random->pick(100);

  # 74.4525000061007

  # $pick = $random->pick(100);

  # 34.2701478718908

=cut

$test->for('example', 2, 'pick', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->pick(100)), trunc("74.4525000061007");
  is trunc($random->pick(100)), trunc("34.2701478718908");
  is trunc($random->pick(100)), trunc("11.1085282444161");
  is trunc($random->pick(100)), trunc("42.2338957988309");
  is trunc($random->pick(100)), trunc("8.11111711783106");
  is trunc($random->pick(100)), trunc("85.6440708026625");
  is trunc($random->pick(100)), trunc("49.8799422194079");
  is trunc($random->pick(100)), trunc("47.8814290644628");
  is trunc($random->pick(100)), trunc("69.0812444305639");
  is trunc($random->pick(100)), trunc("83.4593765962154");
  is trunc($random->pick(100)), trunc("46.2899834399462");
  is trunc($random->pick(100)), trunc("57.7638060310598");
  is trunc($random->pick(100)), trunc("53.397276092527");
  is trunc($random->pick(100)), trunc("2.58899224807152");
  is trunc($random->pick(100)), trunc("76.9812041501151");
  is trunc($random->pick(100)), trunc("60.1136413955935");
  is trunc($random->pick(100)), trunc("90.8832753514449");
  is trunc($random->pick(100)), trunc("48.9384814281067");
  is trunc($random->pick(100)), trunc("53.5989747213943");
  is trunc($random->pick(100)), trunc("49.6690956018035");
  is trunc($random->pick(100)), trunc("43.7637516830268");
  is trunc($random->pick(100)), trunc("34.9677252863827");
  is trunc($random->pick(100)), trunc("92.1922185727137");
  is trunc($random->pick(100)), trunc("6.03915988287085");
  is trunc($random->pick(100)), trunc("85.9894102366727");
  is trunc($random->pick(100)), trunc("97.1989986776236");
  is trunc($random->pick(100)), trunc("84.8903724785583");
  is trunc($random->pick(100)), trunc("25.1877319902214");
  is trunc($random->pick(100)), trunc("20.5785604346421");
  is trunc($random->pick(100)), trunc("9.67722492353715");
  is trunc($random->pick(100)), trunc("30.1869908518537");
  is trunc($random->pick(100)), trunc("72.8484952808849");
  is trunc($random->pick(100)), trunc("5.53971736268331");
  is trunc($random->pick(100)), trunc("27.3961811237854");
  is trunc($random->pick(100)), trunc("28.9771392729346");
  is trunc($random->pick(100)), trunc("56.5730099539969");
  is trunc($random->pick(100)), trunc("85.5175439700094");
  is trunc($random->pick(100)), trunc("21.6100809336339");
  is trunc($random->pick(100)), trunc("80.1730449235915");
  is trunc($random->pick(100)), trunc("81.6847529858215");
  is trunc($random->pick(100)), trunc("21.3684453045094");
  is trunc($random->pick(100)), trunc("8.8734388991611");
  is trunc($random->pick(100)), trunc("55.7174209260136");
  is trunc($random->pick(100)), trunc("52.4785089620856");
  is trunc($random->pick(100)), trunc("86.4121192952201");
  is trunc($random->pick(100)), trunc("93.3160761293848");
  is trunc($random->pick(100)), trunc("13.8959891303895");
  is trunc($random->pick(100)), trunc("54.4464237964569");
  is trunc($random->pick(100)), trunc("51.9219732083403");
  is trunc($random->pick(100)), trunc("29.3497175387671");

  $result
});

=example-3 pick

  # given: synopsis

  package main;

  my $pick = $random->pick(2);

  # 1.48905000012201

  # $pick = $random->pick(2);

  # 0.685402957437816

=cut

$test->for('example', 3, 'pick', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is trunc($random->pick(2)), trunc("1.48905000012201");
  is trunc($random->pick(2)), trunc("0.685402957437816");
  is trunc($random->pick(2)), trunc("0.222170564888323");
  is trunc($random->pick(2)), trunc("0.844677915976618");
  is trunc($random->pick(2)), trunc("0.162222342356621");
  is trunc($random->pick(2)), trunc("1.71288141605325");
  is trunc($random->pick(2)), trunc("0.997598844388158");
  is trunc($random->pick(2)), trunc("0.957628581289256");
  is trunc($random->pick(2)), trunc("1.38162488861128");
  is trunc($random->pick(2)), trunc("1.66918753192431");
  is trunc($random->pick(2)), trunc("0.925799668798923");
  is trunc($random->pick(2)), trunc("1.1552761206212");
  is trunc($random->pick(2)), trunc("1.06794552185054");
  is trunc($random->pick(2)), trunc("0.0517798449614304");
  is trunc($random->pick(2)), trunc("1.5396240830023");
  is trunc($random->pick(2)), trunc("1.20227282791187");
  is trunc($random->pick(2)), trunc("1.8176655070289");
  is trunc($random->pick(2)), trunc("0.978769628562134");
  is trunc($random->pick(2)), trunc("1.07197949442789");
  is trunc($random->pick(2)), trunc("0.993381912036071");
  is trunc($random->pick(2)), trunc("0.875275033660536");
  is trunc($random->pick(2)), trunc("0.699354505727655");
  is trunc($random->pick(2)), trunc("1.84384437145427");
  is trunc($random->pick(2)), trunc("0.120783197657417");
  is trunc($random->pick(2)), trunc("1.71978820473345");
  is trunc($random->pick(2)), trunc("1.94397997355247");
  is trunc($random->pick(2)), trunc("1.69780744957117");
  is trunc($random->pick(2)), trunc("0.503754639804427");
  is trunc($random->pick(2)), trunc("0.411571208692841");
  is trunc($random->pick(2)), trunc("0.193544498470743");
  is trunc($random->pick(2)), trunc("0.603739817037074");
  is trunc($random->pick(2)), trunc("1.4569699056177");
  is trunc($random->pick(2)), trunc("0.110794347253666");
  is trunc($random->pick(2)), trunc("0.547923622475707");
  is trunc($random->pick(2)), trunc("0.579542785458692");
  is trunc($random->pick(2)), trunc("1.13146019907994");
  is trunc($random->pick(2)), trunc("1.71035087940019");
  is trunc($random->pick(2)), trunc("0.432201618672678");
  is trunc($random->pick(2)), trunc("1.60346089847183");
  is trunc($random->pick(2)), trunc("1.63369505971643");
  is trunc($random->pick(2)), trunc("0.427368906090187");
  is trunc($random->pick(2)), trunc("0.177468777983222");
  is trunc($random->pick(2)), trunc("1.11434841852027");
  is trunc($random->pick(2)), trunc("1.04957017924171");
  is trunc($random->pick(2)), trunc("1.7282423859044");
  is trunc($random->pick(2)), trunc("1.8663215225877");
  is trunc($random->pick(2)), trunc("0.277919782607789");
  is trunc($random->pick(2)), trunc("1.08892847592914");
  is trunc($random->pick(2)), trunc("1.03843946416681");
  is trunc($random->pick(2)), trunc("0.586994350775342");

  $result
});

=method range

The range method returns a random number within the range provided. If no
arguments are provided, the range is from C<0> to C<2147483647>.

=signature range

  range(string $from, string $to) (number)

=metadata range

{
  since => '1.11',
}

=example-1 range

  # given: synopsis

  package main;

  my $range = $random->range(1, 10);

  # 8

  # $range = $random->range(1, 10);

  # 4

=cut

$test->for('example', 1, 'range', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->range(1, 10), 8;
  is $random->range(1, 10), 4;
  is $random->range(1, 10), 2;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 1;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 7;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 1;
  is $random->range(1, 10), 8;
  is $random->range(1, 10), 7;
  is $random->range(1, 10), 10;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 5;
  is $random->range(1, 10), 4;
  is $random->range(1, 10), 10;
  is $random->range(1, 10), 1;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 10;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 3;
  is $random->range(1, 10), 3;
  is $random->range(1, 10), 1;
  is $random->range(1, 10), 4;
  is $random->range(1, 10), 8;
  is $random->range(1, 10), 1;
  is $random->range(1, 10), 3;
  is $random->range(1, 10), 3;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 3;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 3;
  is $random->range(1, 10), 1;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 9;
  is $random->range(1, 10), 10;
  is $random->range(1, 10), 2;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 6;
  is $random->range(1, 10), 3;

  $result
});

=example-2 range

  # given: synopsis

  package main;

  my $range = $random->range(10, 1);

  # 5

  # $range = $random->range(10, 1);

  # 8

=cut

$test->for('example', 2, 'range', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->range(10, 1), 5;
  is $random->range(10, 1), 8;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 5;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 3;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 7;
  is $random->range(10, 1), 8;
  is $random->range(10, 1), 3;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 3;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 8;
  is $random->range(10, 1), 9;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 8;
  is $random->range(10, 1), 5;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 8;
  is $random->range(10, 1), 8;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 9;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 9;
  is $random->range(10, 1), 10;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 4;
  is $random->range(10, 1), 3;
  is $random->range(10, 1), 9;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 6;
  is $random->range(10, 1), 8;

  $result
});

=example-3 range

  # given: synopsis

  package main;

  my $range = $random->range(0, 60);

  # 45

  # $range = $random->range(0, 60);

  # 20

=cut

$test->for('example', 3, 'range', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->range(0, 60), 45;
  is $random->range(0, 60), 20;
  is $random->range(0, 60), 6;
  is $random->range(0, 60), 25;
  is $random->range(0, 60), 4;
  is $random->range(0, 60), 52;
  is $random->range(0, 60), 30;
  is $random->range(0, 60), 29;
  is $random->range(0, 60), 42;
  is $random->range(0, 60), 50;
  is $random->range(0, 60), 28;
  is $random->range(0, 60), 35;
  is $random->range(0, 60), 32;
  is $random->range(0, 60), 1;
  is $random->range(0, 60), 46;
  is $random->range(0, 60), 36;
  is $random->range(0, 60), 55;
  is $random->range(0, 60), 29;
  is $random->range(0, 60), 32;
  is $random->range(0, 60), 30;
  is $random->range(0, 60), 26;
  is $random->range(0, 60), 21;
  is $random->range(0, 60), 56;
  is $random->range(0, 60), 3;
  is $random->range(0, 60), 52;
  is $random->range(0, 60), 59;
  is $random->range(0, 60), 51;
  is $random->range(0, 60), 15;
  is $random->range(0, 60), 12;
  is $random->range(0, 60), 5;
  is $random->range(0, 60), 18;
  is $random->range(0, 60), 44;
  is $random->range(0, 60), 3;
  is $random->range(0, 60), 16;
  is $random->range(0, 60), 17;
  is $random->range(0, 60), 34;
  is $random->range(0, 60), 52;
  is $random->range(0, 60), 13;
  is $random->range(0, 60), 48;
  is $random->range(0, 60), 49;
  is $random->range(0, 60), 13;
  is $random->range(0, 60), 5;
  is $random->range(0, 60), 33;
  is $random->range(0, 60), 32;
  is $random->range(0, 60), 52;
  is $random->range(0, 60), 56;
  is $random->range(0, 60), 8;
  is $random->range(0, 60), 33;
  is $random->range(0, 60), 31;
  is $random->range(0, 60), 17;

  $result
});

=example-4 range

  # given: synopsis

  package main;

  my $range = $random->range(-5, -1);

  # -2

  # $range = $random->range(-5, -1);

  # -4

=cut

$test->for('example', 4, 'range', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->range(-5, -1), -2;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -2;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -2;
  is $random->range(-5, -1), -2;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -2;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -4;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -1;
  is $random->range(-5, -1), -5;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -3;
  is $random->range(-5, -1), -4;

  $result
});

=method repeat

The repeat method dispatches to the specified method or coderef, repeatedly
based on the number of C<$times> specified, and returns the random results from
each dispatched call. In list context, the results from each call is returned
as a list, in scalar context the results are concatenated.

=signature repeat

  repeat(number $times, string | coderef $code, any @args) (number | string)

=metadata repeat

{
  since => '1.11',
}

=example-1 repeat

  # given: synopsis

  package main;

  my @repeat = $random->repeat(2);

  # (7, 3)

  # @repeat = $random->repeat(2);

  # (1, 4)


=cut

$test->for('example', 1, 'repeat', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is_deeply [$random->repeat(2)], [7, 3];
  is_deeply [$random->repeat(2)], [1, 4];
  is_deeply [$random->repeat(2)], [0, 8];
  is_deeply [$random->repeat(2)], [4, 4];
  is_deeply [$random->repeat(2)], [6, 8];
  is_deeply [$random->repeat(2)], [4, 5];
  is_deeply [$random->repeat(2)], [5, 0];
  is_deeply [$random->repeat(2)], [7, 6];
  is_deeply [$random->repeat(2)], [9, 4];
  is_deeply [$random->repeat(2)], [5, 4];
  is_deeply [$random->repeat(2)], [4, 3];
  is_deeply [$random->repeat(2)], [9, 0];
  is_deeply [$random->repeat(2)], [8, 9];
  is_deeply [$random->repeat(2)], [8, 2];
  is_deeply [$random->repeat(2)], [2, 0];
  is_deeply [$random->repeat(2)], [3, 7];
  is_deeply [$random->repeat(2)], [0, 2];
  is_deeply [$random->repeat(2)], [2, 5];
  is_deeply [$random->repeat(2)], [8, 2];
  is_deeply [$random->repeat(2)], [8, 8];
  is_deeply [$random->repeat(2)], [2, 0];
  is_deeply [$random->repeat(2)], [5, 5];
  is_deeply [$random->repeat(2)], [8, 9];
  is_deeply [$random->repeat(2)], [1, 5];
  is_deeply [$random->repeat(2)], [5, 2];

  $result
});

=example-2 repeat

  # given: synopsis

  package main;

  my @repeat = $random->repeat(2, "float");

  # (1447361.5, "0.0000")

  # @repeat = $random->repeat(2, "float");

  # ("482092.1040", 1555.7410393)


=cut

$test->for('example', 2, 'repeat', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc(1447361.5), trunc("0.0000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("482092.1040"), trunc("1555.7410393")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("243073010.62968"), trunc("211.129029505")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("24482222.86154329"), trunc("6.556")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("0.00"), trunc("17652140.46803842")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("4.19828"), trunc("50807265.7")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("13521.258"), trunc("0.54")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("0.00000000"), trunc("2996.60")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("219329.0876"), trunc("51.256")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("1.2"), trunc("165823309.60632405")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("207785.414616"), trunc("12976.090746608")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("2184.285870579"), trunc("4962126.07")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("52996.93"), trunc("233.659434202")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("208182.10328548"), trunc("446099950.92124")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("27197.291840737"), trunc("2.1292108")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("11504.2135"), trunc("86.1")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("0.000"), trunc("0.000000000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("2814337.555595279"), trunc("0.000000000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("19592108.75910050"), trunc("7955940.0889820")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("10842452.67346"), trunc("236808.75850632")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("65.1309632"), trunc("898218603.151974320")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("25368.54295825"), trunc("13.232559545")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("1884.0766"), trunc("0.824919221")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("45112657.8201"), trunc("29867.7308")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("0.000000"), trunc("242355.0")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("441578271.4"), trunc("306151066.8583753")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("20089.0"), trunc("39.796373")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("3957537.963587"), trunc("980620.6971")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("3432846.381807"), trunc("259.606")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("2.978163"), trunc("7357424.866739")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("32449.6"), trunc("4.2612638")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("883940.5"), trunc("65.6")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("28888.177"), trunc("33.42273901")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("2.4"), trunc("857.0034")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("56816969.0888"), trunc("128687950.53139541")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("32255201.78919"), trunc("0.0000000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("112.8"), trunc("661.365279709")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("4.7003750"), trunc("1817.78179")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("3278.66699936"), trunc("150198904.49644646")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("0.000000000"), trunc("6219.25577121")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("4.47927"), trunc("31446229.542313")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("515.873542695"), trunc("0.0000000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("230595277.91726"), trunc("4835844.88")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("247375172.79516402"), trunc("0.0000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("50.455"), trunc("36.78468310")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("179.427"), trunc("17845232.53113518")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("168937448.725562"), trunc("18313039.6442055")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("49613658.9"), trunc("3.01152290")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("167.4974"), trunc("0.0000")];
  is_deeply [trunc($random->repeat(2, "float"))],
    [trunc("143953.7"), trunc("0.472408092")];

  $result
});

=example-3 repeat

  # given: synopsis

  package main;

  my @repeat = $random->repeat(2, "character");

  # (")", 4)

  # @repeat = $random->repeat(2, "character");

  # (8, "R")

=cut

$test->for('example', 3, 'repeat', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is_deeply [$random->repeat(2, "character")], [")", 4];
  is_deeply [$random->repeat(2, "character")], [8, "R"];
  is_deeply [$random->repeat(2, "character")], ["+", "a"];
  is_deeply [$random->repeat(2, "character")], ["}", "["];
  is_deeply [$random->repeat(2, "character")], ["L", "b"];
  is_deeply [$random->repeat(2, "character")], ["?", "&"];
  is_deeply [$random->repeat(2, "character")], [0, 7];
  is_deeply [$random->repeat(2, "character")], [2, 5];
  is_deeply [$random->repeat(2, "character")], ["^", ","];
  is_deeply [$random->repeat(2, "character")], [0, "w"];
  is_deeply [$random->repeat(2, "character")], ["\$", "h"];
  is_deeply [$random->repeat(2, "character")], [4, 1];
  is_deeply [$random->repeat(2, "character")], [5, 5];
  is_deeply [$random->repeat(2, "character")], [">", "*"];
  is_deeply [$random->repeat(2, "character")], [0, "M"];
  is_deeply [$random->repeat(2, "character")], ["V", "d"];
  is_deeply [$random->repeat(2, "character")], ["G", "^"];
  is_deeply [$random->repeat(2, "character")], ["'", "q"];
  is_deeply [$random->repeat(2, "character")], [6, 9];
  is_deeply [$random->repeat(2, "character")], [5, "a"];
  is_deeply [$random->repeat(2, "character")], ["}", 8];
  is_deeply [$random->repeat(2, "character")], ["G", "X"];
  is_deeply [$random->repeat(2, "character")], ["*", "V"];
  is_deeply [$random->repeat(2, "character")], [">", "t"];
  is_deeply [$random->repeat(2, "character")], ["Y", 2];
  is_deeply [$random->repeat(2, "character")], ["b", "L"];
  is_deeply [$random->repeat(2, "character")], [4, 1];
  is_deeply [$random->repeat(2, "character")], ["T", "H"];
  is_deeply [$random->repeat(2, "character")], [9, "t"];
  is_deeply [$random->repeat(2, "character")], ["-", 5];
  is_deeply [$random->repeat(2, "character")], [")", "^"];
  is_deeply [$random->repeat(2, "character")], ["?", "!"];
  is_deeply [$random->repeat(2, "character")], ["%", "\$"];
  is_deeply [$random->repeat(2, "character")], ["p", 0];
  is_deeply [$random->repeat(2, "character")], [8, "_"];
  is_deeply [$random->repeat(2, "character")], [7, "z"];
  is_deeply [$random->repeat(2, "character")], ["<", "V"];
  is_deeply [$random->repeat(2, "character")], [2, 9];
  is_deeply [$random->repeat(2, "character")], ["F", "c"];
  is_deeply [$random->repeat(2, "character")], [9, ","];
  is_deeply [$random->repeat(2, "character")], ["Z", "K"];
  is_deeply [$random->repeat(2, "character")], ["R", "q"];
  is_deeply [$random->repeat(2, "character")], ["S", "]"];
  is_deeply [$random->repeat(2, "character")], [8, ";"];
  is_deeply [$random->repeat(2, "character")], ["=", "E"];
  is_deeply [$random->repeat(2, "character")], ["N", "Y"];
  is_deeply [$random->repeat(2, "character")], [6, "r"];
  is_deeply [$random->repeat(2, "character")], ["U", ";"];
  is_deeply [$random->repeat(2, "character")], ["T", "E"];
  is_deeply [$random->repeat(2, "character")], [";", "r"];

  $result
});

=method reseed

The reseed method sets the L<perlfunc/srand> (i.e. the PRNG seed) to the value
provided, or the default value used on instanstiation when no seed is passed to
the constructor. This method returns the object that invoked it.

=signature reseed

  reseed(string $seed) (Venus::Random)

=metadata reseed

{
  since => '1.11',
}

=example-1 reseed

  # given: synopsis

  package main;

  my $reseed = $random->reseed;

  # bless({value => ...}, "Venus::Random")

  # my $bit = $random->bit;

  # 0

=cut

$test->for('example', 1, 'reseed', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Random');
  ok $result->value != 42;

  $result
});

=example-2 reseed

  # given: synopsis

  package main;

  my $reseed = $random->reseed(42);

  # bless({value => 42}, "Venus::Random")

  # my $bit = $random->bit;

  # 0

=cut

$test->for('example', 2, 'reseed', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Random');
  ok $result->value == 42;
  ok $result->bit == 0;

  $result
});

=method reset

The reset method sets the L<perlfunc/srand> (i.e. the PRNG seed) to the default
value used on instanstiation when no seed is passed to the constructor. This
method returns the object that invoked it.

=signature reset

  reset() (Venus::Random)

=metadata reset

{
  since => '1.11',
}

=example-1 reset

  # given: synopsis

  package main;

  my $reset = $random->reset;

  # bless({value => ...}, "Venus::Random")

=cut

$test->for('example', 1, 'reset', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Random');
  ok $result->value != 42;

  $result
});

=method restore

The restore method sets the L<perlfunc/srand> (i.e. the PRNG seed) to the
original value used by L<perlfunc/rand>. This method returns the object that
invoked it.

=signature restore

  restore() (Venus::Random)

=metadata restore

{
  since => '1.11',
}

=example-1 restore

  # given: synopsis

  package main;

  my $restore = $random->restore;

  # bless({value => ...}, "Venus::Random")

=cut

$test->for('example', 1, 'restore', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Random');
  ok $result->value != 42;

  $result
});

=method select

The select method returns a random value from the I<"hashref"> or I<"arrayref">
provided.

=signature select

  select(arrayref | hashref $data) (any)

=metadata select

{
  since => '1.11',
}

=example-1 select

  # given: synopsis

  package main;

  my $select = $random->select(["a".."d"]);

  # "c"

  # $select = $random->select(["a".."d"]);

  # "b"

=cut

$test->for('example', 1, 'select', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "b";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "d";
  is $random->select(["a".."d"]), "a";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "c";
  is $random->select(["a".."d"]), "b";

  $result
});

=example-2 select

  # given: synopsis

  package main;

  my $select = $random->select({"a".."h"});

  # "f"

  # $select = $random->select({"a".."h"});

  # "d"

=cut

$test->for('example', 2, 'select', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "d";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "h";
  is_deeply $random->select({"a".."h"}), "b";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "f";
  is_deeply $random->select({"a".."h"}), "d";

  $result
});

=method shuffle

The shuffle method returns the string provided with its characters randomly
rearranged.

=signature shuffle

  shuffle(string $string) (string)

=metadata shuffle

{
  since => '4.15',
}

=cut

=example-1 shuffle

  # given: synopsis

  package main;

  my $shuffle = $random->shuffle('hello');

  # "olhel"

  # $shuffle = $random->shuffle('hello');

  # "loelh"

=cut

$test->for('example', 1, 'shuffle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->shuffle('hello'), 'olhel';
  is $random->shuffle('hello'), 'loelh';
  is $random->shuffle('hello'), 'hleol';
  is $random->shuffle('hello'), 'leohl';
  is $random->shuffle('hello'), 'lhleo';

  $result
});

=method symbol

The symbol method returns a random symbol.

=signature symbol

  symbol() (string)

=metadata symbol

{
  since => '1.11',
}

=example-1 symbol

  # given: synopsis

  package main;

  my $symbol = $random->symbol;

  # "'"

  # $symbol = $random->symbol;

  # ")"

=cut

$test->for('example', 1, 'symbol', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->symbol, "'";
  is $random->symbol, ")";
  is $random->symbol, "#";
  is $random->symbol, "=";
  is $random->symbol, "\@";
  is $random->symbol, ".";
  is $random->symbol, "[";
  is $random->symbol, "+";
  is $random->symbol, ";";
  is $random->symbol, ",";
  is $random->symbol, "+";
  is $random->symbol, "{";
  is $random->symbol, "]";
  is $random->symbol, "~";
  is $random->symbol, "'";
  is $random->symbol, "}";
  is $random->symbol, "<";
  is $random->symbol, "[";
  is $random->symbol, "]";
  is $random->symbol, "[";
  is $random->symbol, "=";
  is $random->symbol, ")";
  is $random->symbol, "<";
  is $random->symbol, "!";
  is $random->symbol, ".";
  is $random->symbol, "?";
  is $random->symbol, ".";
  is $random->symbol, "&";
  is $random->symbol, "^";
  is $random->symbol, "\@";
  is $random->symbol, "(";
  is $random->symbol, ":";
  is $random->symbol, "!";
  is $random->symbol, "*";
  is $random->symbol, "*";
  is $random->symbol, "{";
  is $random->symbol, ".";
  is $random->symbol, "^";
  is $random->symbol, "\"";
  is $random->symbol, ",";
  is $random->symbol, "^";
  is $random->symbol, "\@";
  is $random->symbol, "{";
  is $random->symbol, "]";
  is $random->symbol, ".";
  is $random->symbol, "<";
  is $random->symbol, "\$";
  is $random->symbol, "]";
  is $random->symbol, "]";
  is $random->symbol, "(";

  $result
});

=method symbols

The symbols method returns C<n> L</symbol> characters based on the number (i.e.
count) provided.

=signature symbols

  symbols(number $count) (string)

=metadata symbols

{
  since => '4.15',
}

=cut

=example-1 symbols

  # given: synopsis

  package main;

  my $symbols = $random->symbols(5);

  # "')#=@"

  # $symbols = $random->symbols(5);

  # ".[+;,"

=cut

$test->for('example', 1, 'symbols', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->symbols(5), '\')#=@';
  is $random->symbols(5), '.[+;,';
  is $random->symbols(5), '+{]~\'';
  is $random->symbols(5), '}<[][';
  is $random->symbols(5), '=)<!.';
  is $random->symbols(5), '?.&^@';
  is $random->symbols(5), '(:!**';
  is $random->symbols(5), '{.^",';
  is $random->symbols(5), '^@{].';
  is $random->symbols(5), '<$]](';
  is $random->symbols(5), '(+%$&';
  is $random->symbols(5), ']@[,>';
  is $random->symbols(5), ';**~\\';
  is $random->symbols(5), '_[]&.';
  is $random->symbols(5), ')\\${$';
  is $random->symbols(5), '&<^,\'';
  is $random->symbols(5), '\\,\\&\\';
  is $random->symbols(5), '#>#]\\';
  is $random->symbols(5), '?!:}*';
  is $random->symbols(5), ',}@*}';
  is $random->symbols(5), '_/<*\\';
  is $random->symbols(5), '^.>>}';
  is $random->symbols(5), '[:}$>';
  is $random->symbols(5), '^^=:!';
  is $random->symbols(5), '}-=(+';
  is $random->symbols(5), '~#)@:';
  is $random->symbols(5), '-_*~>';
  is $random->symbols(5), '=:\'<-';
  is $random->symbols(5), '~]<),';
  is $random->symbols(5), '^,?<!';
  is $random->symbols(5), ':%,$}';
  is $random->symbols(5), ';\\&!~';
  is $random->symbols(5), '/>_#:';
  is $random->symbols(5), '{<>><';
  is $random->symbols(5), '}(,@&';
  is $random->symbols(5), '(?++^';
  is $random->symbols(5), '+<##?';
  is $random->symbols(5), ',,+[?';
  is $random->symbols(5), '{[_}~';
  is $random->symbols(5), ';\\>\\)';
  is $random->symbols(5), '%:<]%';
  is $random->symbols(5), '.<;:=';
  is $random->symbols(5), '}[$_-';
  is $random->symbols(5), '[|@<~';
  is $random->symbols(5), '||\'|+';
  is $random->symbols(5), '$"/;-';
  is $random->symbols(5), '+\')!%';
  is $random->symbols(5), ':;[/|';
  is $random->symbols(5), '|#{:$';
  is $random->symbols(5), '=%,;}';

  $result
});

=method token

The token method returns a unique randomly generated L<"md5"|Digest::MD5>
digest.

=signature token

  token() (string)

=metadata token

{
  since => '4.15',
}

=cut

=example-1 token

  # given: synopsis

  package main;

  my $token = $random->token;

  # "86eb5865c3e4a1457fbefcc93e037459"

  # $token = $random->token;

  # "9be02d56ece7efe68bc59d2ebf3c4ed7"

=cut

$test->for('example', 1, 'token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok length($result) > 30;
  like $result, qr/^\w+$/;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;
  isnt +($last = $random->token), $random->token;

  $result
});

=method urlsafe

The urlsafe method returns a unique randomly generated URL-safe string based on
L</base64>.

=signature urlsafe

  urlsafe() (string)

=metadata urlsafe

{
  since => '4.15',
}

=cut

=example-1 urlsafe

  # given: synopsis

  package main;

  my $urlsafe = $random->urlsafe;

  # "WtdsCPBQDKXPv2tcuFbBFcdDtJ6EZRyE3Xke0e65YRQ"

  # $urlsafe = $random->urlsafe;

  # "xXq7Mkwo7nLsFjMW8mvKgdzac5m4X0gFMykO1r0d7GA"

=cut

$test->for('example', 1, 'urlsafe', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok length($result) > 30;
  like $result, qr/^[\w\-]+$/;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;
  isnt +($last = $random->urlsafe), $random->urlsafe;

  $result
});

=method uppercased

The uppercased method returns a random uppercased letter.

=signature uppercased

  uppercased() (string)

=metadata uppercased

{
  since => '1.11',
}

=example-1 uppercased

  # given: synopsis

  package main;

  my $uppercased = $random->uppercased;

  # "T"

  # $uppercased = $random->uppercased;

  # "I"

=cut

$test->for('example', 1, 'uppercased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $random = Venus::Random->new(42);

  is $random->uppercased, "T";
  is $random->uppercased, "I";
  is $random->uppercased, "C";
  is $random->uppercased, "K";
  is $random->uppercased, "C";
  is $random->uppercased, "W";
  is $random->uppercased, "M";
  is $random->uppercased, "M";
  is $random->uppercased, "R";
  is $random->uppercased, "V";
  is $random->uppercased, "M";
  is $random->uppercased, "P";
  is $random->uppercased, "N";
  is $random->uppercased, "A";
  is $random->uppercased, "U";
  is $random->uppercased, "P";
  is $random->uppercased, "X";
  is $random->uppercased, "M";
  is $random->uppercased, "N";
  is $random->uppercased, "M";
  is $random->uppercased, "L";
  is $random->uppercased, "J";
  is $random->uppercased, "X";
  is $random->uppercased, "B";
  is $random->uppercased, "W";
  is $random->uppercased, "Z";
  is $random->uppercased, "W";
  is $random->uppercased, "G";
  is $random->uppercased, "F";
  is $random->uppercased, "C";
  is $random->uppercased, "H";
  is $random->uppercased, "S";
  is $random->uppercased, "B";
  is $random->uppercased, "H";
  is $random->uppercased, "H";
  is $random->uppercased, "O";
  is $random->uppercased, "W";
  is $random->uppercased, "F";
  is $random->uppercased, "U";
  is $random->uppercased, "V";
  is $random->uppercased, "F";
  is $random->uppercased, "C";
  is $random->uppercased, "O";
  is $random->uppercased, "N";
  is $random->uppercased, "W";
  is $random->uppercased, "Y";
  is $random->uppercased, "D";
  is $random->uppercased, "O";
  is $random->uppercased, "N";
  is $random->uppercased, "H";

  $result
});

=method uuid

The uuid method returns a machine-unique randomly generated psuedo UUID string.
B<Note:> The identifier returned attempts to be unique across network devices
but its uniqueness can't be guaranteed.

=signature uuid

  uuid() (string)

=metadata uuid

{
  since => '4.15',
}

=cut

=example-1 uuid

  # given: synopsis

  package main;

  my $uuid = $random->uuid;

  # "0d3eea5f-1826-3d37-e242-72ea44a157fd"

  # $uuid = $random->uuid;

  # "6e179032-c7fe-1dc6-61b8-cebd00fa06a1"

=cut

$test->for('example', 1, 'uuid', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  ok length($result) > 30;
  like $result, qr/^[\w\-]+$/;

  my $random = Venus::Random->new(42);

  my $last;

  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;
  isnt +($last = $random->uuid), $random->uuid;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

SKIP:
$test->render('lib/Venus/Random.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;

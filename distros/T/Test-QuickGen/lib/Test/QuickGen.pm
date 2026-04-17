package Test::QuickGen;

use v5.16;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use Exporter 'import';

our $VERSION = '0.1.2';

our @EXPORT_OK = qw(
  ascii_string alphanumeric_string between id string_of pick nullable words
  utf8_string utf8_sanitized
);
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
  ascii => [qw(ascii_string alphanumeric_string)],
  utf8 => [qw(utf8_string utf8_sanitized)],
  basic => [qw(id between pick nullable)],
);

=head1 NAME

Test::QuickGen - Utilities for generating random test data

=head1 SYNOPSIS

  use Test::QuickGen qw(:all);

  my $id = id();
  my $ascii = ascii_string(10);
  my $alphanum = alphanumeric_string(10);
  my $utf8 = utf8_string(20);
  my $clean = utf8_sanitized(15);

  my $rand = between(1, 100);
  my $opt = nullable("value");
  my $item = pick(qw(a b c));

  my $words = words(\&ascii_string, 5);

=head1 DESCRIPTION

C<Test::QuickGen> provides a set of utility functions for generating random
data, primarily intended for testing purposes. These generators are simple,
fast, and have minimal dependencies.

=head1 COMMAND LINE TOOL

This module comes bundled with an optional test runner, see L<quicktest> for
more details.

=head1 IMPORTING

Nothing is exported by default.

Import functions explicitly:

  use Test::QuickGen qw(id ascii_string);

Import groups of functions using tags:

  use Test::QuickGen qw(:all);
  use Test::QuickGen qw(:ascii);
  use Test::QuickGen qw(:utf8);
  use Test::QuickGen qw(:basic);

=over 4

=item * C<:all>

All available functions.

=item * C<:ascii>

ASCII specific functions.

=item * C<:utf8>

UTF-8 specific functions.

=item * C<:basic>

Simple utils like C<pick> or C<id>.

=back

See source for exact composition of the imports.

=head1 FUNCTIONS

=head2 id

  my $id1 = id();
  my $id2 = id();

  # $id1 != $id2

Returns a monotonically increasing integer starting from 0.

The counter is process-local and resets each time the program runs.

=cut
sub id {
    state $id = 0;
    $id++;
}

=head2 string_of($n, @chars)

  my $str = string_of(10, qw(a b c));

Generates a random string of length C<$n> using the provided list of characters C<@chars>.

=over 4

=item *

C<$n> must be a non-negative integer.

=item *

At least one character must be provided.

=back

=cut
sub string_of {
  my ($n, @chars) = @_;

  croak 'string_of: empty character set' unless @chars;
  
  my $str = '';
  for (1..$n) {
    $str .= $chars[rand @chars];
  }
  $str;
}

=head2 ascii_string($n)

  my $str = ascii_string(10);

Generates a random ASCII string length C<$n>.

The character set includes all visible ASCII symbols and characters (in the
range 33 to 126).

=cut
sub ascii_string {
  my ($n) = @_;
  # all visible ASCII characters
  my @chars = map { chr($_) } 33..126;
  string_of($n, @chars);
}

=head2 alphanumeric_string($n)

  my $str = alphanumeric_string($n);

Generates a random ASCII string of only alphanumericeric characters of
length C<$n>.

=cut
sub alphanumeric_string {
  my ($n) = @_;
  string_of($n, 'a'..'z', 'A'..'Z', '0'..'9');
}

=head2 utf8_string($n)

  my $str = utf8_string(10);

Generates a random UTF-8 string of C<$n> characters.

The generator:

=over 4

=item *

Includes visible Unicode characters up to code point C<0x2FFF>.

=item *

Excludes control characters and invalid Unicode ranges.

=item *

Skips surrogate pairs and non-characters.

=back

Note: Because characters may vary in byte length, this function targets
character count (not byte length).

=cut
sub utf8_string {
  my ($n) = @_;
  my $str = '';
  while (length($str) < $n) {
    # skip non-visible ASCII characters (0x00-0x19)
    # include everything up to 0x2FFF (extended UTF-8)
    my $code_point = between(0x20, 0x2FFF);

    # skip problematic unicode points
    next if ($code_point >= 0xD800 && $code_point <= 0xDFFF); # surrogate pairs
    next if ($code_point >= 0xFDD0 && $code_point <= 0xFDEF); # non characters
    # also non characters
    next if ($code_point % 0x10000 == 0xFFFE || $code_point % 0x10000 == 0xFFFF);
    next if ($code_point >= 0x7F && $code_point <= 0x9F); # control characters

    $str .= chr($code_point);
  }
  $str;
}

=head2 utf8_sanitized($n)

  my $clean = utf8_sanitized(10);

Generates a UTF-8 string of length C<$n> and removes all non-alphanumericeric
characters, retaining only:

=over 4

=item *

Unicode letters (C<\p{L}>)

=item *

Unicode numbers (C<\p{N}>)

=item *

Whitespace

=back

If all characters are filtered out, the function retries until a non-empty
string is produced.

=cut
sub utf8_sanitized {
  my ($n) = @_;
  my $s = utf8_string($n);
  # exit early before stripping if the intended result is an empty string
  return $s if $s eq '';

  $s =~ s/[^\p{L}\p{N}\s]//gu;

  # sometimes all characters get filtered, try again and hope for the best
  if ($s eq '') {
    return utf8_sanitized($n);
  }

  $s;
}

=head2 words($gen, $n, $max_len = 70)

  my $str = words(\&string_generator, 5);

Generates a string made up of C<$n> space-separated "words".

Each word is produced by calling the generator function C<$gen>.

=over 4

=item * C<$gen>

A coderef that is called once per word.

It accepts a single integer argument (the desired length), and returns a string.

For example:

  sub string_generator {
    my ($len) = @_;
    # return a string of length $len
  }

=item * C<$max_len>

An optional parameter to set the maximum length (inclusive) of a word.
Defaults to 70. Must be a positive number.

=item * Word generation

For each of the C<$n> words, a random length between 1 and C<$max_len> is
chosen. That length is passed to C<$gen>, which returns the word.

=item * Output format

The generated words are joined together with a single space.

=back

Example:

  words(\&ascii_string, 3);
  # might return: "aZ3 kLm92 Q"

=cut
sub words {
  my ($gen, $n, $max_len) = @_;

  $max_len //= 70;
  croak '$max_len must be a positive number'
    unless looks_like_number($max_len) && $max_len > 0;

  my @words = map { $gen->(between(1, $max_len)) } (1..$n);
  join ' ', @words;
}

=head2 between($min, $max)

  my $n = between(1, 10);

Returns a random integer between C<$min> and C<$max> (inclusive).

C<$min> must be <= C<$max>.

=cut
sub between {
  my ($min, $max) = @_;
  croak "between: max must be larger or equal to min" if $max < $min;
  $min + int(rand($max - $min + 1));
}

=head2 nullable($val)

  my $value = nullable("data");

Returns either the given value or C<undef>.

25% chance of returning C<undef>, 75% chance of returning the original value.
Useful for testing optional fields.

=cut
sub nullable {
  my ($val) = @_;
  if (rand() < 0.25) {
    undef;
  } else {
    $val;          
  }
}

=head2 pick(@items)

  my $item = pick(qw(a b c));

Returns a random element from the provided list.

If provided an empty list, will return C<undef>.

=cut
sub pick { $_[rand @_] }

=head1 NOTES

=over 4

=item *

These functions are not cryptographically secure.

=item *

Randomness uses the builtin function L<rand|perlfunc/rand>, so all limitations
that apply to that also apply here. Randomness in this module's functions is
uniform in its distribution unless specified otherwise.

=item *

They are intended for testing, fuzzing, and data generation only.

=back

=head1 AUTHOR

Antonis Kalou E<lt>kalouantonis@protonmail.comE<gt>

=head1 CONTRIBUTORS

B<bas080>: L<https://github.com/bas080>

B<Penfold>: Mike Whitaker E<lt>pendfold@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See F<LICENSE> for details.

=cut

1;

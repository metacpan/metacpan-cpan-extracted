package Test::QuickGen;

use v5.16;
use strict;
use warnings;
use Carp qw(croak);
use Exporter 'import';

our $VERSION = '0.1.0';

our @EXPORT_OK = qw(
  ascii_string between id string_of pick nullable words
  utf8_string utf8_sanitized
);
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
  utf8 => [qw(utf8_string utf8_sanitized)],
  basic => [qw(id between pick nullable)],
);

=head1 NAME

Test::QuickGen - Utilities for generating random test data

=head1 SYNOPSIS

  use Test::QuickGen qw(:all);

  my $id = id();
  my $str = ascii_string(10);
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

All functions are exported by default.

=head1 IMPORTING

Nothing is exported by default.

Import functions explicitly:

  use Test::QuickGen qw(id ascii_string);

Import groups of functions using tags:

  use Test::QuickGen qw(:all);
  use Test::QuickGen qw(:utf8);
  use Test::QuickGen qw(:basic);

See source for the exact composition.

=over 4

=item * C<:all>

All available functions.

=item * C<:utf8>

C<utf8_string>, C<utf8_sanitized>.

=item * C<:basic>

C<id>, C<between>, C<pick>, C<nullable>.

=back

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

=head2 string_of

  my $str = string_of(10, qw(a b c));

Generates a random string of length C<$n> using the provided list of characters.

=over 4

=item *

C<$n> must be a non-negative integer.

=item *

At least one character must be provided.

=item *

Characters are selected uniformly at random.

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

=head2 ascii_string

  my $str = ascii_string(10);

Generates a random ASCII string length C<$n>.

The character set includes all lowercase letters (a-z), uppercase letters (A-Z),
digits (0-9) and underscore (_).

=cut

sub ascii_string {
  my ($n) = @_;
  # TODO: include other ASCII characters too
  string_of($n, 'a'..'z', 'A'..'Z', '0'..'9', '_');
}

=head2 utf8_string

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

=head2 utf8_sanitized

  my $clean = utf8_sanitized(10);

Generates a UTF-8 string and removes all non-alphanumeric characters, retaining
only:

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

=head2 words

  my $str = words(\&ascii_string, 5);

Generates a string consisting of C<$n> space-separated "words".

=over 4

=item *

C<$gen> is a coderef that generates a string given a length.

=item *

Each word length is randomly chosen between 1 and 70.

=item *

Words are joined with a single space.

=back

Example:

  words(\&ascii_string, 3);
  # "aZ3 kLm92 Q"

=cut

sub words {
  my ($gen, $n) = @_;
  my @words = map { $gen->(between(1, 70)) } (1..$n);
  join ' ', @words;
}

=head2 between

  my $n = between(1, 10);

Returns a random integer between C<$min> and C<$max> (inclusive).

The distribution is uniform and C<$min> must be <= C<$max>.

=cut

sub between {
  my ($min, $max) = @_;
  croak "between: max must be larger or equal to min" if $max < $min;
  $min + int(rand($max - $min + 1));
}

=head2 nullable

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

=head2 pick

  my $item = pick(qw(a b c));

Returns a random element from the provided list.

If provided an empty list, will return C<undef>. Randomness is uniform in
its distribution.

=cut

sub pick { $_[rand @_] }

=head1 NOTES

=over 4

=item *

These functions are not cryptographically secure.

=item *

They are intended for testing, fuzzing, and data generation only.

=back

=head1 AUTHOR

Antonis Kalou <<kalouantonis@protonmail.com>>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See F<LICENSE> for details.

=cut

1;

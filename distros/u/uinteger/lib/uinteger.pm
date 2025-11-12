package uinteger;
use v5.16.0;
use warnings;
use integer (); # for $integer::hints_bits

our $VERSION = "1.001";

require XSLoader;
XSLoader::load(__PACKAGE__);

sub import {
  # turning "use integer" off means we use the default versions of
  # most bitops, which mostly treat values as UVs (unsigned), while
  # use integer treats then as IVs (signed)
  $^H &= ~$integer::hint_bits;
  $^H{uinteger} = 1;
}

sub unimport {
  $^H{uinteger} = 0;
}

1;

=head1 NAME

uinteger - like "use integer", but unsigned

=head1 SYNOPSIS

  use uinteger;
  print 1 - 2; # print a large number

=head1 DESCRIPTION

Rewrites add, subtract, multiply and unary negation in C<use uinteger>
context to perform the operation as if the number was an unsigned
integer (a Perl C<UV>).

Negative numbers are treated as their 2's complement representation.

Most bitops already treat their arguments as unsigned outside of C<use
integer> so this doesn't need to cover those.

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=cut

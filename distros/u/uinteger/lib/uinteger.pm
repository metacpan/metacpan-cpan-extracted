package uinteger;
use v5.16.0;
use warnings;
use integer (); # for $integer::hints_bits

our $VERSION = "1.000";

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

=head1 PERFORMANCE

The raw OPs are about as fast as under C<use integer;>, but two things
lead to slightly slower performance:

=over

=item *

The target lexical optimization isn't performed for custom ops.
Code like:

  $z = $c + $d;

initially generates an op tree something like:

  sassign
    padtmp = add(stack values)
      padsv($c)
      padsv($d)
    padsv($z)

which, when the target variable is lexical, is then optimized to:

  $z = add(stack values)
    padsv($c)
    padsv($d)

but that optimization isn't done for custom operators.  For code that
does a lot of intermediate stores to lexicals this can make a
significant difference.  This may change.

=item *

SvUV(), the macro used to fetch an unsigned integer from an SV only
directly accesses the value when the value isn't representable as an
IV, ie. when the value is above C<IV_MAX>.

This means that fetching an IV is typically a little faster.

=back

If you want performant unsigned integer (or integer or floating point)
math you should probably be using XS.

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=cut

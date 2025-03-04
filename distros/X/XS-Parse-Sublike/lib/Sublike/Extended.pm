#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk

package Sublike::Extended 0.37;

use v5.14;
use warnings;

use Carp;

# XS code is part of XS::Parse::Sublike
require XS::Parse::Sublike;

=head1 NAME

C<Sublike::Extended> - enable extended features when parsing C<sub>-like syntax

=head1 SYNOPSIS

=for highlighter language=perl

   use v5.26;
   use Sublike::Extended;
   use experimental 'signatures';

   extended sub greet (:$name = "world") {
      say "Hello, $name";
   }

   greet( name => $ENV{USER} );

Or, I<since version 0.29:>

   use v5.26;
   use Sublike::Extended 0.29 'sub';
   use experimental 'signatures';

   sub greet (:$name = "world") {
      say "Hello, $name";
   }

   greet( name => $ENV{USER} );

=head1 DESCRIPTION

This module extends the syntax for declaring named or anonymous subroutines
using Perl's builtin C<sub> keyword, or other similar keywords provided by
third-party modules, to enable parsing of extra features.

By default, this module provides a new keyword, L<C<extended>|/extended>,
which parses the extra syntax required. Optionally I<since version 0.29>, this
module can additionally take over the handling of the C<sub> keyword itself,
allowing this extra syntax to be used without the C<extended> prefix keyword.
As this ability may be surprising to unsuspecting readers, this is not done by
default and must be explicitly requested with the C<sub> import argument:

   use Sublike::Extended 'sub';

On Perl 5.38 or above, this can also take over handling of the C<method>
keyword when using C<feature 'class'>.

   use Sublike::Extended 'method';

Currently, the only extended features that are provided are related to the
parsing of a subroutine signature. Since signatures are only available on Perl
version 5.26 or later, this module is unlikely to be useful in earlier
versions of Perl.

=head2 Named parameters

Extended subroutines can declare named parameters in the signature, after any
positional ones. These take the form of a name prefixed by a colon character.
The caller of such a function should pass values for these parameters by the
usual name-value pair syntax that would be used for passing into a regular
hash. Within the body of the subroutine the values passed into these are
unpacked into regular lexical variables.

   sub colour (:$red, :$green, :$blue) {
      ... # $red, $green and $blue are available as regular lexicals
   }

   # argument order at the caller site is not important
   colour(green => 1, blue => 2, red => 3);

Positional parameters I<can> be placed after optional positional ones, but in
order to make use of them the caller would have to pass a value for every
positional parameter including the optional ones first. This is unlikely to be
very useful; if you want to have optional parameters and named parameters, use
named optional ones after any I<mandatory> positional parameters.

As with positional parameters, they are normally mandatory, but can be made
optional by supplying a defaulting expression. If the caller fails to pass a
value corresponding to an optional parameter, the default expression is
evaluated and used instead.

   sub f (:$x0, :$x1, :$x2 = 0) { ... }
   # The caller must provide x0 and x1, but x2 is optional

I<Since version 0.23> named parameters can be given defaulting expressions
with the C<//=> or C<||=> operators, meaning their defaults apply also if the
caller passed a present-but-undef, or present-but-false value.

   sub f (:$x0, :$x1, :$x2 //= 0) { ... }
   # $x2 will be set to 0 even if the caller passes  x2 => undef

An optional slurpy hash or (I<since version 0.24>) slurpy array is also
permitted after all of these. It will contain the values of any other
name-value pairs given by the caller, after those corresponding to named
parameters have already been extracted.

   sub g (:$alpha, :$beta, %rest) { ... }

   sub g (:$alpha, :$beta, @rest) { ... }

In the case of a slurpy array, it will contain every argument value that was
not consumed as a named parameter pair, in the original order passed by the
caller, including any duplicates.

=head2 Parameter Attributes

Parameters to extended subroutines can use attribute syntax to apply extra
attributes to individual parameters.

   sub info ($x :Attribute) { ... }

Any attributes that are available are ones that have been previously
registered with L<XS::Parse::Sublike> using its XS-level API. The particular
behaviour of such an attribute would be defined by whatever module provided
the attribute.

=head1 KEYWORDS

=head2 extended

   extended sub NAME (SIGNATURE...) { BODY... }

   extended sub (SIGNATURE...) { BODY... };

This prefix keyword enables extra parsing features when handling a C<sub> (or
other sub-like function keyword).

This keyword can be freely mixed with other C<sub>-prefix keywords, such as
C<async> from L<Future::AsyncAwait>

   async extended sub f (:$param) { ... }

This can also be used with other keywords that provide C<sub>-like syntax,
such as C<method> from L<Object::Pad> or the core C<use feature 'class'>.

   extended method f (:$param) { ... }

=cut

sub import
{
   shift;
   $^H{"Sublike::Extended/extended"}++;

   my @rest = grep {
      $_ eq "sub"    ? ( $^H{"Sublike::Extended/extended-sub"}++, 0 ) :
      $_ eq "method" ? ( $^H{"Sublike::Extended/extended-method"}++, 0 ) :
                       1
   } @_;

   croak "Unrecognised import arguments: @rest" if @rest;
}

sub unimport
{
   shift;
   delete $^H{"Sublike::Extended/extended"};

   my @rest = grep {
      $_ eq "sub"    ? ( delete $^H{"Sublike::Extended/extended-sub"}, 0 ) :
      $_ eq "method" ? ( delete $^H{"Sublike::Extended/extended-method"}, 0 ) :
                       1
   } @_;

   croak "Unrecognised unimport arguments: @rest" if @rest;
}

=head1 TODO

=over 4

=item *

Support defined-or and true-or positional parameters even on versions of Perl
before they were officially added (v5.38).

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Sublike::Extended 0.21;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Sublike::Extended> - enable extended features when parsing C<sub>-like syntax

=head1 SYNOPSIS

   use v5.26;
   use Sublike::Extended;
   use experimental 'signatures';

   extended sub greet (:$name = "world") {
      say "Hello, $name";
   }

   greet( name => $ENV{USER} );

=head1 DESCRIPTION

This module extends the syntax for declaring named or anonymous subroutines
using Perl's builtin C<sub> keyword, or other similar keywords provided by
third-party modules, to enable parsing of extra features.

Currently, the only extended features that are provided are related to the
parsing of a subroutine signature. Since signatures are only available on Perl
version 5.26 or later, this module is unlikely to be useful in earlier
versions of Perl.

=head2 Named parameters

Extended subroutines can be declare named parameters in the signature, after
any positional ones. These take the form of a name prefixed by a colon
character. The caller of such a function should pass values for these
parameters by the usual name-value pair syntax that would be used for passing
into a regular hash. Within the body of the subroutine the values passed into
these are unpacked into regular lexical variables.

   extended sub colour (:$red, :$green, :$blue) {
      ... # $red, $green and $blue are available as regular lexicals
   }

   # argument order at the caller site is not important
   colour(green => 1, blue => 2, red => 3);

As with positional parameters, they are normally mandatory, but can be made
optional by supplying a defaulting expression. If the caller fails to pass a
value corresponding to the parameter, the default expression is evaluated and
used instead.

   extended sub f (:$x0, :$x1, :$x2 = 0) { ... }
   # The caller must provide x0 and x1, but x2 is optional

An optional slurpy hash is also permitted after all of these. It will contain
the values of any other name-value pairs given by the caller, after those
corresponding to named parameters have already been extracted.

   extended sub g (:$alpha, :$beta, %rest) { ... }

=head2 Parameter Attributes

Parameters to extended subroutines can use attribute syntax to apply extra
attributes to individual parameters.

   extended sub info ($x :Attribute) { ... }

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
   $^H{"Sublike::Extended/extended"}++;
}

sub unimport
{
   delete $^H{"Sublike::Extended/extended"};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

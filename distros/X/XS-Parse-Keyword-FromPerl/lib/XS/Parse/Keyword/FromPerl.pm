#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk

package XS::Parse::Keyword::FromPerl 0.10;

use v5.26; # XS code needs op_class() and the OPclass_* constants
use warnings;

use meta 0.003_002;
no warnings 'meta::experimental';

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<XS::Parse::Keyword::FromPerl> - drive C<XS::Parse::Keyword> directly from Perl

=head1 DESCRIPTION

This module provides a Perl-visible API wrapping (some of) the functionality
provided by L<XS::Parse::Keyword>, allowing extension keywords to be added to
the Perl language by writing code in Perl itself.

It provides a thin wrapping layer over the XS functions provided by XPK
itself. No real attempt is made here to provide further abstractions on top of
the API already provided by Perl and XPK, so users will have to be familiar
with the overall concepts there as well.

This module is currently experimental, on top of the already-experimental
nature of C<XS::Parse::Keyword> itself.

=cut

use Exporter 'import';
push our @EXPORT_OK, qw(
   register_xs_parse_keyword
);

# Most of the optree stuff is imported from Optree::Generate
require Optree::Generate;
foreach my $sym (qw(
   opcode
   op_contextualize
   op_scope
   newOP
   newASSIGNOP
   newBINOP
   newCONDOP
   newFOROP
   newGVOP
   newLISTOP
   newLOGOP
   newPADxVOP
   newSVOP
   newUNOP
   G_VOID G_SCALAR G_LIST
   OPf_WANT OPf_WANT_VOID OPf_WANT_SCALAR OPf_WANT_LIST
   OPf_KIDS
   OPf_PARENS
   OPf_REF
   OPf_MOD
   OPf_STACKED
   OPf_SPECIAL
)) {
   Optree::Generate->import( $sym );
   push @EXPORT_OK, $sym;
}

=head1 OPTREE FUNCTIONS

The L<Optree::Generate> module contains a selection of helper functions to
allow Perl code to get access to various parts of the C-level API that would
be useful when building optrees for keywords. They used to be part of this
module, and so are currently re-exported for convenience, but a later version
of this module may start emitting warnings when they are used this way, and
eventually that may stop being provided at all.

Code needing these should import them directly:

   use Optree::Generate qw( opcode newUNOP ... );

=head1 XPK FUNCTIONS

=head2 register_xs_parse_keyword

   register_xs_parse_keyword "name" => %args;

Registers a new extension keyword into the C<XS::Parse::Keyword> registry,
defined using the given name and arguments.

Takes the following named arguments:

=over 4

=item flags => INT

Optional. If present, a bitmask of the following flag constants:

=over 4

=item XPK_FLAG_EXPR

The build phase is expected to return C<KEYWORD_PLUGIN_EXPR>.

=item XPK_FLAG_STMT

The build phase is expected to return C<KEYWORD_PLUGIN_STMT>.

=item XPK_FLAG_AUTOSEMI

The syntax forms a complete statement, which should be followed by C<;>.

=back

=item pieces => ARRAY

Optional. If present, contains definitions for the syntax pieces to be parsed
for the syntax of this keyword. This must be composed of a list of calls to
the various C<XPK_...> piece-generating functions; documented below.

=item permit_hintkey => STRING

Optional. A string value to use for the "permit_hintkey".

=item permit => CODE

Optional. Callback function for the "permit" phase of keyword parsing.

   $ok = $permit->( $hookdata );

When invoked, it is passed a single arugment containing the (optional)
hookdata value, and its result should be a boolean scalar.

At least one of C<permit_hintkey> or C<permit> must be provided.

=item check => CODE

Optional. Callback function for the "check" phase of keyword parsing.

   $check->( $hookdata );

When invoked, it is passsed a single argument containing the (optional)
bookdata value.

=item build => CODE

Callback function for the "build" phase of keyword parsing.

   $ret = $build->( \$out, \@args, $hookdata );

When invoked, it is passed a SCALAR ref to store the output optree into, an
ARRAY reference containing the parsed arguments, and the (optional) hookdata
value.

The C<@args> array will contain object references referring to the individual
arguments parsed by the parser pieces. See L</Parser Arguments>.

The callback function should be build an optree as a C<B::OP> fragment,
possibly by calling the various C<new*OP()> functions defined above, and store
the eventual result into the scalar referred to by the first argument.

The callback should return one of C<KEYWORD_PLUGIN_EXPR> or
C<KEYWORD_PLUGIN_STMT> to indicate how its syntax should be interpreted by the
perl parser.

=item hookdata => SCALAR

Optional. If present, this scalar value is stored by the keyword definition
and passed into each of the phase callbacks when invoked. If not present then
C<undef> will be passed to the callbacks instead.

=back

=cut

=head2 Piece Type Functions

The following functions can be used to generate parsing pieces.

Many simple piece types have an variant which is optional; if the input source
does not look like the expected syntax for the piece type then it will emit
C<undef> rather than raise an error. These piece types have their names
suffixed by C<_OPT>.

=head3 XPK_BLOCK

A block of code, returned in the I<op> field.

=head3 XPK_ANONSUB

An anonymous subroutine, returned in the I<cv> field.

=head3 XPK_ARITHEXPR, XPK_ARITHEXPR_OPT

An arithemetic expression, returned in the I<op> field.

=head3 XPK_TERMEXPR, XPK_TERMEXPR_OPT

A term expression, returned in the I<op> field.

=head3 XPK_LISTEXPR, XPK_LISTEXPR_OPT

A list expression, returned in the I<op> field.

=head3 XPK_IDENT, XPK_IDENT_OPT

An identifier, returned as a string in the I<sv> field.

=head3 XPK_PACKAGENAME, XPK_PACKAGENAME_OPT

A package name, returned as a string in the I<sv> field.

=head3 XPK_LEXVARNAME

   XPK_LEXVARNAME($kind)

A lexical variable name, returned as a string in the I<sv> field.

The C<$kind> must be a bitmask of C<XPK_LEXVAR_SCALAR>, C<XPK_LEXVAR_ARRAY>,
C<XPK_LEXVAR_HASH>; or C<XPK_LEXVAR_ANY> for convenience to set all three.

=head3 XPK_VSTRING, XPK_VSTRING_OPT

A version string, returned as a L<version> object instance in the I<sv> field.

=head3 XPK_LEXVAR

   XPK_LEXVAR($kind)

A lexical variable that already exists in the pad, returned as a pad offset in
the I<padix> field.

C<$kind> is specified as in C<XPK_LEXVARNAME>.

=head3 XPK_LEXVAR_MY

   XPK_LEXVAR_MY($kind)

A lexical variable, parsed as if it appeared in a C<my> expression. It will be
added to the pad and returned as a pad offset in the I<padix> field.

=head3 XPK_COMMA

=head3 XPK_COLON

=head3 XPK_EQUALS

A literal comma, colon or equals sign. These do not appear in the arguments
list.

=head3 XPK_LITERAL

   XPK_LISTEXPR($string)

A literal string match. No value is returned.

This should be avoided if at all possible, in favour of the character matches
above, or C<XPK_KEYWORD>.

=head3 XPK_KEYWORD

   XPK_KEYWORD($string)

A literal string match, which requires that the following text does not begin
with an identifier character (thus avoiding prefix-match problems). No value
is returned.

=head3 XPK_INTRO_MY

Calls the perl C<intro_my()> function immediately. No input is consumed and no
output value is generated.

=head3 XPK_WARNING

   XPK_WARNING($message)

Emits a warning by callling the core perl C<warn()> function immediately.

=head3 XPK_WARNING_...

   XPK_WARNING_AMBIGUOUS($message)
   XPK_WARNING_DEPRECATED($message)
   XPK_WARNING_EXPERIMENTAL($message)
   XPK_WARNING_PRECEDENCE($message)
   XPK_WARNING_SYNTAX($message)

Several variants of L</XPK_WARNING> that are conditional on various warning
categories being enabled.

=head3 XPK_SEQUENCE

   XPK_SEQUENCE(@pieces)

A sub-sequence. Normally this is not necessary, as most of the
structure-forming functions already take a sequence of pieces. It is mostly
useful as as an option to the C<XPK_CHOICE> function.

Nothing extra is returned, beyond the values from the individual pieces.

=head3 XPK_OPTIONAL

   XPK_OPTIONAL(@pieces)

An optional sequence of pieces that may or may not be present. Returns an
integer value in the I<i> field of 0 if the sequence was not found, or 1
followed by its values if the sequence was found.

=head3 XPK_REPEATED

   XPK_REPEATED(@pieces)

A repeating sequence of pieces. Returns an integer value in the I<i> field
indicating how many times the sequence repeated, followed by all the values
returned by each.

=head3 XPK_CHOICE

   XPK_CHOICE(@pieces)

The pieces of this function are not interpreted as a sequence, but instead
as a list of possible choices. Returns an integer value in the I<i> field
indicating which choice was found, followed by all the values returned by
that sequence.

The first possible choice is numbered C<0>. If no choice matched, it returns
C<-1>. To cause an error instead, use L<XPK_FAILURE>.

=head3 XPK_FAILURE

   XPK_FAILURE($message)

Attempting to parse this piece type will immediately cause a compile-time
failure with the given message. This can be used as the final option in
C<XPK_CHOICE> to ensure a valid match.

=head3 XPK_PARENS

   XPK_PARENS(@pieces)

Expects to find a sequence of pieces, all surrounded by parentheses (round
brackets, C<( ... )>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=head3 XPK_ARGS

   XPK_ARGS(@pieces)

A container similar to C<XPK_PARENS> except that the parentheses themselves
are optional, similar to perl's parsing of calls to known functions.

=head3 XPK_BRACKETS

   XPK_BRACKETS(@pieces)

Expects to find a sequence of pieces, all surrounded by square brackets
(C<[ ... ]>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=head3 XPK_BRACES

   XPK_BRACES(@pieces)

Expects to find a sequence of pieces, all surrounded by braces (C<{ ... }>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=head3 XPK_CHEVRONS

   XPK_CHEVRONS(@pieces)

Expects to find a sequence of pieces, all surrounded by chevrons (angle
brackets, C<< < ... > >>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=cut

my $thispkg = meta::get_this_package();

# Simple pieces
foreach (qw(
      BLOCK ANONSUB ARITHEXPR TERMEXPR LISTEXPR IDENT IDENT_OPT
      PACKAGENAME PACKAGENAME_OPT VSTRING VSTRING_OPT COMMA COLON EQUALS
   )) {
   my $name = "XPK_$_";
   push @EXPORT_OK, $name;
   $thispkg->add_symbol( "\&$name" => sub {
      bless [$name], "XS::Parse::Keyword::FromPerl::_Piece";
   } );
}
# Single-SV parametric pieces
foreach (qw(
      LEXVARNAME LEXVAR LEXVAR_MY LITERAL KEYWORD FAILURE WARNING
   )) {
   my $name = "XPK_$_";
   push @EXPORT_OK, $name;
   $thispkg->add_symbol( "\&$name" => sub {
      bless [$name, $_[0]], "XS::Parse::Keyword::FromPerl::_Piece";
   } );
}
# Structural multiple-value pieces
foreach (qw(
      SEQUENCE OPTIONAL REPEATED CHOICE
      PARENS ARGS BRACKETS BRACES CHEVRONS
   )) {
   my $name = "XPK_$_";
   push @EXPORT_OK, $name;
   $thispkg->add_symbol( "\&$name" => sub {
      bless [$name, [@_]], "XS::Parse::Keyword::FromPerl::_Piece";
   } );
}

# Back-compat wrappers for the old names
foreach (qw( PAREN ARG BRACKET BRACE CHEVRON )) {
   my $macroname = "XPK_${_}S";
   my $funcname  = "XPK_${_}SCOPE";
   push @EXPORT_OK, $funcname;
   $thispkg->add_symbol( "\&$funcname" => sub {
      warnings::warnif deprecated => "$funcname is now deprecated; use $macroname instead";
      bless [$macroname, [@_]], "XS::Parse::Keyword::FromPerl::_Piece";
   } );
}

=head2 Parser Arguments

Each of the values given in the C<@args> array for the "build" phase callback
are given as object references having the following methods

=head3 op

   $op = $arg->op;

Returns an optree.

=head3 cv

   $cv = $arg->cv;

Returns a CV wrapped in a CODE reference.

=head3 sv

   $sv = $arg->sv;

Returns the SV itself, or C<undef> if the optional SV was absent.

=head3 has_sv

   $ok = $arg->has_sv;

Returns true if the optional SV was present (even if it was C<undef>), or
false if it was absent.

=head3 i

   $i = $arg->i;

Returns an integer.

=head3 padix

   $padix = $arg->padix;

Returns a pad offset index as an integer.

=head3 line

   $line = $arg->line;

Returns the line number of the source text on which the piece was started.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

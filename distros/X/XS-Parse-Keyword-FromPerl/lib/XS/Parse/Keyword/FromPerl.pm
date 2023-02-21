#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package XS::Parse::Keyword::FromPerl 0.03;

use v5.26; # XS code needs op_class() and the OPclass_* constants
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<XS::Parse::Keyword::FromPerl> - drive C<XS::Parse::Keyword> directly from Perl

=head1 DESCRIPTION

This module provides a Perl-visible API wrapping (some of) the functionality
provided by L<XS::Parse::Keyword>, allowing extension keywords to be added to
the Perl language by writing code in Perl itself.

It provides a thin wrapping later over the XS functions provided by XPK
itself, and additionally provides some extra perl-visible functions for things
like optree management, which would normally be written directly in C code. No
real attempt is made here to provide further abstractions on top of the API
already provided by Perl and XPK, so users will have to be familiar with the
overall concepts there as well.

This module is currently experimental, on top of the already-experimental
nature of C<XS::Parse::Keyword> itself.

=cut

require B; # for the B::OP classes

use Exporter 'import';
push our @EXPORT_OK, qw(
   opcode
   newOP
   newBINOP
   newFOROP
   newGVOP
   newLISTOP
   newLOGOP
   newPADxVOP
   newSVOP
   newUNOP

   register_xs_parse_keyword
);

=head1 UTILITY FUNCTIONS

The following helper functions are provided to allow Perl code to get access
to various parts of the C-level API that would be useful when building optrees
for keywords. They are not part of the C<XS::Parse::Keyword> API.

=head2 opcode

   $type = opcode( $opname );

Returns an opcode integer corresponding to the given op name, which should be
lowercase and without the leading C<OP_...> prefix. As this involves a linear
search across the entire C<PL_op_name> array you may wish to perform this just 
once and store the result, perhaps using C<use constant> for convenience.

   use constant OP_CONST => opcode("const");

=head2 new*OP

This family of functions return a new OP of the given class, for the type,
flags, and other arguments specified.

A suitable C<$type> can be obtained by using the L</opcode> function.

C<$flags> contains the opflags; a bitmask of the following constants.

   OPf_WANT OPf_WANT_VOID OPf_WANT_SCALAR OPf_WANT_LIST
   OPf_KIDS
   OPf_PARENS
   OPf_REF
   OPf_MOD
   OPf_STACKED
   OPf_SPECIAL

The op is returned as a C<B::OP> instance or a subclass thereof.

These functions can only be called during the C<build> phase of a keyword
hook, because they depend on having the correct context set by the
currently-compiling function.

=head3 newOP

   $op = newOP( $type, $flags );

Returns a new base OP for the given type and flags.

=head3 newBINOP

   $op = newBINOP( $type, $flags, $first, $last );

Returns a new BINOP for the given type, flags, and first and last OP child.

=head3 newFOROP

   $op = newFOROP( $flags, %svop, $expr, $block, $cont );

Returns a new optree representing a heavyweight C<for> loop, given the
optional iterator SV op, the list expression, the block, and the optional
continue block, all as OP instances.

=head3 newGVOP

   $op = newGVOP( $type, $flags, $gvref );

Returns a new SVOP for the given type, flags, and GV given by a GLOB
reference. The referred-to GLOB will be stored in the SVOP itself.

=head3 newLISTOP

   $op = newLISTOP( $type, $flags, @children );

Returns a new LISTOP for the given type, flags, and child SVs.

Note that an arbitrary number of child SVs can be passed here. This wrapper
function will automatically perform the C<op_convert_list> conversion from a
plain C<OP_LIST> if required.

=head3 newLOGOP

   $op = newLOGOP( $type, $flags, $first, $other );

Returns a new LOGOP for the given type, flags, and first and other OP child.

=head3 newPADxVOP

   $op = newPADxVOP( $type, $flags, $padoffset );

Returns a new op for the given type, flags, and pad offset. C<$type> must be
one of C<OP_PADSV>, C<OP_PADAV>, C<OP_PADHV> or C<OP_PADCV>.

=head3 newSVOP

   $op = newSVOP( $type, $flags, $sv );

Returns a new SVOP for the given type, flags, and SV. A copy of the given
scalar will be stored in the SVOP itself.

=head3 newUNOP

   $op = newUNOP( $type, $flags, $first );

Returns a new UNOP for the given type, flags, and first OP child.

=cut

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

=head3 XPK_BLOCK

A block of code, returned in the I<op> field.

=head3 XPK_ANONSUB

An anonymous subroutine, returned in the I<cv> field.

=head3 XPK_ARITHEXPR

An arithemetic expression, returned in the I<op> field.

=head3 XPK_TERMEXPR

A term expression, returned in the I<op> field.

=head3 XPK_LISTEXPR

A list expression, returned in the I<op> field.

=head3 XPK_IDENT, XPK_IDENT_OPT

An identifier, returned as a string in the I<sv> field.

The C<_OPT> variant is optional.

=head3 XPK_PACKAGENAME, XPK_PACKAGENAME_OPT

A package name, returned as a string in the I<sv> field.

The C<_OPT> variant is optional.

=head3 XPK_LEXVARNAME

   XPK_LEXVARNAME($kind)

A lexical variable name, returned as a string in the I<sv> field.

The C<$kind> must be a bitmask of C<XPK_LEXVAR_SCALAR>, C<XPK_LEXVAR_ARRAY>,
C<XPK_LEXVAR_HASH>; or C<XPK_LEXVAR_ANY> for convenience to set all three.

=head3 XPK_VSTRING, XPK_VSTRING_OPT

A version string, returned as a L<version> object instance in the I<sv> field.

The C<_OPT> variant is optional.

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

=head3 XPK_PARENSCOPE

   XPK_PARENSCOPE(@pieces)

Expects to find a sequence of pieces, all surrounded by parentheses (round
brackets, C<( ... )>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=head3 XPK_ARGSCOPE

   XPK_ARGSCOPE(@pieces)

A scope similar to C<XPK_PARENSCOPE> except that the parentheses themselves
are optional, similar to perl's parsing of calls to known functions.

=head3 XPK_BRACKETSCOPE

   XPK_BRACKETSCOPE(@pieces)

Expects to find a sequence of pieces, all surrounded by square brackets
(C<[ ... ]>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=head3 XPK_BRACESCOPE

   XPK_BRACESCOPE(@pieces)

Expects to find a sequence of pieces, all surrounded by braces (C<{ ... }>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=head3 XPK_CHEVRONSCOPE

   XPK_CHEVRONSCOPE(@pieces)

Expects to find a sequence of pieces, all surrounded by chevrons (angle
brackets, C<< < ... > >>).

Nothing extra is returned, beyond the values from the individual contained
pieces.

=cut

# Simple pieces
foreach (qw(
      BLOCK ANONSUB ARITHEXPR TERMEXPR LISTEXPR IDENT IDENT_OPT
      PACKAGENAME PACKAGENAME_OPT VSTRING VSTRING_OPT COMMA COLON EQUALS
   )) {
   my $name = "XPK_$_";
   push @EXPORT_OK, $name;

   no strict 'refs';
   *$name = sub { bless [$name], "XS::Parse::Keyword::FromPerl::_Piece" };
}
# Single-SV parametric pieces
foreach (qw(
      LEXVARNAME LEXVAR LEXVAR_MY LITERAL KEYWORD FAILURE
   )) {
   my $name = "XPK_$_";
   push @EXPORT_OK, $name;

   no strict 'refs';
   *$name = sub { bless [$name, $_[0]], "XS::Parse::Keyword::FromPerl::_Piece" };
}
# Structural multiple-value pieces
foreach (qw(
      SEQUENCE OPTIONAL REPEATED CHOICE
      PARENSCOPE ARGSCOPE BRACKETSCOPE BRACESCOPE CHEVRONSCOPE
   )) {
   my $name = "XPK_$_";
   push @EXPORT_OK, $name;

   no strict 'refs';
   *$name = sub { bless [$name, [@_]], "XS::Parse::Keyword::FromPerl::_Piece" };
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

=head1 TODO

=over 4

=item *

Non-trivial C<pieces> for parsing. Pieces that are structural and consume
other pieces (OPTIONAL, SEQ, etc..)

=item *

More C<new*OP()> wrapper functions.

=item *

More optree-mangling functions. At least, some way to set the TARG might be
handy.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

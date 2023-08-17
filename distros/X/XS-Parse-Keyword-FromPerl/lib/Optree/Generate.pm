#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Optree::Generate 0.07;

use v5.26; # XS code needs op_class() and the OPclass_* constants
use warnings;

BEGIN {
   require XSLoader;
   XSLoader::load( __PACKAGE__, our $VERSION );
}

BEGIN {
   if( $^V ge v5.36 ) {
      warnings->unimport(qw( experimental::builtin ));
      builtin->import(qw( blessed reftype ));
   }
   else {
      require Scalar::Util;
      Scalar::Util->import(qw( blessed reftype ));
   }
}

require B; # for the B::OP classes

use Exporter 'import';
push our @EXPORT_OK, qw(
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
   make_entersub_op
);

=head1 NAME

C<Optree::Generate> - helper functions for creating optree fragments from Perl

=head1 DESCRIPTION

This module provides helper functions to allow Perl code to get access to
various parts of the C-level API that would be useful when building optrees,
such as when parsing and implementing code behind custom keywords. It is
mostly intended for use with L<XS::Parse::Keyword::FromPerl> and
L<XS::Parse::Infix::FromPerl>.

=cut

=head1 FUNCTIONS

=head2 opcode

   $type = opcode( $opname );

Returns an opcode integer corresponding to the given op name, which should be
lowercase and without the leading C<OP_...> prefix. As this involves a linear
search across the entire C<PL_op_name> array you may wish to perform this just 
once and store the result, perhaps using C<use constant> for convenience.

   use constant OP_CONST => opcode("const");

=head2 op_contextualize

   $op = op_contextualize( $op, $context );

Applies a syntactic context to an optree representing an expression.
C<$context> must be one of the exported constants C<G_VOID>, C<G_SCALAR>, or
C<G_LIST>.

=head2 op_scope

   $op = op_scope( $op );

Wraps an optree with some additional ops so that a runtime dynamic scope will
created.

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

These functions can only be called during the compilation time of a perl
subroutine. This is unlikely to be happening most of the time, except during
the C<build> phase of a keyword registered using C<XS::Parse::Keyword> or the
C<new_op> phase of an infix operator registered using C<XS::Parse::Infix>.

=head3 newOP

   $op = newOP( $type, $flags );

Returns a new base OP for the given type and flags.

=head3 newASSIGNOP

   $op = newASSIGNOP( $flags, $left, $optype, $right );

Returns a new op representing an assignment operation from the right to the
left OP child of the given type. Note the odd order of arguments.

=head3 newBINOP

   $op = newBINOP( $type, $flags, $first, $last );

Returns a new BINOP for the given type, flags, and first and last OP child.

=head3 newCONDOP

   $op = newCONDOP( $flags, $first, $trueop, $falseop );

Returns a new conditional expression op for the given condition expression and
true and false alternatives, all as OP instances.

=head3 newFOROP

   $op = newFOROP( $flags, $svop, $expr, $block, $cont );

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

=head2 make_entersub_op

   $op = make_entersub_op( $cv, $argops, ... );

A handy wrapper function around calling C<newLISTOP> to create an
C<OP_ENTERSUB> op that will invoke a code reference (which may be known at
compiletime), with a given list of argument-generating optree framents. This
in effect creates a function call.

I<$cv> must be one of:

=over 2

=item *

An optree fragment as a C<B::OP> instance, which will be invoked directly to
yield the required CV

=item *

A CODE reference, which will be stored in a C<OP_CONST>

=item *

A plain string, which will be used to look up a GLOB in the symbol table and
stored as a C<OP_GV> + C<OP_RV2CV> pair.

=back

I<$argops> should be an ARRAY reference containing optree fragments that
generate the arguments to the function.

Takes the following additional optional named arguments:

=over 4

=item flags => INT

Additional flags to set on the returned C<OP_ENTERSUB>. The C<OPf_STACKED>
flag will always be set.

=back

=cut

use constant {
   OP_CONST    => opcode("const"),
   OP_ENTERSUB => opcode("entersub"),
   OP_GV       => opcode("gv"),
   OP_RV2CV    => opcode("rv2cv"),
};

sub make_entersub_op
{
   my ( $cv, $argops, %args ) = @_;

   my $cvop;
   if( blessed $cv and $cv->isa( "B::OP" ) ) {
      $cvop = $cv;
   }
   elsif( ( reftype $cv // "" ) eq "CODE" ) {
      $cvop = newSVOP(OP_CONST, 0, $cv);
   }
   else {
      my $gv = do { no strict 'refs'; \*$cv };
      $cvop = newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, $gv));
   }

   my $flags = $args{flags} // 0;
   return newLISTOP(OP_ENTERSUB, $flags | OPf_STACKED, @$argops, $cvop);
}

=head1 TODO

=over 4

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

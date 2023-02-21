#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

package XS::Parse::Infix 0.33;

use v5.14;
use warnings;

# No actual .xs file; the code is implemented in XS::Parse::Keyword
require XS::Parse::Keyword;

=head1 NAME

C<XS::Parse::Infix> - XS functions to assist in parsing infix operators

=head1 DESCRIPTION

This module provides some XS functions to assist in writing syntax modules
that provide new infix operators as perl syntax, primarily for authors of
syntax plugins. It is unlikely to be of much use to anyone else; and highly
unlikely to be of any use when writing perl code using these. Unless you are
writing a syntax plugin using XS, this module is not for you.

This module is also currently experimental, and the design is still evolving
and subject to change. Later versions may break ABI compatibility, requiring
changes or at least a rebuild of any module that depends on it.

In addition, the places this functionality can be used are relatively small.
No current release of perl actually supports custom infix operators, though it
has now been merged to C<blead>, the main development branch, and will be
present in development release C<v5.37.7> onwards.

In addition, the various C<XPK_INFIX_*> token types of L<XS::Parse::Keyword>
support querying on this module, so some syntax provided by other modules may
be able to make use of these new infix operators.

=cut

=head1 CONSTANTS

=head2 HAVE_PL_INFIX_PLUGIN

   if( XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN ) { ... }

This constant is true if built on a perl that supports the C<PL_infix_plugin>
extension mechanism, meaning that custom infix operators registered with this
module will actually be recognised by the perl parser.

No actual production releases of perl yet support this feature, but see above
for details of development versions which do.

=cut

=head1 XS FUNCTIONS

=head2 boot_xs_parse_infix

  void boot_xs_parse_infix(double ver);

Call this function from your C<BOOT> section in order to initialise the module
and parsing hooks.

I<ver> should either be 0 or a decimal number for the module version
requirement; e.g.

   boot_xs_parse_infix(0.14);

=head2 parse_infix

   bool parse_infix(enum XSParseInfixSelection select, struct XSParseInfixInfo **infop);

I<Since version 0.27.>

This function attempts to parse syntax for an infix operator from the current
parser position. If it is successful, it fills in the variable pointed to by
I<infop> with a pointer to the actual information structure and returns
C<true>. If no suitable operator is found, returns C<false>.

=head2 xs_parse_infix_new_op

   OP *xs_parse_infix_new_op(const struct XSParseInfixInfo *info, U32 flags,
      OP *lhs, OP *rhs);

This function constructs a new optree fragment to represent invoking the infix
operator with the given operands. It should be used much the same as core
perl's C<newBINOP> function.

The C<info> structure pointer would be obtained from the C<infix> field of the
result of invoking the various C<XPK_INFIX_*> token types from
C<XS::Parse::Keyword>, or by calling L</parse_infix> directly.

=head2 register_xs_parse_infix

   void register_xs_parse_infix(const char *opname,
      const struct XSParseInfixHooks *hooks, void *hookdata);

This function installs a set of parsing hooks to be associated with the given
operator name. This new operator will then be available via
L<XS::Parse::Keyword> by the various C<XPK_INFIX_*> token types,
L</parse_infix>, or to core perl's C<PL_infix_plugin> if available.

These tokens will all yield an info structure, with the following fields:

   struct XSParseInfixInfo {
      const char *opname;
      OPCODE opcode;  /* for built-in operators, or OP_CUSTOM for 
                         custom-registered ones */

      struct XSParseInfixHooks *hooks;
      void                     *hookdata;

      enum XSParseInfixClassification cls;  /* since version 0.28 */
   };

If the operator name contains any non-ASCII characters they are presumed to be
in UTF-8 encoding. This will matter for deparse purposes.

=cut

=head1 PARSE HOOKS

The C<XSParseInfixHooks> structure provides the following fields which are
used at various stages of parsing.

   struct XSParseInfixHooks {
      U16 flags; /* currently ignored */
      U8 lhs_flags;
      U8 rhs_flags;
      enum XSParseInfixClassification cls;

      const char *wrapper_func_name;

      const char *permit_hintkey;
      bool (*permit)(pTHX_ void *hookdata);

      OP *(*new_op)(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata);
      OP *(*ppaddr)(pTHX);

      /* optional */
      void (*parse)(pTHX_ U32 flags, SV **parsedata, void *hookdata);
   };

=head2 Flags

The C<flags> field is currently ignored. It is defined simply to reserve the
space in case used in a later version. It should be set to zero.

The C<lhs_flags> and C<rhs_flags> fields give details on how to handle the
left- and right-hand side operands, respectively.

It should be set to one of the following constants, or left as zero:

=over 4

=item XPI_OPERAND_TERM_LIST

The operand will be foced into list context, preserving the C<OP_PUSHMARK> at
the beginning. This means that the ppfunc for this infix operator will have to
C<POPMARK> to find that.

=item XPI_OPERAND_LIST

The same as above.

=back

Older versions used to provide constants named C<XPI_OPERAND_ARITH> and
C<XPI_OPERAND_TERM> but they related to an older version of the core perl
branch. These names are now aliases for zero, and can be removed from new
code.

In addition the following extra bitflags are defined:

=over 4

=item XPI_OPERAND_ONLY_LOOK

If set, the operator function promises that it will not mutate any of its
passed values, nor allow leaking of direct alias pointers to them via return
value or other locations.

This flag is optional; omitting it when applicable will not change any
observed behaviour. Setting it may enable certain optimisations to be
performed.

Currently, this flag simply enables an optimisation in the call-checker for
infix operator wrapper functions that take list-shaped operands. This
optimisation discards an C<OP_ANONLIST> operation which would create a
temporary anonymous array reference for its operand values, allowing a slight
saving of memory use and CPU time. This optimisation is only safe to perform
if the operator does not mutate or retain aliases of any of the arguments, as
otherwise the caller might see unexpected modifications or value references to
the values passed.

=back

=head2 The Selection Stage

The C<cls> field gives a "classification" of the operator, suggesting what
sort of operation it provides. This is used as a filter by the various
C<XS::Parse::Keyword> selection macros.

The classification should be one of the C<XPI_CLS_*> constants found and
described further in the main F<XSParseInfix.h> file.

=head2 The C<permit> Stage

As a shortcut for the common case, the C<permit_hintkey> may point to a string
to look up from the hints hash. If the given key name is not found in the
hints hash then the keyword is not permitted. If the key is present then the
C<permit> function is invoked as normal.

If not rejected by a hint key that was not found in the hints hash, the
function part of the stage is called next and should inspect whether the
keyword is permitted at this time perhaps by inspecting other lexical clues,
and return true only if the keyword is permitted.

Both the string and the function are optional. Either or both may be present.
If neither is present then the keyword is always permitted - which is likely
not what you wanted to do.

=head2 The C<parse> Stage

If the optional C<parse> hook function is present, it is called immediately
after the parser has recognised the presence of the named operator itself but
before it attempts to consume the right-hand side term. This hook function can
attempt further parsing, in order to implement more complex syntax such as
hyper-operators.

When invoked, it is passed a pointer to an C<SV *>-typed storage variable. It
is free to use this variable it desires to store a result, which will then
later be made available to the C<new_op> function.

=head2 The Op Generation Stage

If the infix operator is going to be used, then one of the C<new_op> or the
C<ppaddr> fields explain how to create a new optree fragment.

If C<new_op> is defined then it will be used, and is expected to return an
optree fragment that consumes the LHS and RHS arguments to implement the
semantics of the operator. If the optional C<parse> stage had been present
earlier, the C<SV **> pointer passed here will point to the same storage that
C<parse> had previously had access to, so it can retrieve the results.

If C<new_op> is not present, then the C<ppaddr> will be used instead to
construct a new BINOP of the C<OP_CUSTOM> type. If an earlier C<parse> stage
had stored additional results into the C<SV *> variable these will be lost
here.

=head2 The Wrapper Function

Additionally, if the C<wrapper_func_name> field is set to a string, this gives
the (fully-qualified) name for a function to be generated as part of
registering the operator. This newly-generated function will act as a wrapper
for the operator.

For operators whose RHS is a scalar, the wrapper function is assumed to take
two simple scalar arguments. The result of invoking the function on those
arguments will be determined by using the operator code.

   $result = $lhs OP $rhs;

   $result = WRAPPERFUNC( $lhs, $rhs );

For operators whose RHS is a list, the wrapper function takes at least one
argument, possibly more. The first argument is the scalar on the LHS, and the
remaining arguments, however many there are, form the RHS:

   $result = $lhs OP @rhs;

   $result = WRAPPERFUNC( $lhs, @rhs );

For operators whose LHS and RHS is a list, the wrapper function takes two
arguments which must be array references containing the lists.

   $result = @lhs OP @rhs;

   $result = WRAPPERFUNC( \@lhs, \@rhs );

This creates a convenience for accessing the operator from perls that do not
support C<PL_infix_plugin>.

In the case of scalar infix operators, the wrapper function also includes a
call-checker which attempts to inline the operator directly into the callsite.
Thus, in simple cases where the function is called directly on exactly two
scalar arguments (such as in the following), no C<ENTERSUB> overhead will be
incurred and the generated optree will be identical to that which would have
been generated by using infix operator syntax directly:

   WRAPPERFUNC( $lhs, $rhs );
   WRAPPERFUNC( $lhs, CONSTANT );
   WRAPPERFUNC( $args[0], $args[1] );
   WRAPPERFUNC( $lhs, scalar otherfunc() );

The checker is very pessimistic and will only rewrite callsites where it
determines this can be done safely. It will not rewrite any of the following
forms:

   WRAPPERFUNC( $onearg );            # not enough args
   WRAPPERFUNC( $x, $y, $z );         # too many args
   WRAPPERFUNC( @args[0,1] );         # not a scalar
   WRAPPERFUNC( $lhs, otherfunc() );  # not a scalar

The wrapper function for infix operators which take lists on both sides also
has a call-checker which will attempt to inline the operator in similar
circumstances. In addition to the optimisations described above for scalar
operators, this checker will also inline an array-reference operator and omit
the resulting dereference behaviour. Thus, the two following lines emit the
same optree, without an C<OP_SREFGEN> or C<OP_RV2AV>:

   @lhs OP @rhs;
   WRAPPERFUNC( \@lhs, \@rhs );

B<Note> that technically, this optimisation isn't strictly transparent in the
odd cornercase that one of the referenced arrays is also the backing store for
a blessed object reference, and that object class has a C<@{}> overload.

   my @arr;
   package SomeClass {
      use overload '@{}' => sub { return ["values", "go", "here"]; };
   }
   bless \@arr, "SomeClass";

   # this will not actually invoke the overload operator
   WRAPPERFUNC( \@arr, [4, 5, 6] );

As this cornercase relates to taking duplicate references to the same blessed
object's backing store variable, it should not matter to any real code;
regular objects that are passed by reference into the wrapper function will
run their overload methods as normal.

The callchecker for list operands can optionally also discard an op of the
C<OP_ANONLIST> type, which is used by anonymous array-ref construction:

   ($u, $v, $w) OP ($x, $y, $z);
   WRAPPERFUNC( [$u, $v, $w], [$x, $y, $z] );

This optimisation is only performed if the operator declared it safe to do so,
via the C<XPI_OPERAND_ONLY_LOOK> flag.

If a function of the given name already exists at registration time it will be
left undisturbed and no new wrapper will be created. This permits the same
infix operator to have multiple spellings of its name; for example to allow
both a real Unicode and a fallback ASCII transliteration of the same operator.
The first registration will create the wrapper function; the subsequent one
will skip it because it would otherwise be identical.

Note that when generating an optree for a wrapper function call, the C<new_op>
hook function will be invoked with a C<NULL> pointer for the C<SV *>-typed
parse data storage, as there won't be an opporunity for the C<parse> hook to
run in this case.

=cut

=head1 DEPARSE

This module operates with L<B::Deparse> in order to automatically provide
deparse support for infix operators. Every infix operator that is implemented
as a custom op (and thus has the C<ppaddr> hook field set) will have deparse
logic added. This will allow it to deparse to either the named wrapper
function, or to the infix operator syntax if on a C<PL_infix_plugin>-enabled
perl and the appropriate lexical hint is enabled at the callsite.

In order for this to work, it is important that your custom operator is I<not>
registered as a custom op using the C<Perl_register_custom_op()> function.
This registration will be performed by C<XS::Parse::Infix> itself at the time
the infix operator is registered.

=cut

sub B::Deparse::_deparse_infix_wrapperfunc_scalarscalar
{
   my ( $self, $wrapper_func_name, $op, $ctx ) = @_;

   my $lhs = $op->first;
   my $rhs = $op->last;

   $_ = $self->deparse( $_, 6 ) for $lhs, $rhs;

   return "$wrapper_func_name($lhs, $rhs)";
}

sub B::Deparse::_deparse_infix_wrapperfunc_listlist
{
   my ( $self, $wrapper_func_name, $op, $ctx ) = @_;

   my $lhs = $op->first;
   my $rhs = $op->last;

   foreach my $var ( \$lhs, \$rhs ) {
      my $argop = $$var;
      my $kid;

      if( $argop->name eq "null" and
          $argop->first->name eq "pushmark" and
          ($kid = $argop->first->sibling) and
          B::Deparse::null($kid->sibling) ) {
         my $add_refgen;

         # A list of a single item
         if( $kid->name eq "rv2av" and $kid->first->name ne "gv" ) {
            $argop = $kid->first;
         }
         elsif( $kid->name eq "padav" or $kid->name eq "rv2av" ) {
            $add_refgen++;
         }
         else {
            print STDERR "Maybe UNWRAP list ${\ $kid->name }\n";
         }

         $$var = $self->deparse( $argop, 6 );

         $$var = "\\$$var" if $add_refgen;
      }
      else {
         # Pretend the entire list was anonlist
         my @args;
         $argop = $argop->first->sibling; # skip pushmark
         while( not B::Deparse::null($argop) ) {
            push @args, $self->deparse( $argop, 6 );
            $argop = $argop->sibling;
         }

         $$var = "[" . join( ", ", @args ) . "]";
      }
   }

   return "$wrapper_func_name($lhs, $rhs)";
}

sub B::Deparse::_deparse_infix_named
{
   my ( $self, $opname, $op, $ctx ) = @_;

   my $lhs = $op->first;
   my $rhs = $op->last;

   return join " ",
      $self->deparse_binop_left( $op, $lhs, 14 ),
      $opname,
      $self->deparse_binop_right( $op, $rhs, 14 );
}

=head1 TODO

=over 4

=item *

Have the entersub checker for list/list operators unwrap arrayref or
anon-array argument forms (C<WRAPPERFUNC( \@lhs, \@rhs )> or
C<WRAPPERFUNC( [LHS], [RHS] )>).

=item *

Further thoughts about how infix operators with C<parse> hooks will work with
automatic deparse, and also how to integrate them with L<XS::Parse::Keyword>'s
grammar piece.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

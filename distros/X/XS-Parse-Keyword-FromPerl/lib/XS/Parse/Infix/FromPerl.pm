#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package XS::Parse::Infix::FromPerl 0.10;

use v5.26; # XS code needs op_class() and the OPclass_* constants
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<XS::Parse::Infix::FromPerl> - drive C<XS::Parse::Infix> directly from Perl

=head1 DESCRIPTION

This module provides a Perl-visible API wrapping (some of) the functionality
provided by L<XS::Parse::Infix>, allowing extension infix operators to be
added to the Perl language by writing code in Perl itself.

It provides a thin wrapping layer over the XS functions provided by XPI
itself. No real attempt is made here to provide further abstractions on top of
the API already provided by Perl and XPI, so users will have to be familiar
with the overall concepts there as well.

This module is currently experimental, on top of the already-experimental
nature of C<XS::Parse::Infix> itself.

=cut

use Exporter 'import';
push our @EXPORT_OK, qw(
   register_xs_parse_infix
);

=head1 FUNCTIONS

=head2 register_xs_parse_infix

   register_xs_parse_infix "name" => %args;

Registers a new extension infix operator into the C<XS::Parse::Infix>
registry, defined using the given name and arguments.

Takes the following named arguments:

=over 4

=item cls => INT

The classification for the operator, which is used both as a filter for the
various C<XS::Parse::Keyword> selection macros, and a hint to the Perl parser
on the precedence level given to the operator. This should be one of the
C<XPI_CLS_*> constants.

=item wrapper_func_name => STRING

Optional. A string value to use for the "wrapper_func_name".

=item permit_hintkey => STRING

Optional. A string value to use for the "permit_hintkey".

=item permit => CODE

Optional. Callback function for the "permit" phase of parsing.

   $ok = $permit->( $hookdata );

When invoked, it is passed a single arugment containing the (optional)
hookdata value, and its result should be a boolean scalar.

At least one of C<permit_hintkey> or C<permit> must be provided.

=item new_op => CODE

Callback function for the "new_op" phase of parsing.

   $op = $new_op->( $flags, $lhs, $rhs, $parsedata, $hookdata );

When invoked, it is passed a flags value, the left-hand and right-hand side
operand optree fragments as C<B::OP> references, the parse data (though this
will always be C<undef> currently), and the optional hookdata value.

Its result should be the overall optree fragment, again as a C<B::OP>
reference, to represent the entire invocation sequence for the operator.

=item hookdata => SCALAR

Optional. If present, this scalar value is stored by the operator definition
and passed into each of the phase callbacks when invoked. If not present then
C<undef> will be passed to the callbacks instead.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

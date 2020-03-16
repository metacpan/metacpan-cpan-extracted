#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=encoding UTF-8

=head1 NAME

C<XS::Parse::Sublike> - XS functions to assist in parsing C<sub>-like syntax

=head1 DESCRIPTION

This module provides some XS functions to assist in writing parsers for
C<sub>-like syntax, primarily for authors of keyword plugins using the
C<PL_keyword_plugin> hook mechanism. It is unlikely to be of much use to
anyone else; and highly unlikely to be any use when writing perl code using
these. Unless you are writing a keyword plugin using XS, this module is not
for you.

This module is also highly experimental, consisting currently of pieces of
code extracted and refactored from L<Future::AsyncAwait> and L<Object::Pad>.
It is hoped eventually this will be useful for other modules too, as well as
providing a potential mechanism by which multiple of these kinds of modules
can coöperate when parsing the same file, and combine their effects. As yet
this part of the mechanism does not exist.

=head1 XS FUNCTIONS

=head2 boot_xs_parse_sublike

   boot_xs_parse_sublike()

Call this function from your C<BOOT> section in order to initialise the module
and parsing hooks.

=head2 xs_parse_sublike

   int result = xs_parse_sublike(&hooks, op_ptr)

This function performs the actual parsing of a C<sub>-like keyword. It expects
the lexer to be at a position just after the introduction keyword has been
consumed, and will proceed to parse an optional name, list of attributes,
signature (if enabled by C<use feature 'signatures'>), and code body. The
return value and C<op_ptr> can be used directly from the keyword plugin
function. It is intended this function be invoked from it, and the result
returned directly.

I<hooks> should be a structure that can provide optional function pointers
used to customise the parsing process at various stages. The structure should
be declared using the following:

   struct XSParseSublikeHooks hooks = { 0 };

=head1 PARSE HOOKS

The C<XSParseSublikeHooks> structure provides the following hook stages, in
the given order:

=head2 post_blockstart

   void (*post_blockstart)(pTHX)

Invoked after the optional name and list of attributes have been parsed and
the C<block_start()> function has been called. This hook stage may wish to
perform any alterations of C<PL_compcv> or related, inspect or alter the
lexical pad, provide hints hash values, or any other tasks before the
signature and code body are parsed.

=head2 pre_blockend

   OP * (*pre_blockend)(pTHX_ OP *body)

Invoked after the signature and body of the function have been parsed, just
before the C<block_end()> function is invoked. This hook is passed the optree
as it has been parsed. The hook stage may wish to inspect or alter the optree,
and should return it. The return value will then be passed to C<newATTRSUB()>.

=head2 post_newcv

   void (*post_newcv)(pTHX_ CV *cv)

Invoked just after C<newATTRSUB()> has been invoked on the optree. The hook
stage may wish to inspect or alter the CV.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike;

use strict;
use warnings;

our $VERSION = '0.04';

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
It is hoped eventually this will be useful for other modules too.

=head1 XS FUNCTIONS

=head2 boot_xs_parse_sublike

  void boot_xs_parse_sublike(double ver)

Call this function from your C<BOOT> section in order to initialise the module
and parsing hooks.

I<ver> should either be 0 or a decimal number for the module version
requirement; e.g.

   boot_xs_parse_sublike(0.04);

=head2 xs_parse_sublike

   int xs_parse_sublike(const struct XSParseSublikeHooks *hooks, OP **op_ptr)

This function performs the actual parsing of a C<sub>-like keyword. It expects
the lexer to be at a position just after the introduction keyword has been
consumed, and will proceed to parse an optional name, list of attributes,
signature (if enabled by C<use feature 'signatures'>), and code body. The
return value and C<op_ptr> can be used directly from the keyword plugin
function. It is intended this function be invoked from it, and the result
returned directly.

For a more automated handling of keywords, see L</register_xs_parse_sublike>.

I<hooks> should be a structure that can provide optional function pointers
used to customise the parsing process at various stages.

=head2 register_xs_parse_sublike

   void register_xs_parse_sublike(const char *keyword,
     const struct XSParseSublikeHooks *hooks)

This function installs a set of parsing hooks to be associated with the given
keyword. Such a keyword will then be handled automatically by a keyword parser
installed by C<XS::Parse::Sublike> itself.

When the keyword is encountered, the hook's C<permit> function is first tested
to see if the keyword is permitted at this point. If the function returns true
then the keyword is consumed and parsed as per L</xs_parse_sublike>.

=head2 xs_parse_sublike_any

   int xs_parse_sublike_any(const struct XSParseSublikeHooks *hooks, OP **op_ptr)

This function expects to consume an introduction keyword at the lexer position
which is either C<sub> or the name of another C<sub>-like keyword, which has
been previously registered using L</register_xs_parse_sublike>. It then
proceeds to parse the subsequent syntax similar to how it would have parsed if
encountered by the module's own keyword parser plugin, except that the second
set of hooks given here also take effect.

If a regular C<sub> is encountered, then this is parsed using the I<hooks> in
a similar way to C<xs_parse_sublike()>.

If a different registered C<sub>-like keyword is encountered, then parsing is
performed using B<both> sets of hooks - the ones given to this function as
well as the ones registered with the keyword. This allows their effects to
combined. The hooks given by the I<hooks> argument are considered to be on the
"outside" from those of the registered keyword "inside". The outside ones run
first for all stages, except C<pre_blockend> which runs them inside-out.

=head1 PARSE HOOKS

The C<XSParseSublikeHooks> structure provides the following hook stages, in
the given order:

=head2 permit

   bool (*permit)(pTHX)

Called by the installed keyword parser hook which is used to handle keywords
registered by L</register_xs_parse_sublike>. This hook stage should inspect
whether the keyword is permitted at this time (typically by inspecting the
hints hash C<GvHV(PL_hintgv)> for some imported key) and return true only if
the keyword is permitted.

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

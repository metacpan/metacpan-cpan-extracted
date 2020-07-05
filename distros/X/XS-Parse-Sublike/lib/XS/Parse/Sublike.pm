#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike;

use strict;
use warnings;

our $VERSION = '0.10';

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

This module is also currently experimental, and the design is still evolving
and subject to change. Later versions may break ABI compatibility, requiring
changes or at least a rebuild of any module that depends on it.

=head1 XS FUNCTIONS

=head2 boot_xs_parse_sublike

  void boot_xs_parse_sublike(double ver)

Call this function from your C<BOOT> section in order to initialise the module
and parsing hooks.

I<ver> should either be 0 or a decimal number for the module version
requirement; e.g.

   boot_xs_parse_sublike(0.04);

=head2 xs_parse_sublike

   int xs_parse_sublike(const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)

This function performs the actual parsing of a C<sub>-like keyword. It expects
the lexer to be at a position just after the introduction keyword has been
consumed, and will proceed to parse an optional name, list of attributes,
signature (if enabled by C<use feature 'signatures'>), and code body. The
return value and C<op_ptr> can be used directly from the keyword plugin
function. It is intended this function be invoked from it, and the result
returned directly.

For a more automated handling of keywords, see L</register_xs_parse_sublike>.

I<hooks> should be a structure that can provide optional function pointers
used to customise the parsing process at various stages. I<hookdata> is an
opaque pointer which is passed through to each of the hook stage functions.

=head2 register_xs_parse_sublike

   void register_xs_parse_sublike(const char *keyword,
     const struct XSParseSublikeHooks *hooks, void *hookdata)

This function installs a set of parsing hooks to be associated with the given
keyword. Such a keyword will then be handled automatically by a keyword parser
installed by C<XS::Parse::Sublike> itself.

When the keyword is encountered, the hook's C<permit> function is first tested
to see if the keyword is permitted at this point. If the function returns true
then the keyword is consumed and parsed as per L</xs_parse_sublike>.

I<hookdata> is an opaque pointer which is passed through to each of the hook
stage functions when they are invoked.

=head2 xs_parse_sublike_any

   int xs_parse_sublike_any(const struct XSParseSublikeHooks *hooks, void *hookdata,
     OP **op_ptr)

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

I<hookdata> is an opaque pointer which is passed through to each of the hook
stage functions when they are invoked.

=head1 PARSE CONTEXT

The various hook stages all share state about the ongoing parse process using
various fields of the C<XSParseSublikeContext> structure.

   struct XSParseSublikeContext {
      SV *name;
      OP *attrs;
      OP *body;
      CV *cv;
   }

=head1 PARSE HOOKS

The C<XSParseSublikeHooks> structure provides the following hook stages, which
are invoked in the given order.

The structure has a I<flags> field, which controls various optional parts of
operation. The following flags are defined.

=over 4

=item XS_PARSE_SUBLIKE_FLAG_FILTERATTRS

If set, the optional C<filter_attr> stage will be invoked.

=back

In addition there are two C<U8> fields named I<require_parts> and
I<skip_parts> which control the behaviour of various parts of the syntax which
are usually optional. Any parts with bits set in I<require_parts> become
non-optional, and an error if they are missing. Any parts with bits set in
I<skip_parts> will skip the relevant part of the parsing process.

When two sets of hooks are combined by the C<xs_parse_sublike_any> function,
these bitmasks are accumulated together with inclusive or. Any part required
by either set of hooks will still be required; any step skipped by either will
be skipped entirely.

If the same bit is set in both fields then the relevant parsing step will not
be performed but it will still be an error for that section to be missing.
This is likely not useful.

Note that for skipped parts, only the actual parsing steps are skipped. A hook
function can still set the relevant fields in the context structure anyway to
force a particular value for those parts.

=over 4

=item XS_PARSE_SUBLIKE_PART_NAME

The name of the function.

=item XS_PARSE_SUBLIKE_PART_ATTRS

The attributes of the function.

This part can be skipped, but the bit is ignored when in I<require_parts>. It
is always permitted to not provide any additional attributes to a function
definition.

=item XS_PARSE_SUBLIKE_PART_SIGNATURE

The parameter signature of the function.

This part can be skipped, but the bit is ignored when in I<require_parts>. It
is always permitted not to provide a signature for a function definition,
because such syntax only applies when C<use feature 'signatures'> is in
effect, and only on supporting perl versions.

=back

=head2 The C<permit> Stage

   bool (*permit)(pTHX_ void *hookdata)

Called by the installed keyword parser hook which is used to handle keywords
registered by L</register_xs_parse_sublike>. This hook stage should inspect
whether the keyword is permitted at this time (typically by inspecting the
hints hash C<GvHV(PL_hintgv)> for some imported key) and return true only if
the keyword is permitted.

=head2 Parse Name

At this point, the optional name is parsed and filled into the C<name> field
of the context.

=head2 The C<pre_subparse> Stage

   void (*pre_subparse)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)

Invoked just before C<start_subparse()> is called.

=head2 Parse Attrs

At this point the optional sub attributes are parsed and filled into the
C<attrs> field of the context, then C<block_start()> is called.

=head2 The optional C<filter_attr> Stage

   bool (*filter_attr)(pTHX_ struct XSParseSublikeContext *ctx,
      SV *attr, SV *val, void *hookdata);

If the I<flags> field includes C<XS_PARSE_SUBLIKE_FLAG_FILTERATTRS> then each
individual attribute is passed through this optional filter function
immediately as each is parsed. I<attr> will be a string SV containing the name
of the attribute, and I<val> will either be C<NULL>, or a string SV containing
the contents of the parens after its name (without the parens themselves).

If the filter returns C<true>, it indicates that it has in some way handled
the attribute and it should not be added to the list given to C<newATTRSUB()>.
If the filter returns C<false> it will be handled in the usual way; equivalent
to the case where the filter function did not exist.

=head2 The C<post_blockstart> Stage

   void (*post_blockstart)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)

Invoked after the C<block_start()> function has been called. This hook stage
may wish to perform any alterations of C<PL_compcv> or related, inspect or
alter the lexical pad, provide hints hash values, or any other tasks before
the signature and code body are parsed.

=head2 Parse Body

At this point, the main body of the function is parsed and the optree is
stored in the C<body> field of the context. If the perl version supports sub
signatures and they are enabled and found, the body will be prefixed with the
signature ops as well.

=head2 The C<pre_blockend> Stage

   void (*pre_blockend)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)

Invoked just before the C<block_end()> function is invoked. The hook stage may
wish to inspect or alter the optree stored in the C<body> context field.

=head2 The C<post_newcv> Stage

   void (*post_newcv)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)

Invoked just after C<newATTRSUB()> has been invoked on the optree. The hook
stage may wish to inspect or alter the CV stored in the C<cv> context field.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

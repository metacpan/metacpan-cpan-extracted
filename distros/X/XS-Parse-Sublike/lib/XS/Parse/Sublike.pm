#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2024 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike 0.26;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

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

=for highlighter language=c

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

Note that this function is now vaguely discouraged, in favour of using a
prefixing keyword instead, by using the C<XS_PARSE_SUBLIKE_FLAG_PREFIX> flag.

=head1 PARSE CONTEXT

The various hook stages all share state about the ongoing parse process using
various fields of the C<XSParseSublikeContext> structure.

   struct XSParseSublikeContext {
      SV *name;
      OP *attrs;
      OP *body;
      CV *cv;
      U32 actions;
      HV *moddata;
   }

The C<actions> field will contain a bitmask of action flags that control the
various steps that C<XS::Parse::Sublike> might take inbetween invoking hook
stages. The initial value of this field is set after the name-parsing stage,
depending on whether or not a name is found. Stage hook functions may modify
the field to adjust the subsequent behaviour.

At the current ABI version, a module will have to set the
C<XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS> bit of the C<flags> field in
order to make use of the I<actions> field. A future ABI version may remove
this restriction.

=over 4

=item XS_PARSE_SUBLIKE_ACTION_CVf_ANON

If set, the C<start_subparse()> call will be set up for an anonymous function
protosub; if not it will be set for a named function. This is set by default
if a name was not found.

=item XS_PARSE_SUBLIKE_ACTION_SET_CVNAME

If set, the newly-constructed CV will have the given name set on it. This is
set by default if a name was found.

On Perl versions 5.22 and above, this flag can be set even if
C<XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL> is not. In this case, the CV will
not be reachable via the symbol table, even though it knows its own name and
pretends that it is. On earlier versions of perl this flag will be ignored in
that case.

=item XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL

If set, the newly-constructed CV will be installed into the symbol table at
its given name. Note that it is not possible to enable this flag without also
enabling C<XS_PARSE_SUBLIKE_ACTION_SET_CVNAME>. This is set by default if a
name was found.

=item XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL

If set, the newly-constructed CV will be installed into the currently
compiling lexical pad as its given name. This is only available on Perl
version 5.18 or above, and conflicts with the alternative of
C<XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL>. This is set by default if a name
was found I<and> the C<my> keyword appeared before the construction.

=item XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE

If set, the syntax will yield the C<OP_REFGEN> / C<OP_ANONCODE> optree
fragment typical of anonymous code expressions; if not it will be C<OP_NULL>.
This is set by default if a name was not found.

=item XS_PARSE_SUBLIKE_ACTION_RET_EXPR

If set, the syntax will parse like an expression; if not it will parse like a
statement. This is set by default if a name was not found.

=back

The I<moddata> field will point towards an HV that modules can used to store
extra data between stages. As a naming convention a module should prefix its
keys with its own module name and a slash character, C<"Some::Module/field">.
The field will point to a newly-created HV for every parse invocation, and
will be released when each parse is complete.

=head1 PARSE HOOKS

The C<XSParseSublikeHooks> structure provides the following hook stages, which
are invoked in the given order.

The structure has a I<flags> field, which controls various optional parts of
operation. The following flags are defined.

=over 4

=item XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL

If B<not> set, the I<require_parts> field will imply the
C<XS_PARSE_SUBLIKE_PART_BODY> flag, making the body part required. By setting
this flag this will no longer happen. If all hooks agree, then the body will
become optional.

=item XS_PARSE_SUBLIKE_FLAG_PREFIX

If set, the keyword is considered to be a prefix that can be placed in front
of C<sub> or another sub-like keyword, to add its set of hooks in addition to
those of the following keyword. These prefices may be further stacked.

=back

In addition there are two C<U8> fields named I<require_parts> and
I<skip_parts> which control the behaviour of various parts of the syntax which
are usually optional. Any parts with bits set in I<require_parts> become
non-optional, and an error if they are missing. Any parts with bits set in
I<skip_parts> will skip the relevant part of the parsing process.

When multiple sets of hooks are combined by the C<xs_parse_sublike_any>
function, or as part of parsing prefixing keywords, these bitmasks are
accumulated together with inclusive or. Any part required by any set of hooks
will still be required; any step skipped by either will be skipped entirely.

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

This part can be skipped, but it is always permitted not to provide a
signature for a function definition even if the bit it set in
I<require_parts>. This is because such syntax only applies when
C<use feature 'signatures'> is in effect, and only on supporting perl
versions.

However, setting the bit in I<require_parts> instead has the effect of
enabling C<use feature 'signatures'> (at least on supporting perl versions),
thus permitting the syntax to use a signature even if the signatures feature
was not previously enabled.

=item XS_PARSE_SUBLIKE_PART_BODY

The actual body of the function, expressed as a brace-delimited block.

This part cannot be skipped, but it can be made optional by omitting it from
the I<require_parts> field. Instead of the block, it is permitted to place a
single semicolon (C<;>) to act as a statement terminator; thus giving the same
syntax as a subroutine forward declaration.

In this case, the C<body> and C<cv> fields of the context structure will
remain C<NULL>.

This flag is currently implied on the I<require_parts> field if the hook does
not supply the C<XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL> flag; meaning that most
use-cases will make it a required part.

=back

=head2 The C<permit> Stage

   const char *permit_hintkey
   bool (*permit)(pTHX_ void *hookdata)

Called by the installed keyword parser hook which is used to handle keywords
registered by L</register_xs_parse_sublike>.

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

=head2 Parse Name

At this point, the optional name is parsed and filled into the C<name> field
of the context.

=head2 The C<pre_subparse> Stage

   void (*pre_subparse)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)

Invoked just before C<start_subparse()> is called.

=head2 Parse Attrs

At this point the optional sub attributes are parsed and filled into the
C<attrs> field of the context, then C<block_start()> is called.

=head2 The C<filter_attr> Stage

   bool (*filter_attr)(pTHX_ struct XSParseSublikeContext *ctx,
      SV *attr, SV *val, void *hookdata);

If this optional stage is defined, then each individual attribute is passed
through this optional filter function immediately as each is parsed. I<attr>
will be a string SV containing the name of the attribute, and I<val> will
either be C<NULL>, or a string SV containing the contents of the parens after
its name (without the parens themselves).

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

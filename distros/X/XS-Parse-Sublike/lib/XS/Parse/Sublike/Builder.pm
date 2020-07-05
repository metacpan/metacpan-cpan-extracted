#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike::Builder;

use strict;
use warnings;

our $VERSION = '0.10';

=head1 NAME

C<XS::Parse::Sublike::Builder> - build-time support for C<XS::Parse::Sublike>

=head1 SYNOPSIS

In F<Build.PL>:

   use XS::Parse::Sublike::Builder;

   my $build = Module::Build->new(
      ...,
      configure_requires => {
         ...
         'XS::Parse::Sublike::Builder' => 0,
      }
   );

   XS::Parse::Sublike::Builder->extend_module_build( $build );

   ...

=head1 DESCRIPTION

This module provides a build-time helper to assist authors writing XS modules
that use L<XS::Parse::Sublike>. It prepares a L<Module::Build>-using
distribution to be able to make use of C<XS::Parse::Sublike>.

=cut

my $XSParseSublike_h = do {
   local $/;
   readline DATA;
};

=head1 FUNCTIONS

=cut

=head2 write_XSParseSublike_h

   XS::Parse::Sublike::Builder->write_XSParseSublike_h

Writes the F<XSParseSublike.h> file to the current working directory. To cause
the compiler to actually find this file, see L</extra_compiler_flags>.

=cut

sub write_XSParseSublike_h
{
   shift;

   open my $out, ">", "XSParseSublike.h" or
      die "Cannot open XSParseSublike.h for writing - $!\n";

   $out->print( $XSParseSublike_h );
}

=head2 extra_compiler_flags

   @flags = XS::Parse::Sublike::Builder->extra_compiler_flags

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<XSParseSublike.h> file.

=cut

sub extra_compiler_flags
{
   shift;
   return "-I.";
}

=head2 extend_module_build

   XS::Parse::Sublike::Builder->extend_module_build( $build )

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   eval { $self->write_XSParseSublike_h } or do {
      warn $@;
      return;
   };

   # preserve existing flags
   my @flags = @{ $build->extra_compiler_flags };
   push @flags, $self->extra_compiler_flags;

   $build->extra_compiler_flags( @flags );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

__DATA__
#ifndef __XS_PARSE_SUBLIKE_H__
#define __XS_PARSE_SUBLIKE_H__

#define XSPARSESUBLIKE_ABI_VERSION 3

struct XSParseSublikeContext {
  SV *name;  /* may be NULL for anon subs */
  /* STAGE pre_subparse */
  OP *attrs; /* may be NULL */
  /* STAGE post_blockstart */
  OP *body;
  /* STAGE pre_blockend */
  CV *cv;
  /* STAGE post_newcv */
};

enum {
  XS_PARSE_SUBLIKE_FLAG_FILTERATTRS = 1<<0,
};

enum {
  XS_PARSE_SUBLIKE_PART_NAME      = 1<<0,
  XS_PARSE_SUBLIKE_PART_ATTRS     = 1<<1,
  XS_PARSE_SUBLIKE_PART_SIGNATURE = 1<<2,
};

struct XSParseSublikeHooks {
  U16  flags;
  U8   require_parts;
  U8   skip_parts;
  bool (*permit)         (pTHX_ void *hookdata);
  void (*pre_subparse)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_blockstart)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*pre_blockend)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_newcv)     (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);

  /* if flags & XS_PARSE_SUBLIKE_FLAG_FILTERATTRS */
  bool (*filter_attr)    (pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *val, void *hookdata);
};

static int (*parse_func)(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr);
#define xs_parse_sublike(hooks, hookdata, op_ptr)  S_xs_parse_sublike(aTHX_ hooks, hookdata, op_ptr)
static int S_xs_parse_sublike(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)
{
  if(!parse_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*parse_func)(aTHX_ hooks, hookdata, op_ptr);
}

static void (*register_func)(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata);
#define register_xs_parse_sublike(kw, hooks, hookdata) S_register_xs_parse_sublike(aTHX_ kw, hooks, hookdata)
static void S_register_xs_parse_sublike(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata)
{
  if(!register_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*register_func)(aTHX_ kw, hooks, hookdata);
}

static int (*parseany_func)(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr);
#define xs_parse_sublike_any(hooks, hookdata, op_ptr)  S_xs_parse_sublike_any(aTHX_ hooks, hookdata, op_ptr)
static int S_xs_parse_sublike_any(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)
{
  if(!parseany_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*parseany_func)(aTHX_ hooks, hookdata, op_ptr);
}

#define boot_xs_parse_sublike(ver) S_boot_xs_parse_sublike(aTHX_ ver)
static void S_boot_xs_parse_sublike(pTHX_ double ver) {
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Sublike"), versv, NULL);

  int abi_version = SvIV(get_sv("XS::Parse::Sublike::ABIVERSION", 0));
  if(abi_version != XSPARSESUBLIKE_ABI_VERSION)
    croak("XS::Parse::Sublike ABI version mismatch - library provides %d, compiled for %d",
        abi_version, XSPARSESUBLIKE_ABI_VERSION);

  parse_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, void *, OP**),
      SvUV(get_sv("XS::Parse::Sublike::PARSE", 0)));

  register_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseSublikeHooks *, void *),
      SvUV(get_sv("XS::Parse::Sublike::REGISTER", 0)));

  parseany_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, void *, OP**),
      SvUV(get_sv("XS::Parse::Sublike::PARSEANY", 0)));
}

#endif

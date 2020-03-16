#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike::Builder;

use strict;
use warnings;

our $VERSION = '0.01';

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

struct XSParseSublikeHooks {
  void (*post_blockstart)(pTHX);
  OP * (*pre_blockend)   (pTHX_ OP *body);
  void (*post_newcv)     (pTHX_ CV *cv);
};

#define xs_parse_sublike(hooks, op_ptr)  S_xs_parse_sublike(aTHX_ hooks, op_ptr)
static int S_xs_parse_sublike(pTHX_ struct XSParseSublikeHooks *hooks, OP **op_ptr)
{
  SV *sv = get_sv("XS::Parse::Sublike::PARSE", 0);
  if(!sv)
    croak("Cannot find $XS::Parse::Sublike::PARSE - is it loaded?");

  int (*func)(pTHX_ struct XSParseSublikeHooks *hooks, OP **op_ptr)
    = INT2PTR(int (*)(pTHX_ struct XSParseSublikeHooks *, OP**), SvUV(sv));

  return (*func)(aTHX_ hooks, op_ptr);
}

#define boot_xs_parse_sublike() \
  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Sublike"), NULL, NULL)

#endif

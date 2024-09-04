#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package XS::Parse::Keyword::Builder 0.46;

use v5.14;
use warnings;

=head1 NAME

C<XS::Parse::Keyword::Builder> - build-time support for C<XS::Parse::Keyword>

=head1 SYNOPSIS

In F<Build.PL>:

   use XS::Parse::Keyword::Builder;

   my $build = Module::Build->new(
      ...,
      configure_requires => {
         ...
         'XS::Parse::Keyword::Builder' => 0,
      }
   );

   XS::Parse::Keyword::Builder->extend_module_build( $build );

   ...

=head1 DESCRIPTION

This module provides a build-time helper to assist authors writing XS modules
that use L<XS::Parse::Keyword>. It prepares a L<Module::Build>-using
distribution to be able to make use of C<XS::Parse::Keyword>.

=cut

use XS::Parse::Keyword::Builder_data;

=head1 FUNCTIONS

=cut

=head2 write_XSParseKeyword_h

   XS::Parse::Keyword::Builder->write_XSParseKeyword_h;

This method no longer does anything I<since version 0.43>.

=cut

sub write_XSParseKeyword_h
{
}

=head2 extra_compiler_flags

   @flags = XS::Parse::Keyword::Builder->extra_compiler_flags;

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<XSParseKeyword.h> file.

=cut

sub extra_compiler_flags
{
   shift;

   require File::ShareDir;
   require File::Spec;
   require XS::Parse::Keyword;

   return "-I" . File::Spec->catdir( File::ShareDir::module_dir( "XS::Parse::Keyword" ), "include" ),
      XS::Parse::Keyword::Builder_data->BUILDER_CFLAGS;
}

=head2 extend_module_build

   XS::Parse::Keyword::Builder->extend_module_build( $build );

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   # preserve existing flags
   my @flags = @{ $build->extra_compiler_flags };
   push @flags, $self->extra_compiler_flags;

   $build->extra_compiler_flags( @flags );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

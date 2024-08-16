#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2024 -- leonerd@leonerd.org.uk

package XS::Parse::Sublike::Builder 0.23;

use v5.14;
use warnings;

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

=head1 FUNCTIONS

=cut

=head2 write_XSParseSublike_h

   XS::Parse::Sublike::Builder->write_XSParseSublike_h;

This method no longer does anything I<since version 0.22>.

=cut

sub write_XSParseSublike_h
{
}

=head2 extra_compiler_flags

   @flags = XS::Parse::Sublike::Builder->extra_compiler_flags;

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<XSParseSublike.h> file.

=cut

sub extra_compiler_flags
{
   shift;

   require File::ShareDir;
   require File::Spec;
   require XS::Parse::Sublike;
   return "-I" . File::Spec->catdir( File::ShareDir::module_dir( "XS::Parse::Sublike" ), "include" );
}

=head2 extend_module_build

   XS::Parse::Sublike::Builder->extend_module_build( $build );

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

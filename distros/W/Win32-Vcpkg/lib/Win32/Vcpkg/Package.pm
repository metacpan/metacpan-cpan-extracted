package Win32::Vcpkg::Package;

use strict;
use warnings;
use 5.008001;
use Win32::Vcpkg;
use Path::Tiny ();

# ABSTRACT: Interface to Microsoft Vcpkg Packages
our $VERSION = '0.02'; # VERSION


sub new
{
  my($class, %args) = @_;

  my $root    = defined $args{root} ? Path::Tiny->new($args{root}) : Win32::Vcpkg->root;
  my $triplet = $args{triplet} || Win32::Vcpkg->perl_triplet;
  my @lib     = @{ $args{lib} || [] };
  my $debug   = defined $args{debug} ? $args{debug} : $ENV{PERL_WIN32_VCPKG_DEBUG};

  my $cflags = "-I@{[ $root->child('installed', $triplet, 'include') ]}";

  my $libdir = $root->child('installed', $triplet, 'lib');
  $libdir    = $libdir->parent->child('debug','lib') if $debug;
  my $libs   = "-LIBPATH:$libdir";

  foreach my $lib (@lib)
  {
    if(-f $libdir->child("$lib.lib"))
    {
      $libs .= " $lib.lib";  # Question: should this be an absolute path?
    }
    else
    {
      require Carp;
      Carp::croak("unable to find $lib");
    }
  }

  bless {
    name    => $args{_name},
    version => $args{_version},
    root    => $root,
    triplet => $triplet,
    cflags  => $cflags,
    libs    => $libs,
  }, $class;
}


sub name { shift->{name} }


sub version { shift->{version} }


sub root { shift->{root} }


sub triplet { shift->{triplet} }


sub cflags { shift->{cflags} }


sub libs { shift->{libs} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Vcpkg::Package - Interface to Microsoft Vcpkg Packages

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Win32::Vcpkg::Package;
 
 my $package = Win32::Vcpkg::Package->new(
   lib => ['foo','bar'],
 );
 
 my $cflags = $package->cflags;
 my $libs   = $package->libs;

=head1 DESCRIPTION

This module provides an interface to a C<Vcpkg> package.  C<Vcpkg> is a Visual C++ library package manager,
and as such is useful in building XS and FFI extensions for Visual C++ builds of Perl.  Given a list of
libraries, this module will search for them, and if found you can get the compiler and linker flags needed
to compile and link against them.

=head1 CONSTRUCTOR

=head2 new

 my $package = Win32::Vcpkg::Package->new(%options);

Creates a package instance.  If the libraries specified are not found then an exception will be thrown.

=over 4

=item root

The C<Vcpkg> root.  By default this is what C<root> from L<Win32::Vcpkg> returns.

=item triplet

The C<Vcpkg> triplet.  By default this is what C<perl_triplet> from L<Win32::Vcpkg> returns.

=item lib

Array reference of library names.  Do not include the C<.lib> extension.  If not provided, then
no libraries will be linked against, but this might be useful to get the compiler flags (C<cflags>)
and linker flags (C<libs>) needed for C<Vcpkg>.

=item debug

If true, link against the debug version of the libraries.

=back

=head1 ATTRIBUTES

=head2 name

 my $name = $package->name;

Returns the name of the package, if known.

=head2 version

 my $version = $package->version;

Returns the version of the package, if known.

=head2 root

 my $root = $package->root;

The C<Vcpkg> root.  This is an L<Path::Tiny> object.

=head2 triplet

 my $triplet = $package->triplet;

The C<Vcpkg> triplet.

=head2 cflags

 my $cflags = $package->cflags;

The compiler flags needed to compile against the package.

=head2 libs

 my $libs = $package->libs;

The linker flags needed to link against the package.

=head1 SEE ALSO

=over 4

=item L<Win32:Vcpkg>

=item L<Win32::Vcpkg::List>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

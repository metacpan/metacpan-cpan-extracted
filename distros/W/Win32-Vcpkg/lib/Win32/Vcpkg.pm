package Win32::Vcpkg;

use strict;
use warnings;
use 5.008001;
use Path::Tiny ();
use Config;

# ABSTRACT: Interface to Microsoft Vcpkg
our $VERSION = '0.02'; # VERSION


sub root
{
  if(defined $ENV{PERL_WIN32_VCPKG_ROOT})
  {
    my $root = Path::Tiny->new($ENV{PERL_WIN32_VCPKG_ROOT});
    if(-d $root && -f $root->child('.vcpkg-root'))
    {
      return $root;
    }
  }

  {
    my $vcpkg_path_txt = Path::Tiny->new(
      $^O eq 'MSWin32'
      ? "~/AppData/Local/vcpkg/vcpkg.path.txt"
      : "~/.vcpkg/vcpkg.path.txt",
    );
    if(-r $vcpkg_path_txt)
    {
      my $path = $vcpkg_path_txt->slurp;  # FIXME: what is the encoding of this file?
      chomp $path;
      my $root = Path::Tiny->new($path);
      if(-d $root && -f $root->child('.vcpkg-root'))
      {
        return $root;
      }
    }
  }

  return ();
}


my $perl_triplet;

sub perl_triplet
{
  return $perl_triplet if $perl_triplet;

  return $perl_triplet = $ENV{VCPKG_DEFAULT_TRIPLET} if defined $ENV{VCPKG_DEFAULT_TRIPLET};

  if($Config{archname} =~ /^x86_64-linux/)
  {
    return $perl_triplet = 'x64-linux';
  }
  elsif($^O eq 'darwin' && $Config{ptrsize} == 8)
  {
    return $perl_triplet = 'x64-osx';
  }
  elsif($^O eq 'MSWin32')
  {
    if($Config{ptrsize} == 4)
    {
      return $perl_triplet = 'x86-windows';
    }
    elsif($Config{ptrsize} == 8)
    {
      return $perl_triplet = 'x64-windows'
    }
  }
  die "no triplet for this build of Perl";
}


my %default_triplet = (
  'MSWin32' => 'x86-windows',
  'linux'   => 'x64-linux',
  'darwin'  => 'x64-osx',
);

sub default_triplet
{
  $ENV{VCPKG_DEFAULT_TRIPLET} || $default_triplet{$^O} || die "no default triplet for $^O";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Vcpkg - Interface to Microsoft Vcpkg

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Win32::Vcpkg;
 my $root = Win32::Vcpkg->root;
 my $triplet = Win32::Vcpkg->perl_triplet;

=head1 DESCRIPTION

This module provides an interface for finding and using C<Vcpkg> packages.  C<Vcpkg> is a Visual C++
library package manager, and as such is useful in building XS and FFI extensions for Visual C++ builds
of Perl.

=head1 METHODS

=head2 root

 my $path = Win32::Vcpkg->root;

Returns a L<Path::Tiny> object for the root of the Vcpkg install.

=head2 perl_triplet

 my $triplet = Win32::Vcpkg->perl_triplet;

Returns the triplet needed for linking against Perl.

=head2 default_triplet

 my $triplet = Win32::Vcpkg->default_triplet;

Returns the default triplet for the current environment.

=head1 ENVIRONMENT

=over 4

=item C<VCPKG_DEFAULT_TRIPLET>

This is Vcpkg's default triplet.  If set this will override platform detection for the default triplet.

=item C<PERL_WIN32_VCPKG_ROOT>

If set, this will be used for the Vcpkg root instead of automatic detection logic.

=item C<PERL_WIN32_VCPKG_DEBUG>

If set to true, will link against debug libraries.

=back

=head1 SEE ALSO

=over 4

=item L<Win32:Vcpkg::List>

=item L<Win32:Vcpkg::Package>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

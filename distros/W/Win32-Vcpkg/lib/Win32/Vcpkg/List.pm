package Win32::Vcpkg::List;

use strict;
use warnings;
use 5.008001;
use Win32::Vcpkg;
use Path::Tiny ();
use Storable qw( dclone );

# ABSTRACT: Interface to Microsoft Vcpkg List of Packages
our $VERSION = '0.04'; # VERSION


sub new
{
  my($class, %args) = @_;

  my $root = defined $args{root} ? Path::Tiny->new($args{root}) : Win32::Vcpkg->root;

  my $vcpkg_exe = $root->child('vcpkg.exe');
  if(-x $vcpkg_exe)
  {
    # TODO: this is a bit flaky, the root directory might
    # not have vcpkg.exe.
    `$vcpkg_exe list`;  # force a rebuild of the status file
  }

  my $status = $root->child('installed', 'vcpkg', 'status');

  my @status;
  my %arch;
  {
    my %entry;

    foreach my $line ($status->lines)
    {
      chomp $line;
      if($line =~ /^(.*?):\s*(.*)$/)
      {
        my($k,$v) = ($1, $2);
        $entry{$k} = $v;
        $arch{$v}++ if $k eq 'Architecture';
      }
      elsif($line =~ /^\s*$/)
      {
        if(%entry)
        {
          push @status, dclone(\%entry);
          %entry = ();
        }
      }
    }

    if(%entry)
    {
      push @status, \%entry;
    }
  }

  bless {
    root     => $root,
    status   => \@status,
    triplets => [sort keys %arch],
  }, $class;
}


sub root { shift->{root} }


sub triplets { @{ shift->{triplets} } }


sub search
{
  my($self, $name, %options) = @_;
  my $triplet = $options{triplet} || Win32::Vcpkg->perl_triplet;
  my $debug   = defined $options{debug} ? $options{debug} : $ENV{PERL_WIN32_VCPKG_DEBUG};

  foreach my $status (@{ $self->{status} })
  {
    next unless $status->{Architecture} eq $triplet
    &&          $status->{Package} eq $name
    &&          !defined $status->{Feature}
    &&          $status->{Version}
    &&          $status->{Status} eq 'install ok installed';

    my $version = $status->{Version};
    my $file_list = $self->root->child('installed','vcpkg','info',sprintf("%s_%s_%s.list", $name, $version, $triplet));
    if($file_list->is_file)
    {
      my @lib;
      my $libpath = Path::Tiny->new($triplet, 'lib');
      $libpath = $libpath->parent->child('debug','lib') if $debug;
      foreach my $line ($file_list->lines)
      {
        chomp $line;
        my $path = Path::Tiny->new($line);
        if($path->basename =~ /^(.*?)\.lib$/)
        {
          if($path->parent->stringify eq $libpath->stringify)
          {
            push @lib, "$1";
          }
        }
      }
      require Win32::Vcpkg::Package;
      return Win32::Vcpkg::Package->new(
        _name    => $name,
        _version => $version,
        root     => $self->root,
        triplet  => $triplet,
        debug    => $debug,
        include  => $options{include},
        lib      => \@lib,
      );
    }
    else
    {
      require Carp;
      Carp::croak("unable to find file list for $name $version $triplet");
    }
  }

  return undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Vcpkg::List - Interface to Microsoft Vcpkg List of Packages

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Win32::Vcpkg::List;

=head1 DESCRIPTION

This module provides an interface to a list of C<Vcpkg> package.  C<Vcpkg> is a Visual C++ library package manager,
and as such is useful in building XS and FFI extensions for Visual C++ builds of Perl.

=head1 CONSTRUCTOR

=head2 new

 my $list = Win32::Vcpkg::List->new(%options);

Creates a list of packages instance.

=over 4

=item root

The C<Vcpkg> root.  By default this is what C<root> from L<Win32::Vcpkg> returns.

=back

=head1 ATTRIBUTES

=head2 root

 my $root = $list->root;

The C<Vcpkg> root.  This is an L<Path::Tiny> object.

=head2 triplets

 my @triplets = $list->triplets;

Return a list of the architecture triplets present in the Vcpkg install directory.

=head1 METHODS

=head2 search

 my $package = $list->search($name, %options);

Search for a package with the given name.  The package returned will be an instance of
L<Win32::Vcpkg::Package>.  If no package is found then C<undef> is returned.  Options:

=over 4

=item triplet

The architecture triplet to search under.  The C<Vcpkg> triplet.  By default this
is what C<perl_triplet> from L<Win32::Vcpkg> returns.

=item include

Any header subdirectory names.

=item debug

If set to true, the C<$package> object will use debug libraries.

=back

=head1 SEE ALSO

=over 4

=item L<Win32::Vcpkg>

=item L<Win32::Vcpkg::Package>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

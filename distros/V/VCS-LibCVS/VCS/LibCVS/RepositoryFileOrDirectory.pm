#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::RepositoryFileOrDirectory;

use strict;
use Carp;

use File::Spec::Unix;

=head1 NAME

VCS::LibCVS::RepositoryFileOrDirectory - An object in the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a CVS object in the repository, either a file or a directory.  You
shouldn't use this directly, instead you should use RepositoryFile and
RepositoryDirectory which inherit from it.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/RepositoryFileOrDirectory.pm,v 1.14 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Repository}  The VCS::LibCVS::Repository in which the object lives.
#
# $self->{FileSpec}    Path of $self in the repository filesystem
#                      Canonized with File::Spec::Unix, and relative to the
#                      repository root.  Repositories always use UNIX Filespecs

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<find()>

$rep_obj = VCS::LibCVS::RepositoryFileOrDirectory->find($repository, $name)

=over 4

=item return type: subclass of VCS::LibCVS::RepositoryFileOrDirectory

=item argument 1 type: VCS::LibCVS::Repository

=item argument 2 type: string scalar

The path of a file or directory within the repository.

=back

It will return either a VCS::LibCVS::RepositoryDirectory or
VCS::LibCVS::RepositoryFile object, depending on what the second argument
names.

=cut

sub find {
  my $class = shift;

  # First see if it's already in the repository cache
  if ($VCS::LibCVS::Cache_RepositoryFileOrDirectory) {
    my ($repo, $path) = @_;
    my $cache = $repo->{RepositoryFileOrDirectoryCache};
    return $cache->{$path} if $cache->{$path};
  }

  my $file_or_dir;
  # Try to load it as a file, if an exception is thrown, then it's a directory.
  eval { $file_or_dir = VCS::LibCVS::RepositoryFile->new(@_); };
  if ($@) {
    if ($@ !~ /^.* is a directory./) {
      confess($@);
    }
    $file_or_dir = VCS::LibCVS::RepositoryDirectory->new(@_);
  }

  return $file_or_dir;
}

# This constructor is private, there's no reason for anything except the
# subclasses to call it.

sub new {
  my $class = shift;
  my ($repo, $path) = @_;

  # If the path is absolute, make it relative to the repository
  if (File::Spec::Unix->file_name_is_absolute($path)) {
    my $base = $repo->get_root()->get_dir();
    $path = File::Spec::Unix->abs2rel( $path, $base );
  }

  # Clean up the path.  See issue 47.
  $path = File::Spec::Unix->canonpath($path);

  # Look in the repo's cache for this file
  my $cache = $repo->{RepositoryFileOrDirectoryCache};
  return $cache->{$path}
    if $VCS::LibCVS::Cache_RepositoryFileOrDirectory && $cache->{$path};

  my $that = bless {}, $class;
  $that->{Repository} = $repo;
  $that->{FileSpec} = $path;

  # Cache if appropriate
  $cache->{$path} = $that if $VCS::LibCVS::Cache_RepositoryFileOrDirectory;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_name()>

$name = $r_obj->get_name({abs => 1})

=over 4

=item return type: scalar string

=item argument 1 type: hash ref of options

All options default to false.

  $opts->{abs}     False: Don't return absolute filename
  $opts->{no_dir}  False: Include directory names
  $opts->{no_base} False: Include the filename within the directory

=back

Returns the filename of the object with the repository, formatted according to
the options.

=cut

sub get_name {
  my $self = shift;
  my $opts = shift || {};

  my $abs = $self->{Repository}->get_root()->get_dir();
  my ($vol, $dir, $base) = File::Spec::Unix->splitpath($self->{FileSpec});

  my $path = File::Spec::Unix->catdir($opts->{abs}     ? "$abs" : (),
                                      ($opts->{no_dir} || !$dir)  ? () : "$dir",
                                      $opts->{no_base} ? ()     : "$base");
  # If there's no $dir, then it's the current dir, so return that
  $path ||= File::Spec::Unix->curdir();
  return $path;
}

=head2 B<get_repository()>

$rep_obj->get_repository()

=over 4

=item return type: VCS::LibCVS::Repository

=back

Returns the repository in which this object lives.

=cut

sub get_repository {
  my $self = shift;
  return $self->{Repository};
}

=head2 B<get_directory_of()>

$r_dir = $r_obj->get_directory_of()

=over 4

=item return type: VCS::LibCVS::RepositoryDirectory

=back

Returns the repository directory in which the object lives.

For a top level relative repository directory (one with no / in the name), the
parent directory returned will be ".".  For "." an exception will be thrown.

=cut

sub get_directory_of {
  my $self = shift;

  confess (". has no parent directory") if ($self->{FileSpec} eq ".");

  # totally screws up if there is a ".." in there.  See issue 47.
  my $dir = ($self->get_name({no_base => 1})) || ".";
  return VCS::LibCVS::RepositoryDirectory->new($self->{Repository}, $dir);
}

=head2 B<equals()>

if ($ford1->equals($ford2)) {

=over 4

=item return type: boolean

=item argument 1 type: VCS::LibCVS::RepositoryFileOrDirectory

=back

Returns true if this and the other "f or d" represent the same thing in the
repository.

=cut

sub equals {
  my $self = shift;
  my $other = shift;

  return (   $self->{Repository}->equals($other->{Repository})
          && ($self->{FileSpec} eq $other->{FileSpec}));
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

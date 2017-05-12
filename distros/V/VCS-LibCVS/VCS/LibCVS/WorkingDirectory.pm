#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::WorkingDirectory;

use strict;
use Carp;

use IO::Dir;

=head1 NAME

VCS::LibCVS::WorkingDirectory - A directory checked out from CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents a directory of files checked out from CVS.

=head1 SUPERCLASS

VCS::LibCVS::WorkingFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/WorkingDirectory.pm,v 1.10 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::WorkingFileOrDirectory");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$working_dir = VCS::LibCVS::WorkingDirectory->new($dirname)

=over 4

=item return type: VCS::LibCVS::WorkingDirectory

=item argument 1 type: scalar string

The name of the directory which is under CVS control.

=back

Creates a new WorkingDirectory.  The filename may be relative or absolute, and
is stored as such.

=cut

sub new {
  my $class = shift;
  my $that = $class->SUPER::new(@_);

  $that->{Admin} = VCS::LibCVS::Admin->new($that->get_name);

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_remote_object()>

$r_dir = $l_dir->get_remote_object()

=over 4

=item return type: VCS::LibCVS::RepositoryDirectory

Returns the CVS repository directory associated with this working directory.

=back

It reads the CVS working dir administrative directory to get this info.

=cut

sub get_remote_object {
  my $self = shift;

  my $repo = VCS::LibCVS::Repository->new($self->{Admin}->get_Root());
  my $r_name = $self->{Admin}->get_Repository()->{DirectoryName};
  return VCS::LibCVS::RepositoryDirectory->new($repo, $r_name);
}

=head2 B<get_files()>

$l_files = $l_dir->get_files()

=over 4

=item return type: ref to hash

keys are filenames relative to this directory, as strings, values are
objects of type VCS::LibCVS::WorkingFile.

=back

Returns the CVS managed files in this directory, as specified locally in the
CVS sandbox administrative directory.

=cut

sub get_files {
  my $self = shift;
  my $entries = $self->{Admin}->get_Entries();
  my %files;
  foreach my $name (keys %$entries) {
    # Ignore any non-files in the list
    if ( $entries->{$name}->is_file() ) {
      my $full_name = File::Spec->catfile($self->get_name, $name);
      $files{$name} = VCS::LibCVS::WorkingFile->new($full_name);
    }
  }
  return \%files;
}

=head2 B<get_directory_branch()>

$local_dir->get_directory_branch()

=over 4

=item return type: VCS::LibCVS::DirectoryBranch

=back

Returns the DirectoryBranch that this local directory is on, as determined by
any sticky tag.

=cut

sub get_directory_branch {
  my $self = shift;

  return VCS::LibCVS::DirectoryBranch->new($self->get_remote_object(),
                                           $self->{Admin}->get_Tag());
}

=head2 B<get_unmanaged_files()>

$u_files = $l_dir->get_unmanaged_files()

=over 4

=item return type: ref to hash

keys are the names of files, relative to this directory.  values are objects of
type VCS::LibCVS::WorkingUnmanagedFile.

=back

Return the list of files which are neither scheduled for addition, checked-out
from the repository, nor ignored.

Note that there may be a file in the repository with the same name as one
returned by this routine.  This is a conflict situation.

=cut

sub get_unmanaged_files {
  my $self = shift;

  # Managed files
  my $m_files = $self->get_files();

  # To check if files are to be ignored
  my $ignorer = $self->get_repository()->get_ignoreChecker();

  # All files in the directory
  my $dir = IO::Dir->new($self->get_name());
  my @entries = $dir->read();
  $dir->close();

  # Holds the hash of unmanaged files
  my %u_files;
  foreach my $name (@entries) {
    my $full_name = File::Spec->catfile($self->get_name(), $name);
    # Throws exceptions if the file is not right
    my $u_file;
    eval {
      $u_file = VCS::LibCVS::WorkingUnmanagedFile->new($full_name);
      $u_files{$name} = $u_file;
    };
  }

  return \%u_files;
}

=head2 B<get_directories()>

$s_dirs = $l_dir->get_directories()

=over 4

=item return type: ref to hash

keys are the names of directories, relative to this directory.  values are
objects of type VCS::LibCVS::WorkingDirectory.

=back

Returns the CVS managed directories in this directory, as specified locally in
the CVS sandbox administrative directory.

=cut

sub get_directories {
  my $self = shift;
  my $entries = $self->{Admin}->get_Entries();
  my %dirs;
  foreach my $name (keys %$entries) {
    # Ignore any non-directories in the list
    if ( $entries->{$name}->is_directory() ) {
      my $full_name = File::Spec->catfile($self->get_name, $name);
      $dirs{$name} = VCS::LibCVS::WorkingDirectory->new($full_name);
    }
  }
  return \%dirs;
}

###############################################################################
# Private routines
###############################################################################

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  my $l_dir = $self->get_name();
  my $root_repo_dir = $self->{Admin}->get_Root()->{RootDir};
  my $within_repo_dir = $self->{Admin}->get_Repository()->as_string();
  my $r_dir = File::Spec::Unix->catdir($root_repo_dir, $within_repo_dir);
  return [ $l_dir, $r_dir ];
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::RepositoryDirectory;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::RepositoryDirectory - A Directory in the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a directory in the CVS repository.

=head1 SUPERCLASS

VCS::LibCVS::RepositoryFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/RepositoryDirectory.pm,v 1.10 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::RepositoryFileOrDirectory");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_files()>

@r_files = $r_dir->get_files({ Recursive => 0 })

=over 4

=item argument 1 type: hash ref to options

=item return type: list of VCS::LibCVS::RepositoryFile

=back

Return a complete list of CVS files, regardless of which branches they are on,
and whether they are alive or dead.  The Recursive option may be set, to return
all files in all subdirectories also, or the default which is to return only
files in this directory.

Available options are: "Recursive".

=cut

sub get_files {
  my $self = shift;
  my $options = shift || {};

  # For recursive mode, the rlog command is used to fetch the list of files.
  # log isn't appropriate for this because log requires each directory to be
  # reported as a working directory.  For non-recursive mode, the log command
  # is used.  It's better than rlog for this because some older versions (at
  # least 1.11.1p1) of log don't respect the "-l" option.  In both cases the
  # "-R" option is used to output just the names of the RCS files, since that's
  # all that's needed.

  my $command_name = ($options->{Recursive}) ? "rlog" : "log";
  my $command = VCS::LibCVS::Command->new({}, $command_name, ["-R"], [$self]);
  $command->issue($self->get_repository());

  # The filenames are returned as messages, containing absolute paths to the
  # RCS files on the cvs server machine.  They are cleaned up by making them
  # relative to the repository root directory, removing the ",v", and the
  # optional Attic.  Then a RepositoryFile object is created for each one.

  my $repo_root = $self->get_repository()->get_root()->get_dir();
  my @files = map {
    $_ =~ s#^$repo_root/(.*?)(Attic/)?([^/]*)?,v#$1$3#;
    VCS::LibCVS::RepositoryFile->new($self->{Repository}, $_);
  } $command->get_messages(",v\$");

  return \@files;
}

=head2 B<get_file()>

$r_file = $r_dir->get_file($name)

=over 4

=item argument 1 type: scalar string, the name of the file.

=item return type: VCS::LibCVS::RepositoryFile

=back

Return a single named repository file, which is in this directory.  If there's
no such file in this directory, an exception is thrown.

=cut

sub get_file {
  my $self = shift;
  my $name = $self->get_name() . "/" . shift;

  return VCS::LibCVS::RepositoryFile->new($self->{Repository}, $name);
}

=head2 B<get_directories()>

@r_files = $r_dir->get_directories()

=over 4

=item return type: list of VCS::LibCVS::RepositoryDirectory

=back

=cut

sub get_directories {
  confess "Not Implemented";
}

###############################################################################
# Private routines
###############################################################################

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  # Use the repository dir as the working directory required by the protocol
  return [ $self->get_name({}), $self->get_name({abs => 1}) ];
}


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

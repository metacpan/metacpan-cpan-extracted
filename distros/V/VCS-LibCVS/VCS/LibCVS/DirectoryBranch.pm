#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::DirectoryBranch;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::DirectoryBranch - A CVS managed directory, viewed from a branch.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a directory managed by CVS, viewed from a specific branch.

When getting the files in the directory, only those on that branch will be
considered.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/DirectoryBranch.pm,v 1.11 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Directory}        VCS::LibCVS::RepositoryDirectory
# $self->{TagSpec}          VCS::LibCVS::Datum::TagSpec of the Branch
#                           For the main branch/trunk its value is undef

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$dir_branch = VCS::LibCVS::DirectoryBranch->new($dir, $tag_spec)

=over 4

=item return type: VCS::LibCVS::DirectoryBranch

=item argument 1 type: VCS::LibCVS::RepositoryDirectory

=item argument 2 type: VCS::LibCVS::Datum::TagSpec

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  ($that->{Directory}, $that->{TagSpec}) = @_;

  if ($that->{TagSpec}) {
    my $tag_type = $that->{TagSpec}->get_type();

    # If it's a branch tag, everything is fine
    if ($tag_type eq VCS::LibCVS::Datum::TagSpec::TYPE_BRANCH) {
    }
    # If it's a date tag, then it's on the trunk, so make it undef
    elsif ($tag_type eq VCS::LibCVS::Datum::TagSpec::TYPE_DATE) {
      delete($that->{TagSpec});
    }
    # If it's a non-branch tag, guess the branch tag from one of the files
    elsif ($tag_type eq VCS::LibCVS::Datum::TagSpec::TYPE_NONBRANCH) {
      confess "This code is broken.  See Issue 35";
    }
    # Revision sticky tags for directories are unlikely to correspond to a
    # single branch for all files in that directory, so throw an exception.
    elsif ($tag_type eq VCS::LibCVS::Datum::TagSpec::TYPE_REVISION) {
      confess "Cannot create a DirectoryBranch with a revision sticky tag.";
    }
  }
  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_directory()>

$dir = $dir_branch->get_directory()

=over 4

=item return type: VCS::LibCVS::RepositoryDirectory

=back

=cut

sub get_directory() {
  return shift->{Directory};
}

=head2 B<get_tag()>

$tag = $dir_branch->get_tag()

=over 4

=item return type: VCS::LibCVS::Datum::TagSpec

=back

=cut

sub get_tag() {
  return shift->{TagSpec};
}

=head2 B<get_file_branches()>

$file_bs = $dir_branch->get_file_branches()

=over 4

=item return type: ref to hash of string -> VCS::LibCVS::FileBranch

Keys are the names of the files without directory specified
Values are VCS::LibCVS::FileBranch objects

=back

For each file in this directory, on this branch, return a FileBranch object.

It doesn't include files whose tip revision on this branch is dead.

=cut

sub get_file_branches {
  my $self = shift;

  # To get the list of files, just do a "cvs up -r"

  # Since only one directory is specified with a Directory request, there is no
  # need to submit a "-l" argument to avoid recursion.

  # Specify the tag, or no tag for the trunk
  my $tag_spec = $self->{TagSpec};
  my $tag_arg = (defined $tag_spec) ? [ "-r" . $tag_spec->get_name() ] : [];
  my $dir = $self->get_directory();
  my $command = VCS::LibCVS::Command->new({}, "update", $tag_arg, [$dir]);

  $command->issue($self->get_directory->get_repository());

  # We are only interested in the updated responses
  my @resps = $command->get_responses("VCS::LibCVS::Client::Response::Updated");
  my %results;
  foreach my $resp (@resps) {
    # Construct the name of the specified file.  Its basename is specified in
    # the first datum of the response (a pathname).  Its directory is the
    # fullname of this object.
    my ($basename) = ( $resp->data()->[0]->{RemoteFile} =~ m#^.*/([^/]*)# );
    my $name = File::Spec::Unix->catfile($dir->get_name(), $basename);
    # Construct a filebranch
    my $file = VCS::LibCVS::RepositoryFile->new($dir->get_repository(), $name);
    my $file_branch = VCS::LibCVS::FileBranch->new($file, $tag_spec, undef);
    $results{$basename} = $file_branch;
  }
  return \%results;
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

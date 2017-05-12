#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Admin;

use strict;
use Carp;

use FileHandle;

use VCS::LibCVS::Datum;

=head1 NAME

VCS::LibCVS::Admin - The CVS sandbox administrative directory.

=head1 SYNOPSIS

  $admin_dir = VCS::LibCVS::Admin->new("/home/alex/wrk/libcvs/Perl");
  $entries = $admin->get_Entries;
  $tag = $admin->get_Tag;

=head1 DESCRIPTION

Admin represents the administrative information used for managing the
checked-out files in the sandbox.  Each instance of Admin reprsents this
information for the contents of a single directory.

In order to be compatible with other CVS implementations, the default is to use
a subdirectory of the indicated directory named "CVS".  It should contain at
least the three files "Entries", "Root" and "Repository".  To use a different
name, change $VCS::LibCVS::Admin_Dir_Name.

The administrative information is accessed through objects which are subclasses
of LibCVS::Datum.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Admin.pm,v 1.18 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{AdminDirName}   The filesystem name of the directory containing
#                         the administrative files eg /home/alex/wrk/mod1/CVS
# $self->{DirName}        The filesystem name of the directory containing
#                         the CVS managed files eg /home/alex/wrk/mod1

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$admin_dir = Admin->new($directory_name)

=over 4

=item return type: VCS::LibCVS::Admin

A new Admin.

=item argument 1 type: scalar string

The name of directory in the file system.  This should not end in a slash.

=back

Creates a new Admin.  The administrative information is assumed to be in a
subdirectory called CVS (or value of $VCS::LibCVS::Admin_Dir_Name) of the
specified directory.

=cut

sub new {
  my ($class, $dir) = @_;

  my $admin_dir = File::Spec->catpath('', $dir, $VCS::LibCVS::Admin_Dir_Name);
  confess "No CVS admin directory: $admin_dir" unless -d $admin_dir;

  my $that = bless {}, $class;
  $that->{DirName} = $dir;
  $that->{AdminDirName} = $admin_dir;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_dir_name()>

$dir_name = $admin->get_dir_name()

=over 4

=item return type: scalar string

=back

Returns the name of the local directory whose administrative data this object
represents.

=cut

sub get_dir_name {
  my $self = shift;
  return $self->{DirName};
}

=head2 B<get_Entries()>

$entries = $admin->get_Entries()

=over 4

=item return type: ref to hash

keys are filenames as strings, values are VCS::LibCVS::Datum::Entry

=back

Returns the list of CVS managed files in the directory.  They are stored in a
hash with relative filenames as keys and LibCVS::Datum::Entry objects as values.

=cut

sub get_Entries {
  my $self = shift;

  # A line with just a D, means that subdirectories have not been recorded.
  # Remember if it's found, and look for them manually.
  my $sub_dirs_not_included = 0;

  my $filename = File::Spec->catpath('', $self->{AdminDirName}, "Entries");
  my $fh = FileHandle->new($filename);
  confess "Couldn't open $filename" unless defined $fh;
  my $entries = {};
  foreach my $entry_line ($fh->getlines()) {
    if ($entry_line =~ /^D$/) {
      $sub_dirs_not_included = 1;
      next;
    }
    my $entry = VCS::LibCVS::Datum::Entry->new($entry_line);
    $entries->{$entry->name} = $entry;
  }

  # Do the manual check for directories if necessary.
  if ($sub_dirs_not_included) {
    # Get the name of the parent directory.
    my @splitdirs = File::Spec->splitdir($self->{AdminDirName});
    pop @splitdirs;
    my $parent = File::Spec->catdir(@splitdirs);

    # Traverse all of its directory entries.
    my $parent_dir = IO::Dir->new($parent) || confess("Can't opendir $parent");
    foreach my $subdir ($parent_dir->read()) {
      next if $subdir =~ /\.\.?/;
      next if $subdir eq $VCS::LibCVS::Admin_Dir_Name;
      # Skip it if it was already found in the Entries file.
      next if defined $entries->{$subdir};
      # Skip it unless it has a subdirectory called CVS.
      next unless
        -d File::Spec->catdir(($parent, $subdir, $VCS::LibCVS::Admin_Dir_Name));

      # Create a new entry for it.
      $entries->{$subdir} = VCS::LibCVS::Datum::Entry->new("D/$subdir////");
    }
  }

  return $entries;
}

=head2 B<get_Root()>

$root = $admin->get_Root()

=over 4

=item return type: LibCVS::Datum::Root

=back

Returns the CVS Root for the directory.

=cut

sub get_Root {
  my $self = shift;

  my $filename = $self->{AdminDirName} . "/Root";
  my $fh = FileHandle->new($filename);
  return VCS::LibCVS::Datum::Root->new($fh->getline);
}

=head2 B<get_Repository()>

$rep_dir = $admin->get_Repository()

=over 4

=item return type: VCS::LibCVS::Datum::DirectoryName

=back

Returns the name of the repository directory for this directory, relative to
the root of the repository.

=cut

sub get_Repository {
  my $self = shift;

  my $filename = $self->{AdminDirName} . "/Repository";
  my $fh = FileHandle->new($filename);
  my $repodir = $fh->getline();
  my $root = $self->get_Root()->as_string();
  $repodir =~ s#^$root/(.*)#$1#;
  return VCS::LibCVS::Datum::DirectoryName->new($repodir);
}

=head2 B<get_Tag()>

$tag = $admin->get_Tag()

=over 4

=item return type: LibCVS::Datum::TagSpec

=back

Returns the sticky tag specification for this directory.  If there is no sticky
tag, it returns undef.

=cut

sub get_Tag {
  my $self = shift;

  my $filename = $self->{AdminDirName} . "/Tag";
  return undef unless -e $filename;
  my $fh = FileHandle->new($filename);
  return VCS::LibCVS::Datum::TagSpec->new($fh->getline);
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;

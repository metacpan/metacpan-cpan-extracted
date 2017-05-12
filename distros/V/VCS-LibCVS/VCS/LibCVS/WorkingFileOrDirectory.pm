#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::WorkingFileOrDirectory;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::WorkingFileOrDirectory - Something checked out with CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

A WorkingFileOrDirectory is the working version of something checked out of
CVS.  It implements a small amount of common functionality between files and
directories.

The filename used to contruct the object may be relative or absolute, and is
stored as such, so be careful if you changed the current directory.

There should be no need to create this object directly.  Use WorkingFile and
WorkingDirectory instead.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/WorkingFileOrDirectory.pm,v 1.6 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Admin}     Object of type VCS::LibCVS::Admin.  Created by the
#                    constructors in the subclasses.
#
# $self->{FileSpec}  Path of $self in the local filesystem
#                    Canonized with File::Spec.  Relative or absolute.

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$working_thing = VCS::LibCVS::WorkingFileOrDirectory->new($filename)

=over 4

=item return type: VCS::LibCVS::WorkingFileOrDirectory

=item argument 1 type: scalar string

The name of a file or directory which is under CVS control.

=back

Creates a new WorkingFileOrDirectory.  There's little good reason to call this
constructor, instead you'll want to call the constructors of WorkingFile and
WorkingDirectory, since they provide the fun routines.

The filename used to contruct the object may be relative or absolute, and is
stored as such.

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  # Clean up the path
  $that->{FileSpec} = File::Spec->canonpath(shift);

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

  my $path = $self->{FileSpec};
  $path = File::Spec->rel2abs($path) if ($opts->{abs});

  my ($vol, $dir, $base) = File::Spec->splitpath($path);

  return $base if ($opts->{no_dir});

  $path = File::Spec->catpath($vol, $dir, $opts->{no_base} ? "" : "$base");
  # If there's no $dir, then it's the current dir, so return that
  $path ||= File::Spec->curdir();
  return File::Spec->canonpath($path);
}

=head2 B<get_repository()>

$rep = $l_obj->get_repository()

=over 4

=item return type: VCS::LibCVS::Repository

Returns the repository in which this managed object lives.

=back

It reads the CVS sandbox administrative directory to get this info.

=cut

sub get_repository {
  my $self = shift;
  return VCS::LibCVS::Repository->new($self->{Admin}->get_Root());
}

=head2 B<get_remote_object()>

$r_obj = $l_obj->get_remote_object()

=over 4

=item return type: VCS::LibCVS::ManagedObject

Returns the remote object associated with this local object.

=back

It reads the CVS sandbox administrative directory to get this info.

=cut

sub get_remote_object {
  confess "Should be implemented in subclass.";
}

=head2 B<get_branch()>

$branch = $l_obj->get_branch()

=over 4

=item return type: VCS::LibCVS::Branch

Returns the branch this local object is on.

=back

If there is no sticky branch tag, it returns the MAIN branch.

=cut

sub get_branch {
  confess "Not Implemented";
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

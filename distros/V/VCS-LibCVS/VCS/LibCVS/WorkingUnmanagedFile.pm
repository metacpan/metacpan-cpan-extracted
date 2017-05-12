#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::WorkingUnmanagedFile;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::WorkingUnmanagedFile - A file which is not managed by CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents a file not from CVS.

=head1 SUPERCLASS

VCS::LibCVS::WorkingFileOrDirectory

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/WorkingUnmanagedFile.pm,v 1.9 2005/10/10 12:52:11 dissent Exp $ ';

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

$unmanaged_file = VCS::LibCVS::WorkingUnmanagedFile->new($filename)

=over 4

=item return type: VCS::LibCVS::WorkingUnmanagedFile

=item argument 1 type: scalar string

The name of the file which is not under CVS control.

=back

Creates a new WorkingUnmanagedFile.  The filename may be relative or absolute,
and is stored as such.

It throws an exception if the file is recorded in the CVS/Entries file, or
should be ignored by CVS.

=cut

sub new {
  my $class = shift;
  my $that = $class->SUPER::new(@_);
  my $full_name = $that->get_name();

  # Check if the file is managed by CVS
  $that->{Admin} = VCS::LibCVS::Admin->new($that->get_name({no_base => 1}));
  my $ent = $that->{Admin}->get_Entries()->{$that->get_name({no_dir => 1})};
  confess "$full_name is managed by CVS" if $ent;

  # Check if the file should be ignored by CVS
  my $ignorer = $that->get_repository()->get_ignoreChecker();
  confess "No such file $full_name" unless -f $full_name;
  confess "That's the admin dir" if $full_name eq $VCS::LibCVS::Admin_Dir_Name;
  confess "$full_name is being ignored" if $ignorer->ignore_check($full_name);

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<is_in_the_way()>

if ($u_file->is_in_the_way()) {

=over 4

=item return type: boolean scalar

=back

Returns true if there is a file or a directory in the repository with the same
name as this file.  This file is in the way because it prevents the update from
the repository.

An unusual case occurs if this file has the same contents as the one in the
repository.  In this case, "cvs update" will add the local administrative
information and not report "in the way".  This routine will still return true
in that case.

=cut

# Perhaps make it return an enumerated state.  See bug #14189.

sub is_in_the_way {
  my $self = shift;

  # Issue an update command.  If it returns "nothing known about", then the
  # file is not in the way.  In any other case it is in the way, either because
  # a directory is there, or another file.
  my $up_c = new VCS::LibCVS::Command({}, "update", ["-ld"], [$self]);
  $up_c->issue($self->get_repository());
  my @errors = $up_c->get_errors("nothing known about");
  return !@errors;
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS

=cut

# Directory names for reporting to the server.
# Routine called in Command.pm, see there for more details.
sub _get_repo_dirs {
  my $self = shift;
  my $l_dir = $self->get_name({no_base => 1});
  my $root_repo_dir = $self->{Admin}->get_Root()->{RootDir};
  my $within_repo_dir = $self->{Admin}->get_Repository()->as_string();
  my $r_dir = File::Spec::Unix->catdir($root_repo_dir, $within_repo_dir);

  return [ $l_dir, $r_dir ];
}

1;

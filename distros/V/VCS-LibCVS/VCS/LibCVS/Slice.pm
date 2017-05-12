#
# Copyright (c) 2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Slice;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Slice - A slice through a CVS Repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

A set of revisions in the repository, with at most one revision per file.
Common examples of slices are the revisions of all files in a directory
at a specific time, or all file revisions with a specific tag.

A slice is used to manipulate sets of revisions for operations such as
tagging and retrieving known configurations.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Slice.pm,v 1.2 2005/09/10 02:20:31 dissent Exp $ ';

###############################################################################
# Private variables
###############################################################################

# $self->{Revisions}  A hash ref containing the FileRevisions in this Slice
#                     Keys are the names of the files
#                     Values are FileRevision objects

###############################################################################
# Class routines
###############################################################################

sub new {
  my $class = shift;
  my $that = bless {}, $class;
  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_revision()>

$file_rev = $slice->get_revision($file)

=over 4

=item argument 1 type: VCS::LibCVS::RepositoryFile

=item return type: VCS::LibCVS::FileRevision

=back

Returns the revision of the given file in this slice, or undef if there isn't
one.

=cut

sub get_revision() {
  my $self = shift;
  my $file = shift;
  return $self->{Revisions}->{$file->get_name()};
}

=head2 B<get_revisions()>

@file_revs = $slice->get_revisions()

=over 4

=item return type: ref to array of VCS::LibCVS::FileRevision

=back

Returns all the revisions in this slice, in a list.

=cut

sub get_revisions() {
  my $self = shift;
  my $file = shift;
  return values(%{$self->{Revisions}});
}

=head2 B<add_revision()>

$slice->add_revision($file_rev)

=over 4

=item argument 1 type: VCS::LibCVS::FileRevision

=item return type: void

=back

Adds the provided FileRevision to the slice.  If the file already has a
revision in this slice, it is overwritten.

=cut

sub add_revision() {
  my $self = shift;
  my $file_rev = shift;
  $self->{Revisions}->{$file_rev->get_file()->get_name()} = $file_rev;
}

=head2 B<tag()>

$slice->tag($tag_name)

=over 4

=item argument 1 type: string

=item return type: void

=back

Tag the revisions in this slice with the given tag_name.  If you want to create
a branch at these revisions, use branch() instead.

=cut

sub tag() {
  my $self = shift;
  my $tag_name = shift;
  my @file_revs = values %{$self->{Revisions}};
  my $command = VCS::LibCVS::Command->new({}, "tag", ["$tag_name"], \@file_revs);
  $command->issue($file_revs[0]->get_file()->get_repository());
  # issue() will throw an exception if there is an error.
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

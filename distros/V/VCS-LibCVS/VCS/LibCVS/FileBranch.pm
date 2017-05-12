#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::FileBranch;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::FileBranch - A specific branch of a file managed by CVS.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a single branch of a file managed by CVS.

Branches are identified by revision numbers, but most have branch tags in
addition.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/FileBranch.pm,v 1.13 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{File}            VCS::LibCVS::RepositoryFile of this FileBranch
# $self->{TagSpec}         VCS::LibCVS::Datum::TagSpec of the FileBranch
#                          It's undef for the main branch/trunk
# $self->{RevisionNumber}  VCS::LibCVS::Datum::RevisionNumber of this FileBranch

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$file_branch = VCS::LibCVS::FileBranch->new($file, $tag_spec, $revision)

=over 4

=item return type: VCS::LibCVS::FileBranch

=item argument 1 type: VCS::LibCVS::RepositoryFile

=item argument 2 type: VCS::LibCVS::Datum::TagSpec

=item argument 3 type: VCS::LibCVS::Datum::RevisionNumber

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  ($that->{File}, $that->{TagSpec}, $that->{RevisionNumber}) = @_;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_revision_number()>

$file = $file_branch->get_revision_number()

=over 4

=item return type: VCS::LibCVS::RevisionNumber

=back

=cut

sub get_revision_number() {
  return shift->{RevisionNumber};
}

=head2 B<get_file()>

$file = $file_branch->get_file()

=over 4

=item return type: VCS::LibCVS::RepositoryFile

=back

=cut

sub get_file() {
  return shift->{File};
}

=head2 B<get_tag()>

$tag = $file_branch->get_tag()

=over 4

=item return type: VCS::LibCVS::Datum::TagSpec

=back

=cut

sub get_tag() {
  return shift->{TagSpec};
}

=head2 B<get_tip_revision()>

$file_rev = $file_branch->get_tip_revision()

=over 4

=item return type: VCS::LibCVS::FileRevision

=back

Return the latest revision (the tip) of the branch.

=cut

sub get_tip_revision() {
  my $self = shift;
  my $log = $self->{File}->_get_log_messages();

  # The log messages are an indication of all the revisions of the file.  We go
  # through them all, and find the latest one on this branch
  my $tip_num = $self->{RevisionNumber};
  foreach my $rev_str (keys %$log) {
    my $rev = VCS::LibCVS::Datum::RevisionNumber->new($rev_str);
    # Only compare revision numbers on this branch.
    if ($rev->branch_of()->equals($self->{RevisionNumber})) {
      if (   $tip_num->compare($rev)
          == VCS::LibCVS::Datum::RevisionNumber::COMPARE_DESCENDANT) {
        $tip_num = $rev;
      }
    }
  }
  return VCS::LibCVS::FileRevision->new($self->{File}, $tip_num);
}

=head2 B<get_first_revision()>

$file_rev = $file_branch->get_first_revision()

=over 4

=item return type: VCS::LibCVS::FileRevision

=back

Return the first revision of the branch.  For the trunk, this is 1.1 or
equivalent.  For a branch it's the revision on the parent branch that it
sprouts from.  The revision knows that it belongs on this branch, so calling
successor() on it will return the next revision on this branch.

XXXBUG: This doesn't handle the cases where the first revision on the trunk or
the base of the branch is gone.

=cut

sub get_first_revision() {
  my $self = shift;

  if ($self->is_trunk()) {
    my $first_rev = $self->{RevisionNumber}->first_revision_of();
    return VCS::LibCVS::FileRevision->new($self->{File}, $first_rev);
  } else {
    return VCS::LibCVS::FileRevision->new($self->{File},
                                          $self->{RevisionNumber}->base_of(),
                                          $self->{RevisionNumber});
  }
}

=head2 B<get_revision($time)>

$file_rev = $file_branch->get_revision($time)

=over 4

=item argument 1 type: scalar number

Seconds since the epoch.

=item return type: VCS::LibCVS::FileRevision

=back

Return the revision of the branch at the given time.  If the branch was not
created at the time, undef is returned.  If the time is in the future an
exception is thrown (predictions of the future are not yet supported).

=cut

sub get_revision() {
  my $self = shift;
  my $time = shift;

  confess "Predictions of the future not yet supported." if ($time > time);

  # Traverse the revisions on the branch and return at the end of the branch or
  # when a revision was committed after time.  $best_rev is what we return, and
  # is always a revision committed before the time.  If the branch was created
  # after time, then we return undef.
  my $best_rev;
  my $next_rev = $self->get_first_revision();
  while ((defined $next_rev) && ($next_rev->get_time() < $time)) {
    $best_rev = $next_rev;
    $next_rev = $next_rev->get_successor();
  }
  return $best_rev;
}

=head2 B<get_branch()>

$branch = $file_branch->get_branch()

=over 4

=item return type: VCS::LibCVS::Branch

=back

Return the repository wide branch that this is part of. 

=cut

sub get_branch() {
  my $self = shift;

  return VCS::LibCVS::Branch->new($self->{File}->get_repository(),
                                  $self->{TagSpec}->get_name());
}

=head2 B<is_trunk()>

if ($file_branch->is_trunk()) { . . .

=over 4

=item return type: boolean scalar

=back

Return true if this FileBranch is the trunk, false otherwise.  A trunk branch
has no parent.

=cut

sub is_trunk {
  return shift->{RevisionNumber}->is_trunk();
}

=head2 B<get_parent()>

$parent_file_branch = $file_branch->get_parent()

=over 4

=item return type: VCS::LibCVS::FileBranch

=back

Get the FileBranch from which this FileBranch sprouts.  Throws an exception if
this is the trunk FileBranch.

Of course, due to CVS's lazy branching scheme, FileBranches on the same branch,
but for different files, may identify different branches as their parent.  See
the method precedes() for help handling this case.

=cut

sub get_parent() {
  my $self = shift;
  return $self->{File}->get_branch($self->{RevisionNumber}->base_of()->branch_of());
}

=head2 B<equals()>

if ($file_branch->equals($another_file_branch)) { . . .

=over 4

=item return type: scalar boolean

=item argument 1 type: VCS::LibCVS::FileBranch

=back

Return true if these represent the same FileBranch.

=cut

sub equals() {
  my $self = shift;
  my $other = shift;

  if (! $other->isa("VCS::LibCVS::FileBranch")) {
    return 0;
  }

  return (($self->{File}->equals($other->{File})) &&
          ($self->{TagSpec}->equals($other->{TagSpec})) &&
          ($self->{RevisionNumber}->equals($other->{RevisionNumber})));
}

=head2 B<precedes()>

if ($file_branch->precedes($another_file_branch)) { . . .

=over 4

=item return type: scalar boolean

=item argument 1 type: VCS::LibCVS::FileBranch

=back

Because of CVS's lazy branching, two branches may sprout from the same revision
on one file, while on another file, one is a subbranch of the other.  For
example: on file1 brancha is 1.3.2, and branchb is 1.3.4; while on file2
brancha is 1.8.2 and branchb is 1.8.2.6.2.  This method can help you handle
this case.  It returns true if this branch is an ancestor branch or a possible
ancestor branch of the given branch, and false otherwise.

=cut

sub precedes() {
  my $self = shift;
  my $other = shift;

  if (! $other->isa("VCS::LibCVS::FileBranch")) {
    confess("Not a FileBranch");
  }

  if (! $self->{File}->equals($other->{File})) {
    confess "precedes() only works on FileBranches of the same File.";
  }

  my $cmp = $self->{RevisionNumber}->compare($other->{RevisionNumber});

  return ($cmp == VCS::LibCVS::Datum::RevisionNumber::COMPARE_DESCENDANT) ||
    ($cmp == VCS::LibCVS::Datum::RevisionNumber::COMPARE_POSSIBLE_DESCENDANT);
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

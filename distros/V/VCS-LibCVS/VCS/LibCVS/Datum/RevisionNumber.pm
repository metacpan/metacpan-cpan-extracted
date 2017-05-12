#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::RevisionNumber;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::RevisionNumber - A CVS revision number.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a CVS revision number, either a branch or regular one.

It accepts both regular branch numbers (1.4.2) and magic ones (1.4.0.2).  This
means that numbers of the form "0.x" are ambiguous.  They are treated as
revision numbers on the branch "0".

The revision number "0" is used for added files, as well as for one of the
trunk branches.

I use the term "depth" to refer to the number of fields in a revision.  I use
the terms "ancestor" and "descendant" to refer to a relationship between two
revisions, whereby the intervening revisions increase monotonically.  Eg. 1.6
is an ancestor of 1.19 and of 1.6.4.5, but 1.19 and 1.6.4.5 are neither
ancestors nor descendants of each other.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/RevisionNumber.pm,v 1.16 2005/10/10 12:52:12 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

# COMPARE_* constants are documented in compare() routine
use constant COMPARE_EQUAL => 0;
use constant COMPARE_ANCESTOR => 1;
use constant COMPARE_DESCENDANT => 2;
use constant COMPARE_INCOMPARABLE => 3;
use constant COMPARE_POSSIBLE_ANCESTOR => 4;
use constant COMPARE_POSSIBLE_DESCENDANT => 5;

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Number} is the number as a string, with magic branch numbers
#                 converted to regular branch numbers.
# $self->{IsBranch} true if it's a branch revision number

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$rev_num = VCS::LibCVS::Datum::RevisionNumber->new("1.2.4.5")
$rev_num = VCS::LibCVS::Datum::RevisionNumber->new("1.2.0.4")
$rev_num = VCS::LibCVS::Datum::RevisionNumber->new("1.2.4")

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=item argument 1 type: scalar string

Must be a valid CVS revision number.

=back

=cut

sub new {
  my ($class, $num) = @_;
  my $that = bless {}, $class;

  # 0 may only appear by itself, or as the first field or the second to last
  confess "Bad revision number $num"
    unless ($num =~ /^0$|^(0\.)?([1-9][0-9]*\.)*(0\.)?[1-9][0-9]*$/);

  # Convert magic branch numbers to regular ones by removing the 0 in the
  # second to last place, unless it's the first number.
  $num =~ s/\.0(\.[0-9])*$/$1/;
  $that->{Number} = $num;

  # It's a branch if there are an odd number of fields
  $that->{IsBranch} = ($that->_depth() % 2);

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<as_string()>

$rev_str = $rev_num->as_string()

=over 4

=item return type: string scalar

=back

Returns the revision number as a string.

=cut

sub as_string {
  my $self = shift;
  return $self->{Number};
}

=head2 B<equals()>

if ($rev_num1->equals($rev_num2)) {

=over 4

=item return type: boolean

=item argument 1 type: VCS::LibCVS::Datum::RevisionNumber

=back

Returns true if the revision numbers contain the same information.

=cut

sub equals {
  my $self = shift;
  return 0 unless $self->SUPER::equals(@_);
  my $other = shift;
  return $self->{Number} eq $other->{Number};
}

=head2 B<is_branch()>

if ($rev_num->is_branch()) { . . .

=over 4

=item return type: boolean scalar

=back

Return true if this is a branch revision number, false otherwise.

=cut

sub is_branch {
  my $self = shift;
  return $self->{IsBranch};
}

=head2 B<is_trunk()>

if ($rev_num->is_trunk()) { . . .

=over 4

=item return type: boolean scalar

=back

Return true if this is a revision number for the trunk, false otherwise.
A trunk revision number is one with only one field, like: "1", "2", . . .

=cut

sub is_trunk {
  my $self = shift;
  return ($self->_depth() == 1);
}

=head2 B<is_import_branch()>

if ($rev_num->is_import_branch()) { . . .

=over 4

=item return type: boolean scalar

=back

Return true if this is a branch revision number for an import branch, false
otherwise.  An import branch is one with an odd revision number, which is
assumed to be the result of an import.

=cut

sub is_import_branch {
  my $self = shift;
  return (   $self->{IsBranch}
          && ($self->_depth() >= 3)
          && ($self->_last_field() % 2 == 1));
}

=head2 B<branch_of()>

$branch_num = $rev_num->branch_of()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Get the RevisionNumber for the branch on which this revision lives.  If it's a
branch revision number it throws an exception.

=cut

sub branch_of {
  my $self = shift;
  confess "No branch_of() for a branch RevisionNumber" if $self->is_branch();
  return $self->_subrevision();
}

=head2 B<base_of()>

$branch_num = $rev_num->base_of()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Returns the RevisionNumber from which this branch starts.  If it's the trunk or
a non-branch revision, an exception is thrown.

=cut

sub base_of {
  my $self = shift;
  confess "Only branch revisions have a base" unless $self->is_branch();
  confess "Main branch has no base" if $self->_depth == 1;
  return $self->_subrevision();
}

=head2 B<first_revision_of()>

$rev_num = $branch_num->first_revision_of()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Returns the RevisionNumber of the first revision committed to this branch.
This is not the same as the base of the branch, it's the branch number with a
.1 appended.

=cut

sub first_revision_of {
  my $self = shift;
  confess "Only branches have a first revision" unless $self->is_branch();
  return VCS::LibCVS::Datum::RevisionNumber->new($self->as_string() . ".1");
}

=head2 B<get_predecessor()>

$p_rev_num = $rev_num->get_predecessor()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Return the revision number that immediately preceeds this one, it's youngest
ancestor.  Return undef if there isn't one.  Throw an exception if this is a
branch revision.

=cut

sub get_predecessor {
  my $self = shift;
  if ($self->is_branch()) {
    confess "Branches don't have predecessors.";
  }
  if ($self->_last_field != 1) {
    my $rvstr = $self->_subrevision_string() . "." . ($self->_last_field() - 1);
    return VCS::LibCVS::Datum::RevisionNumber->new($rvstr);
  } else {
    if ($self->branch_of()->is_trunk()) {
      return;
    } else {
      return $self->branch_of()->base_of();
    }
  }
}

=head2 B<get_successor()>

$p_rev_num = $rev_num->get_successor()

=over 4

=item return type: VCS::LibCVS::Datum::RevisionNumber

=back

Return the revision number on the same branch that immediately follows this
one, it's eldest descendant.  Throw an exception if this is a branch revision.

=cut

sub get_successor {
  my $self = shift;
  if ($self->is_branch()) {
    confess "Branches don't have successors.";
  }
  my $rvstr = $self->_subrevision_string() . "." . ($self->_last_field() + 1);
  return VCS::LibCVS::Datum::RevisionNumber->new($rvstr);
}

=head2 B<compare()>

$diff = $rev_num1->compare($rev_num2)

=over 4

=item return type: integer, one of VCS::LibCVS::Datum::RevisionNumber::COMPARE_*

=item argument 1 type: string or RevisionNumber object

=back

Compares this revision number with the argument.

The meanings of the return values are:

=over 4

=item COMPARE_EQUAL

They are the same revision number.

=item COMPARE_ANCESTOR

The argument is an ancestor of this.

=item COMPARE_DESCENDANT

The argument is a descendant of this.

=item COMPARE_POSSIBLE_ANCESTOR

The argument is possibly an ancestor of this.

=item COMPARE_POSSIBLE_DESCENDANT

The argument is possibly a descendant of this.

=item COMPARE_INCOMPARABLE

The argument is neither an ancestor, nor a descendant of this, and they aren't
equal.

=back

Both branch and regular revision numbers can be compared this way.  A branch
revision number is an ancestor of all revisions on it (except its base
revision) and its subbranches.  So 1.6.2 is an ancestor of 1.6.2.4, a
descendant of 1.6, and incomparable with 1.7.

Branches that sprout from the same revision are possibly ancestors or
descendants.  However, this can't be known because of CVS's lazy branching.  In
this case, the values returned are COMPARE_POSSIBLE_ANCESTOR and
COMPARE_POSSIBLE_DESCENDANT.  For example, 1.11.4 is possibly and ancestor of
1.11.6.

It would be nice if 1.6 were a descendant of 1.6.2, since it's on that branch,
but then we'd lose transitivity, because then we'd have 1.6.2 < 1.6, 1.6 < 1.7,
but 1.6.2 and 1.7 are incomparable.

=cut

sub compare {
  my ($self, $other) = @_;

  if (!ref($other)) {
    $other = new VCS::LibCVS::Datum::RevisionNumber($other);
  }

  # Check revision numbers that are of the same depth.
  # Since they are of the same depth, they are either both branches, or both
  # revisions
  if ($self->_depth() == $other->_depth()) {
    # Check for trivial equality
    if ($self->equals($other)) {
      return COMPARE_EQUAL;
    }
    # Branches of the same depth that sprout from different revisions are
    # incomparable.  If they sprout from the same revision they are possibly
    # related.
    if ($self->is_branch()) {
      if (! $self->base_of()->equals($other->base_of())) {
        return COMPARE_INCOMPARABLE;
      } else {
        return ($other->_last_field > $self->_last_field)
          ? COMPARE_POSSIBLE_DESCENDANT : COMPARE_POSSIBLE_ANCESTOR;
      }
    }
    # For revisions, check that they are on the same branch, then check their
    # last field
    if ($self->branch_of()->equals($other->branch_of)) {
      return ($other->_last_field > $self->_last_field)
        ? COMPARE_DESCENDANT : COMPARE_ANCESTOR;
    }
    # They are revisions on different branches
    return COMPARE_INCOMPARABLE;
  }

  # The revision numbers are of different depths

  # Reduce the deep revision to the same depth as the shallow revision, and
  # then compare them.
  my $shallow_rev = ($self->_depth > $other->_depth) ? $other : $self;
  my $deep_rev = ($self->_depth > $other->_depth) ? $self : $other;
  # $less_deep_rev is the ancestor of $deep_rev with the same depth as
  # $shallow_rev
  my $less_deep_rev = $deep_rev;
  while ($shallow_rev->_depth() != $less_deep_rev->_depth()) {
    $less_deep_rev = $less_deep_rev->_subrevision();
  }

  # Compare $shallow_rev and $less_deep_rev
  my $result = $shallow_rev->compare($less_deep_rev);

  # Adjust $result to be correct for $shallow_rev->compare($deep_rev)
  # eg $shallow_rev is 1.6, $deep_rev is 1.6.4.3
  $result = COMPARE_DESCENDANT if ($result == COMPARE_EQUAL);

  # eg $shallow_rev is 1.4, $deep_rev is 1.6.4.3
  $result = COMPARE_DESCENDANT if ($result == COMPARE_DESCENDANT);

  # eg $shallow_rev is 1.8, $deep_rev is 1.6.4.3
  $result = COMPARE_INCOMPARABLE if ($result == COMPARE_ANCESTOR);

  $result = COMPARE_INCOMPARABLE if ($result == COMPARE_INCOMPARABLE);

  # Adjust $result to be correct for $self->compare($other)
  # Only COMPARE_DESCENDANT and COMPARE_INCOMPARABLE are possible
  if (($self->_depth > $other->_depth) && $result == COMPARE_DESCENDANT) {
    $result = COMPARE_ANCESTOR;
  }
  return $result;
}

###############################################################################
# Private routines
###############################################################################

# Create new revision number with one less field, as a string
sub _subrevision_string {
  my $self = shift;
  my ($sub_num) = ($self->{Number} =~ /^(.*)\.[0-9]+$/);
  return $sub_num;
}

# Create new RevisionNumber with one less field
sub _subrevision {
  return VCS::LibCVS::Datum::RevisionNumber->new(shift->_subrevision_string());
}

# Get the depth of the revision, ie. the number of fields.
sub _depth {
  my $self = shift;
  my $depth = (my @t = split(/\./, "$self->{Number}"));
  return $depth;
}

# The last field of this revision number
sub _last_field {
  my $self = shift;
  my ($self_field) = ($self->{Number} =~ /.*\.([0-9]+)/);
  return $self_field;
}

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;

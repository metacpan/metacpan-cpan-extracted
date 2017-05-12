#
# Copyright (c) 2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Branch;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Branch - A named branch in the repository.

=head1 SYNOPSIS

=head1 DESCRIPTION

Represents a named branch in the repository.

This branch may exist on any number of files.  This class is not much more than
a wrapper around a branch name.

The main branch (usually branch number 1) is named using the special name
.TRUNK.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Branch.pm,v 1.4 2005/10/10 12:52:11 dissent Exp $ ';

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Repository}  The VCS::LibCVS::Repository in which the branch lives.
#
# $self->{Name}         scalar string which is the name of the branch.

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$branch = VCS::LibCVS::Branch->new($repo, $name)

=over 4

=item return type: VCS::LibCVS::Branch

=item argument 1 type: VCS::LibCVS::Repository

=item argument 2 type: scalar string

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  ($that->{Repository}, $that->{Name}) = @_;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_name()>

$b_name = $branch->get_name()

=over 4

=item return type: scalar string

=back

=cut

sub get_name() {
  return shift->{Name};
}

=head2 B<equals()>

if ($branch->equals($other_branch)) { . . .

=over 4

=item return type: scalar boolean

=back

=cut

sub equals() {
  my $self = shift;
  my $other = shift;
  return (($self->{Repository}->equals($other->{Repository}))
           && ($self->{Name} eq $other->{Name}));
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;

package VCS::CMSynergy::Tset;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

=head1 NAME

VCS::CMSynergy::Tset - convenience methods for C<VCS::CMSynergy::Object>s of type I<tset>

=head1 SYNOPSIS

C<VCS::CMSynergy::Tset> is a subclass of
L<C<VCS::CMSynergy::Object>|VCS::CMSynergy::Object>
with additional methods for Synergy I< DCM transfer sets>.

  use VCS::CMSynergy;
  $ccm = VCS::CMSynergy->new(%attr);
  ...
  $ts = $ccm->tset_object("Toolkit baselines");

  $members = $ts->show_object("direct_members");
  $ts->add(-history => @objs);
  $ts->generate(-dbid => "Any");

=cut

use base qw(VCS::CMSynergy::Object);

use File::Spec;
use Cwd;

=head1 METHODS

=head2 show

  $aref = $ts->show_hashref($what, @keywords);
  $aref = $ts->show_object($what, @keywords);

These two methods are convenience wrappers for
B<ccm dcm -ts $ts -show $what>. For return values and the
meaning of the optional C<@keywords> parameters see the descriptions
of L<query_hashref|VCS::CMSynergy/"query_arrayref, query_hashref">
and L<query_object|VCS::CMSynergy/query_object>.

The following strings can be used for C<$what>, see the Synergy documentation
of the B<ccm dcm -show> sub command for their meaning:

=over 5

=item direct_members
Equivalent to "-members direct".

=item all_members
Equivalent to "-members all".

=back

=cut

# don't blame errors from _must_be_one_of below on one of these
use vars qw(@ISA);
our @CARP_NOT = ("VCS::CMSynergy", @ISA);

sub _show
{
    my ($self, $what, $keywords, $row_type) = @_;

    VCS::CMSynergy::_must_be_one_of($what, qw( direct_members all_members ));
    $what =~ s/_members$//;

    return $self->ccm->_generic_show(
        [ qw( dcm -show -ts ), $self, -members => $what ], $keywords, $row_type);
}

sub add
{
    my $self = shift;
    return $self->ccm->dcm(-ts => $self, -add => @_);
}

sub remove
{
    my $self = shift;
    return $self->ccm->dcm(-ts => $self, -remove => @_);
}

sub recompute
{
    my $self = shift;
    return $self->ccm->dcm(-ts => $self, -recompute => @_);
}

sub delete
{
    my $self = shift;
    return $self->ccm->dcm(-ts => $self, "-delete");
}

sub generate
{
    my $self = shift;
    return $self->ccm->dcm(-ts => $self, -generate => @_);
}


1;

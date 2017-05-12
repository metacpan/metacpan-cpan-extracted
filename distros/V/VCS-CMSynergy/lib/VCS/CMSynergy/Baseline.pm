package VCS::CMSynergy::Baseline;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

=head1 NAME

VCS::CMSynergy::Baseline - convenience methods for C<VCS::CMSynergy::Object>s of type I<baseline>

=head1 SYNOPSIS

C<VCS::CMSynergy::Baseline> is a subclass of
L<C<VCS::CMSynergy::Object>|VCS::CMSynergy::Object>
with additional methods for Synergy I<baselines>.

  use VCS::CMSynergy;
  $ccm = VCS::CMSynergy->new(%attr);
  ...
  $bsl = $ccm->object("20080527 Platform Game 1.1 Release~1:baseline:1");

  $projects = $bsl->show_object("projects");
  $tasks = $bsl->show_object(tasks => qw( task_synopsis completion_date ));

=cut

use base qw(VCS::CMSynergy::Object);

use File::Spec;
use Cwd;

=head1 METHODS

=head2 show

  $aref = $pg->show_hashref($what, @keywords);
  $aref = $pg->show_object($what, @keywords);

These two methods are convenience wrappers for
B<ccm baseline -show $what>. For return values and the
meaning of the optional C<@keywords> parameters see the descriptions
of L<query_hashref|VCS::CMSynergy/"query_arrayref, query_hashref">
and L<query_object|VCS::CMSynergy/query_object>.

The following strings can be used for C<$what>, see the Synergy documentation
of the B<ccm baseline -show> sub command for their meaning:

=over 5

=item *
change_requests

=item *
component_tasks

=item *
fully_included_change_requests

=item *
partially_included_change_requests

=item *
projects

=item *
objects

=item *
tasks

=back

=cut

# don't blame errors from _must_be_one_of below on one of these
use vars qw(@ISA);
our @CARP_NOT = ("VCS::CMSynergy", @ISA);

sub _show
{
    my ($self, $what, $keywords, $row_type) = @_;

    VCS::CMSynergy::_must_be_one_of($what,
        qw( change_requests component_tasks
            fully_included_change_requests partially_included_change_requests
            projects objects tasks ));

    return $self->ccm->_generic_show(
        [ baseline => $self, -show => $what ], $keywords, $row_type);
}

1;

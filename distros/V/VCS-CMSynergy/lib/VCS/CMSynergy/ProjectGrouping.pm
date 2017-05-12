package VCS::CMSynergy::ProjectGrouping;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

=head1 NAME

VCS::CMSynergy::ProjectGrouping - convenience methods for C<VCS::CMSynergy::Object>s of type I<project_grouping>

=head1 SYNOPSIS

C<VCS::CMSynergy::ProjectGrouping> is a subclass of
L<C<VCS::CMSynergy::Object>|VCS::CMSynergy::Object>
with additional methods for Synergy I<project_groupings>.

  use VCS::CMSynergy;
  $ccm = VCS::CMSynergy->new(%attr);
  ...
  $proj = $ccm->object("editor-1:project:1");
  $pg = $proj->project_grouping();

  $projects = $pg->show_object("projects");
  $tasks = $pg->show_object(
    tasks_on_top_of_baseline => qw( task_synopsis completion_date ));

=cut

use base qw(VCS::CMSynergy::Object);

use File::Spec;
use Cwd;

=head1 METHODS

=head2 show

  $aref = $pg->show_hashref($what, @keywords);
  $aref = $pg->show_object($what, @keywords);

These two methods are convenience wrappers for
B<ccm project_grouping -show $what>. For return values and the
meaning of the optional C<@keywords> parameters see the descriptions
of L<query_hashref|VCS::CMSynergy/"query_arrayref, query_hashref">
and L<query_object|VCS::CMSynergy/query_object>.

The following strings can be used for C<$what>, see the Synergy documentation
of the B<ccm project_grouping -show> sub command for their meaning:

=over 5

=item *
added_tasks

=item *
all_tasks

=item *
automatic_tasks

=item *
baseline

=item *
folders

=item *
objects

=item *
projects

=item *
removed_tasks

=item *
tasks_on_top_of_baseline

=back

=cut

# don't blame errors from _must_be_one_of below on one of these
use vars qw(@ISA);
our @CARP_NOT = ("VCS::CMSynergy", @ISA);

sub _show
{
    my ($self, $what, $keywords, $row_type) = @_;

    VCS::CMSynergy::_must_be_one_of($what,
        qw( added_tasks all_tasks automatic_tasks
            baseline folders objects projects
            removed_tasks tasks_on_top_of_baseline ));

    return $self->ccm->_generic_show(
        [ project_grouping => $self, -show => $what ], $keywords, $row_type);
}

1;

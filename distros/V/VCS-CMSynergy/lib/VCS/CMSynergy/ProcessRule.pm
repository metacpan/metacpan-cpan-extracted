package VCS::CMSynergy::ProcessRule;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

=head1 NAME

VCS::CMSynergy::ProcessRule - convenience methods for C<VCS::CMSynergy::Object>s of type I<process_rule>

=head1 SYNOPSIS

C<VCS::CMSynergy::ProcessRule> is a subclass of
L<C<VCS::CMSynergy::Object>|VCS::CMSynergy::Object>
with additional methods for Synergy I<process_rules>.

  use VCS::CMSynergy;
  $ccm = VCS::CMSynergy->new(%attr);
  ...
  $proj = $ccm->object("editor-1:project:1");
  $pr = $proj->process_rule();

  $projects = $pr->show_object("baseline_projects");

=cut

use base qw(VCS::CMSynergy::Object);

use File::Spec;
use Cwd;

=head1 METHODS

=head2 show

  $aref = $pr->show_hashref($what, @keywords);
  $aref = $pr->show_object($what, @keywords);

These two methods are convenience wrappers for
B<ccm process_rule -show $what>. For return values and the
meaning of the optional C<@keywords> parameters see the descriptions
of L<query_hashref|VCS::CMSynergy/"query_arrayref, query_hashref">
and L<query_object|VCS::CMSynergy/query_object>.

The following strings can be used for C<$what>, see the Synergy documentation
of the B<ccm process_rule -show> sub command for their meaning:

=over 5

=item *
baseline_projects

=item *
folders

=item *
folder_templates

=back

=cut

# don't blame errors from _must_be_one_of below on one of these
use vars qw(@ISA);
our @CARP_NOT = ("VCS::CMSynergy", @ISA);

sub _show
{
    my ($self, $what, $keywords, $row_type) = @_;

    VCS::CMSynergy::_must_be_one_of($what, qw( baseline_projects folders folder_templates ));

    return $self->ccm->_generic_show(
        [ process_rule => $self, -show => $what ], $keywords, $row_type);
}

1;

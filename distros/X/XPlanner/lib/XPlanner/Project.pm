package ProjectData;

@ISA = qw(XPlanner::Project);


package XPlanner::Project;

use strict;
use base qw(XPlanner::Object);

sub _proxy_class { "ProjectData" }


=head1 NAME

XPlanner::Project - projects in XPlanner


=head1 SYNOPSIS

  use XPlanner;

  my $xp->login(...);

  my $project = $xp->projects->{"Project Name"};
  $project->delete;

  my $iterations = $project->iterations;


=head1 DESCRIPTION

An object representing a project within XPlanner.


=head2 Methods

=head3 iterations

  my $iterations = $project->iterations;

Lists all iterations of this project keyed by name.

=cut

sub iterations {
    my $self = shift;

    return $self->_map_from_soap('name', 'getIterations', 
                                 'XPlanner::Iteration');
}


=head3 delete

  $project->delete;

Deletes this project from XPlanner.

=cut

sub delete {
    my $self = shift;
    my $proxy = $self->{_proxy};

    $proxy->removeProject($self->{id});
}


=cut

1;

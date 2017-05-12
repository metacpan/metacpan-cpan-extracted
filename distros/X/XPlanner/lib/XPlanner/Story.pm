package UserStoryData;

@ISA = qw(XPlanner::Story);


package XPlanner::Story;

use strict;
use base qw(XPlanner::Object);

sub _proxy_class { "UserStoryData" }


=head1 NAME

XPlanner::Story - User stories in an iteration


=head1 SYNOPSIS

  use XPlanner;

  my $xp->login(...);

  my $iteration = $xp->projects->{"Project Name"}
                     ->iterations->{"Iteration Name"};
  my $story     = $iteration->stories->{"Some Story"};
  $story->delete;


=head1 DESCRIPTION

A story contains the following fields

These are required when creating a new story

    name
    description

These are optional

    customerId
    trackerId
    lastUpdateTime
    priority
    estimatedHours
    originalEstimatedHours
    adjustedEstimatedHours
    actualHours
    remainingHours
    completed

=cut    

sub delete {
    my $self = shift;
    my $proxy = $self->{_proxy};

    $proxy->removeUserStory($self->{id});
}

1;

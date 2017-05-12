package IterationData;

@ISA = qw(XPlanner::Iteration);


package XPlanner::Iteration;

use strict;
use base qw(XPlanner::Object);

sub _proxy_class { "IterationData" }


=head1 NAME

XPlanner::Iteration - an iteration within an XPlanner project


=head1 SYNOPSIS

  use XPlanner;

  my $xp->login(...);
  my $iteration = $xp->projects->{"Some Project"}
                     ->iterations->{"Some Iteration"};

  my $stories = $iteration->stories;

  my $story = $iteration->add_story( %story_data );


=head1 DESCRIPTION

An object representing an iteration within a project in XPlanner

=head2 Methods

=head3 add_story

  my $story = $iteration->add_story( %story_data );

Creates a new story in this $iteration.  See XPlanner::Story for what fields
should go into %story_data.

=cut

sub add_story {
    my($self, %args) = @_;
    my $proxy = $self->{_proxy};
    $args{iterationId} = $self->{id};

    my $new_story = XPlanner::Story->_init(%args);
    $proxy->addUserStory($new_story);

    return $self->stories->{$new_story->{name}};
}

sub stories {
    my $self = shift;

    return $self->_map_from_soap('name', 'getUserStories', 'XPlanner::Story');
}


1;


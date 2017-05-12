package Video::PlaybackMachine::TimeManager;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::TimeManager
####
#### $Revision$
####
#### Tells us what FillSegment to play next in a particular break.
#### Keeps track of what has been played.
####

use Moo;

use Carp;


# TODO: I'm not sure that the implemented algorithm is correct. To get
# the effects I'm looking for, basically the TimeManager should go
# through in priority order and assign time slots to the Fill
# Producers based on minimum and preferred time, stopping when we're
# full.  Actual playback then follows sequence order. Preassignment
# may be against some of the PM philosophy of constantly reacting to
# the current situation, but is essential for getting some of the
# effects that we want (such as "play fills before and after a short
# movie, and ALWAYS do station identification")
#
# Later update: The algorithm actually works as well, if not better,
# than the above. It gets the amount of time remaining, and the amount
# of time required, and the amount of time required by items of a
# higher priority, and computes the remainder.
#

############################# Attributes #############################

has 'current_seq' => (
	is => 'rw',
	default => 0
);

has 'seq_order' => (
	is => 'ro',
	default => sub { [] }
);

with 'Video::PlaybackMachine::Logger';

############################## Class Methods ##############################

sub BUILDARGS {
  my $type = shift;
  my (@segments) = @_;

  return {
  	seq_order => [ sort { $a->sequence_order() <=> $b->sequence_order() } @segments ]
  };
}

############################# Object Methods ##############################

##
## get_segment()
##
## Arguments:
##   TIME_LEFT: int -- Amount of time before next scheduled content
##
## Returns: (list)
##   FillSegment -- Next FillSegment to use
##   int -- unreserved time remaining in seconds
##
## Returns the FillSegment to use to fill up time right now. Returns
## undef if no more fill can be played.
##

# TODO: Can be simplified to a rotating index. We never play out of
# sequence.
sub get_segment {
  my $self = shift;
  my ($time_left) = @_;
  
  # For each segment starting from current in display order
  foreach my $segment ( $self->_segments_left() ) {

    $self->debug("Considering segment ", $segment->name(),  " with time left $time_left");

    # Move to next segment if we don't have time to play it
    my $time_remaining = $self->_seconds_remaining($segment, $time_left);
    $segment->is_available($time_remaining) or do {
      $self->debug("Segment ", $segment->name(), " is not available");
      next;
    };

    # Update whatever we should play next
    $self->current_seq(
    	($self->current_seq + 1) % (scalar @{ $self->seq_order } )
    );

    # Return the segment and time remaining
    return ($segment, $time_remaining);

  } # End for each unfinished segment

  # All's finished or no time; return undef
  return;
}

##
## Returns the segments still to play, in sequence order.
##
sub _segments_left {
  my $self = shift;
  return @{ $self->seq_order }[ $self->{current_seq} ... $#{ $self->{seq_order} } ];
}

##
## _seconds_remaining()
##
## Arguments:
##   CURRENT_SEGMENT: FillSegment
##   TIME_LEFT: int -- seconds
##
## Returns the amount of time in seconds remaining after
## time has been reserved for all of the segments with
## higher priorities than this.
##
# TODO Slideshow expects the time remaining to be the expected preferred time
sub _seconds_remaining {
  my $self = shift;
  my ($current_segment, $time_left_in_break) = @_;

  my $time_remaining = $time_left_in_break;
  foreach my $segment (
			   sort {$a->priority_order() <=> $b->priority_order()}
			   grep { $_->priority_order() < $current_segment->priority_order() }
			   $self->_segments_left()
			  ) 
    {
      $time_remaining > 0 or return 0;
      $segment->is_available($time_remaining) or next;
      $time_remaining -= $segment->producer()->time_layout()->preferred_time($time_remaining);
    }

  return $time_remaining;

}

no Moo;

1;

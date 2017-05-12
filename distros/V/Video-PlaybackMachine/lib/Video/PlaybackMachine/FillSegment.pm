package Video::PlaybackMachine::FillSegment;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillSegment
####
#### $Revision$
####
#### The Filler fills up time in the schedule using an ordered set of
#### FillSegments. For example, an average break sequence might
#### consist of a 'Start Identification' segment played at the
#### beginning, followed by 'Announcements', followed by 'Short
#### Subject', followed by 'End Identification'.
####

use Moo;

use Carp;

############################# Attributes #############################

has 'name' => ( is => 'ro' );

has 'sequence_order' => ( 'is' => 'ro' );

has 'priority_order' => ( 'is' => 'ro' );

has 'producer' => ( 'is' => 'ro', 'required' => 1 );

############################## Class Methods ##############################


############################# Object Methods ##############################

# Deprecate old get_ methods
{
	no strict 'refs';
	
	foreach my $attr ( qw/name producer/ ) {
		*{__PACKAGE__ . '::get_' . $attr} = sub {
			carp "Using get_${attr}() deprecated";
			return $_[0]->$attr;
		};
	}
}


##
## is_available()
##
## Arguments:
##   TIME_LEFT: int
##
## Returns:
##   boolean
##
sub is_available {
  my $self = shift;
  my ($time_left) = @_;
  defined $time_left or confess('Argument $time_left required');

  $self->producer()->is_available() or return;

  return ($self->producer->time_layout()->min_time() <= $time_left);
}


##
## get_priority()
##
## Returns the priority order of the segment.
##
sub get_priority {
	my $self = shift;
	carp "get_priority() deprecated; use priority_order() instead";
  	return $self->priority_order();
}

##
## get_sequence()
##
## Returns the sequence order of the segment.
##
sub get_sequence {
	my $self = shift;
	carp "get_sequence() deprecated; use sequence_order() instead";
  	return $self->sequence_order();
}


##
## get_next()
##
## Returns the sequence number of the FillSegment
## which should come after this one.
##
sub get_next {
  my $self = shift;
  return $self->producer->get_next( $self->sequence_order() );
}

no Moo;

1;

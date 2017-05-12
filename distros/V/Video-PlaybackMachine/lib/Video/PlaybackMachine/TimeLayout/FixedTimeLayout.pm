package Video::PlaybackMachine::TimeLayout::FixedTimeLayout;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::TimeLayout::FixedTimeLayout
####
#### $Revision$
####
#### A TimeLayout that indicates that a certain FillProducer only
#### wants to generate content for a fixed amount of time. 
####

use Moo;

has 'time' => (
	is => 'ro',
	required => 1
);

use Carp;

sub BUILDARGS {
  my $type = shift;
  my ($time) = @_;

  return  { time => $time };
}

############################# Object Methods ##############################

##
## min_time()
##
## Returns the minimum amount of time the fill can take. In this case,
## returns the fixed time.
##
sub min_time {
   my $self = shift;

  return $self->time();
}

##
## preferred_time()
##
## Arguments:
##  TIME_LEFT
##
## Returns the fixed time.
##
sub preferred_time {
	my $self = shift;

  return $self->time;
}

1;

package Video::PlaybackMachine::FillProducer::AbstractStill;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::AbstractStill
####
#### $Revision$
####
#### 
####

use Moo::Role;

use Carp;

with 'Video::PlaybackMachine::FillProducer';

use Video::PlaybackMachine::TimeLayout::FixedTimeLayout;


############################# Parameters #############################

has 'time' => (
	is => 'ro',
	required => 1
);

has 'time_layout' => (
	is => 'lazy',
);


############################# Object Methods ##############################

sub _build_time_layout {
	my $self = shift;
	
	return Video::PlaybackMachine::TimeLayout::FixedTimeLayout->new( $self->time() )
}

##
## get_time_layout()
##
## Returns the FixedTimeLayout for the appropriate time.
##
sub get_time_layout {
	my $self = shift;
	
	carp "get_time_layout() deprecated! use time_layout() instead!";
	
	return $self->time_layout();

}

##
## has_audio()
##
## Stills don't have an audio track.
##
sub has_audio { return; }

##
## is_available()
##
## Stills are always available. Unless they aren't.
##
sub is_available { 1; }

no Moo::Role;

1;

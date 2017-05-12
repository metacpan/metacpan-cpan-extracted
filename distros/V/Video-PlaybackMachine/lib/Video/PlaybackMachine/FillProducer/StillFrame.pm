package Video::PlaybackMachine::FillProducer::StillFrame;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::StillFrame
####
#### $Revision$
####
#### 
####

use Moo;

with 'Video::PlaybackMachine::FillProducer::AbstractStill';

use Carp;

use POE;

############################# Parameters #############################

has 'image' => (
	'is' => 'ro',
	'required' => 1
);

############################# Object Methods ##############################



##
## start()
##
## Displays the StillFrame for the appropriate time. Assumes that
## it's being called within a POE session.
##
sub start {
  my $self = shift;

  $poe_kernel->post('Player', 'play_still', $self->image(), sub {
  	my ($rv) = @_;
  	if ( $rv == 2 ) {
  		$poe_kernel->delay('next_fill');
  		$poe_kernel->yield('next_fill');
  	}
  });
  $poe_kernel->delay('next_fill', $self->time_layout()->preferred_time());
}

##
## is_available()
##
## Reports that the still is available if the image file is readable.
##
sub is_available {
	my $self = shift;

	return -r $self->image();
}

1;

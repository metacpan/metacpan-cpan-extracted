package Video::PlaybackMachine::EventWheel::FullScreen;

our $VERSION = '0.09'; # VERSION

use Moo;

use X11::FullScreen;

with 'Video::PlaybackMachine::EventWheel';

######################### Class Methods #########################


######################### Object Methods ########################

sub get_event {
  my $self = shift;
  my ($heap) = @_;

  return $self->source()->check_event();
}


# Expose is 12
sub set_expose_handler {
	my ($self, $handler) = @_;

  $self->set_handler(12, $handler);
}

# TODO: Make is_running check the display handle

no Moo;

1;

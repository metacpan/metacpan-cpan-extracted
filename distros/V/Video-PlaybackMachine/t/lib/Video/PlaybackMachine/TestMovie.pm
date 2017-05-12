package Video::PlaybackMachine::TestMovie;

####
#### Video::PlaybackMachine::TestMovie
####
#### $Revision$
####
#### Extension of Video::PlaybackMachine::Movie. Schedules
#### a "finished" message for when it's supposed to end.
#### You can use the "real_length" attribute to tell it when
#### that should be.
####

use strict;
use warnings;

use base 'Video::PlaybackMachine::Movie';

use POE;
use Test::More;
use Data::Dumper;

############################# Class Constants #############################

############################## Class Methods ##############################

sub new {
  my $type = shift;
  my $self = $type->SUPER::new(@_);
  my %in = @_;

  if (defined $in{real_length}) {
    $self->{real_length} = $in{real_length};
  }
  else {
    $self->{real_length} = $self->get_length();
  }

  $self->{expected_start} = $in{expected_start};
  $self->{name} = $in{name};

  return $self;

}


############################# Object Methods ##############################

##
## After letting Movie::play() do its thing, schedules a "finished" event
## on the current session after the appropriate length of time.
## 
sub play {
  my $self = shift;

  my $time = time();
  my $diff = abs($time - $self->{expected_start});
  ok( $diff < 2, "$self->{name}: Start time '$time', expected '$self->{'expected_start'}', diff '$diff' (max 2)");

  $self->SUPER::play();
  $poe_kernel->delay_set('finished', $self->{real_length});
}

1;

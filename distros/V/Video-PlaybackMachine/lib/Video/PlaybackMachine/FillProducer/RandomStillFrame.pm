package Video::PlaybackMachine::FillProducer::RandomStillFrame;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::RandomStillFrame
####
#### $Revision$
####
#### Plays a randomly-chosen still frame from a directory.
####
#### Has, at least for now, been superseded by the SlideShow fill
#### producer.
####

use strict;
use warnings;
use Carp;

with 'Video::PlaybackMachine::FillProducer';

use POE;

use IO::Dir;

############################# Class Constants ############################

############################## Class Methods ##############################

##
## new()
##
## Arguments: (hash)
##  directory => string -- Directory containing images to display
##  time => int -- time in seconds image should be displayed
##

has 'directory' => ( 'is' => 'ro', required => 1 );

############################# Object Methods ##############################


sub is_available {
  my $self = shift;

  -d $self->directory() or return;
  $self->get_frames() >= 1 or return;
  return 1;

}

sub get_frames {
  my $self = shift;

  my $dh = IO::Dir->new( $self->directory() );
  my @frames = ();
  while ( my $file = $dh->read() ) {
    next if $file =~ /^\./;
    next unless -f "$self->{'directory'}/$file";
    push(@frames, "$self->{'directory'}/$file");
  }
  return @frames;
}


##
## start()
##
## Displays a random still frame for the appropriate time. Assumes that
## it's being called within a POE session.
##
sub start {
  my $self = shift;

  my @frames = $self->get_frames();
  my $frame = $frames[ rand( scalar @frames ) ];

  $poe_kernel->yield('still_ready', $frame, $self->get_time_layout()->min_time());
}

1;

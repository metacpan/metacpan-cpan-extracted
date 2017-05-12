package Video::PlaybackMachine::FillProducer::UpNext;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::UpNext
####
#### $Revision$
####

use Moo;

use Carp;

extends 'Video::PlaybackMachine::FillProducer::TextFrame';

use POE;

use POSIX qw(strftime);

############################# Class Constants #############################

############################## Class Methods ##############################

############################# Object Methods ##############################

##
## add_text()
##
sub add_text {
  my $self = shift;
  my ($image) = @_;

  my $entry = $poe_kernel->call('Scheduler', 'query_next_scheduled')
    or return;
  my $next_time = strftime '%l:%M', localtime ($entry->start_time());

  $self->write_centered($image, "Up Next:\n\n" . $entry->movie_info()->title()  ."\n\n$next_time");


}

##
## is_available
##
## We are available if there is something "next"
##
sub is_available {
  my $self = shift;

  my $entry = $poe_kernel->call('Scheduler', 'query_next_scheduled')
    or return;
    
  $entry->movie_info() or return;  
    
  1;
}

1;

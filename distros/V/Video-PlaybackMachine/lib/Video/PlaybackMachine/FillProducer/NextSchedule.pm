package Video::PlaybackMachine::FillProducer::NextSchedule;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::NextSchedule
####
#### $Revision$
####

use Moo;

use Carp;

extends 'Video::PlaybackMachine::FillProducer::TextFrame';

use Video::PlaybackMachine::FillProducer::TextFrame::TextTable;
use POE;

use POSIX qw(strftime);

############################# Class Constants #############################

our $Max_Entries = 5;

our $Border = 20;

############################## Class Methods ##############################



############################# Object Methods ##############################

##
## add_text()
##
sub add_text {
  my $self = shift;
  my ($image) = @_;

  my @entries = $poe_kernel->call('Scheduler', 'query_next_scheduled', $Max_Entries)
    or return;
  my $table = 
    Video::PlaybackMachine::FillProducer::TextFrame::TextTable->new(
								    image => $image,
								    border => $Border,
								   );
  foreach my $entry (@entries) {
    my $next_time = strftime '%l:%M', localtime ($entry->start_time());
    $table->add_row($next_time, $entry->movie_info()->title())
      or last;
  }

  $table->draw();

}

##
## is_available
##
## We are available if there is more than one something "next".  If
## there's only one thing left on the schedule, we assume that "up
## next" will be enough.
##
sub is_available {
  my $self = shift;

  my @entries = $poe_kernel->call('Scheduler', 'query_next_scheduled', $Max_Entries)
    or return;

  return scalar @entries > 1;

}


1;

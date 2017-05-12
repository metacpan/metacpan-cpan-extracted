package Video::PlaybackMachine::ScheduleView;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::ScheduleView
####
#### $Revision$
####
#### Translates between the times listed in a schedule
#### and the current time.
####

use strict;
use warnings;
use Carp;
use Log::Log4perl;

############################# Class Constants #############################

############################## Class Methods ##############################

##
## new()
##
## Arguments:
##
##  SCHEDULE_TABLE: Video::PlaybackMachine::ScheduleTable
##  OFFSET: int -- Difference between schedule time and real ( s - r )
##
sub new {
  my $type = shift;

  @_ == 2 or croak "${type}::new(): arguments are SCHEDULE_TABLE and OFFSET; stopped";

  my ($schedule_table, $offset) = @_;

  defined $offset or $offset = 0;

  my $self = {
	      schedule_table => $schedule_table,
	      offset => $offset,
	      logger => Log::Log4perl->get_logger('Video.PlaybackMachine.ScheduleView')
	     };

  bless $self, $type;
}

############################# Object Methods ##############################

##
## Returns the given time corrected with the schedule
## offset. If no arguments, returns the current time
## corrected for schedule offset.
##
# Note: Currently the offset is positive for the past, negative for
# the future.
sub real_to_schedule {
  my $self = shift;
  my ($real_time) = @_;

  defined $real_time or $real_time = CORE::time();
  return $real_time - $self->{offset};

}

sub schedule_to_real {
  my $self = shift;
  my ($schedule_time) = @_;

  defined $schedule_time or return CORE::time();
  return $schedule_time + $self->{'offset'};
}

##
## Returns the offset value.
##
sub get_offset {
  return $_[0]->{offset};
}

##
## Returns the schedule table.
##
sub get_schedule_table {
  return $_[0]->{schedule_table};
}

##
## get_next_entry()
##
## Returns the next entry appearing on our Schedule Table.
##
sub get_next_entry {
  my $self = shift;
  my ($real_time, $num_entries) = @_;
  defined $real_time or $real_time = time();

  return $self->_do_get_next_entry($real_time, $num_entries);
}

sub _do_get_next_entry {
  my $self = shift;
  my ($real_time, $num_entries) = @_;

  return scalar($self->{schedule_table}
		->get_entries_after(
				    $self->real_to_schedule($real_time + 1),
				    $num_entries
				   )
		);
}

##
## Returns the amount of time until the next scheduled entry.
## Returns empty if no scheduled entry remains.
##
sub get_time_to_next {
  my $self = shift;
  my $real_time = time();

  my $next_entry = $self->_do_get_next_entry($real_time)
    or return;

  return $next_entry->get_start_time() - $self->real_to_schedule($real_time);

}

##
## Returns the seek time for a given schedule entry.
##
sub get_seek {
  my $self = shift;
  my $entry = shift;

  my $seek = time() - $self->schedule_to_real($entry->get_start_time());
  return ($seek > 0) ? $seek : 0;

}


1;

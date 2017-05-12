package Video::PlaybackMachine::MockScheduleTable;

####
#### MockScheduleTable
####
#### $Revision$
####
#### Exports a single function letting us make a mock schedule table.
#### (Also there's an object-oriented interface, plus an add() method
#### you can use to add blank ScheduleEntries. The whole thing was 
#### initially a Test::MockObject, thus the closure implementation.)
####

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(mock_schedule_table);

##
## mock_schedule_table()
##
##  Arguments: 
##    NOW: Time we want all these things to start
##
## Creates a MockObject that matches the ScheduleTable interface
## and automatically returns the following ScheduleEntries
## when called:
##     1. An entry starting NOW lasting 10 seconds.
##     2. An entry starting NOW + 20 claiming to last 4 seconds but lasting 7 seconds
##     3. An entry starting NOW + 25 lasting 8 seconds
##     4. An entry starting NOW + 40 claiming to last 5 seconds but lasting 15 seconds
##     5. An entry starting NOW + 46 lasting 10 seconds
##     6. An entry starting NOW + 57 lasting 5 seconds
##
## Predicted results (slack of 2 seconds):
##     * First entry will start NOW
##     * We will enter fill mode at NOW+11
##     * Entry 2 will start NOW+20
##     * Entry 3 will start NOW+28
##     * Entry 4 will start NOW+40
##     * Entry 5 will be skipped
##     * Entry 6 will start NOW+57
##
sub mock_schedule_table {
  my ($now) = @_;

  my $mst = Video::PlaybackMachine::MockScheduleTable->new($now);


  # First one starts NOW and lasts 10 seconds till NOW+10
  $mst->add(0,  0, 10);

  # Then we fill for 10 seconds

  # Second one starts NOW + 20 and lasts 7 seconds
  $mst->add(20, 20,  4, 7);

  # Third one wants to start at 25 seconds, but starts at 28, and lasts 9 seconds till NOW+37
  $mst->add(25, 28,  9, 9);

  # 3 seconds is beneath fill threshold

  # Fourth one starts at 40 seconds and lasts till 20 seconds
  $mst->add(40, 40,  5, 20);

  # Fifth one wants to start at 46 seconds, but is skipped
  $mst->add(46, -1, 15);

  # Sixth one starts at 65 seconds
  $mst->add(65, 65,  5);

  return $mst;

}

##
## new()
##
## Creates a new, empty MockScheduleTable.
##
sub new {
  my $type = shift;
  my ($now, $movie_type) = @_;
  defined $movie_type or $movie_type = 'Video::PlaybackMachine::TestMovie';

  eval "use $movie_type";

  my @entries = ();
  my %entries_cache = ();

  my $self = {};

  $self->{'add_func'} = sub {
    push @entries, [ @_ ];
  };


  my $make_entry_func = sub {
    my ($num, $start_off,  $expected_off, $duration, $real_duration, $file) = @_;
    defined $entries_cache{$num} && return $entries_cache{$num};
    defined($real_duration) or $real_duration = $duration;
    defined($expected_off) or $expected_off =  $start_off;
    defined($file) or $file = '/dev/null';
    my $listing = $movie_type->new(
							 av_files => [ Video::PlaybackMachine::AVFile->new(
													   $file,
													   $duration
													  )
								     ],
							 title => "Test $num $duration ($real_duration)",
							 description => "Test item $num claiming to last $duration seconds and really lasting $real_duration seconds.",
							 'real_length' => $real_duration,
							 expected_start => $now + $expected_off,
							 name => "Movie $num ($expected_off)"

							);

    my $entry = Video::PlaybackMachine::ScheduleEntry->new($now + $start_off, $listing);
    $entries_cache{$num} = $entry;
    return $entry;
  };

  $self->{get_entries_after_func} =  sub {
    my ($time) = @_;

    foreach my $idx (0 .. $#entries) {
      my $sched_time = $entries[$idx][0] + $now;
      if ( $sched_time > $time) {
	return &$make_entry_func($idx + 1, @{ $entries[$idx] });
      }
    }
    return;
  };

  $self->{get_entry_during_func} = sub {
    my ($time) = @_;
    
    foreach my $idx (0 .. $#entries) {
      my $sched_start = $entries[$idx][0] + $now;
      my $sched_end = $entries[$idx][2] + $sched_start;
      if ( ( $sched_start <= $time ) && ( $sched_end > $time ) ) {
	return &$make_entry_func($idx + 1, @{ $entries[$idx] });
      }
    }
    
    return;
  };

  bless $self, $type;

}

sub get_entries_after {
  my $self = shift;
  return $self->{get_entries_after_func}(@_);
}

sub get_entry_during {
  my $self = shift;
  return $self->{get_entry_during_func}(@_);
}

sub add {
  my $self = shift;
  if (ref $_[0] eq 'HASH') {
    my %in = %{ $_[0] };
    $self->{add_func}(@in{ qw(start_off expected_off duration real_duration file) } );
  }
  else {
    $self->{add_func}(@_);
  }
}

1;

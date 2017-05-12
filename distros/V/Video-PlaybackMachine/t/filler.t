# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################


# TODO: Only gives 3 OKs, which might be OK because it won't go into wait mode if there's nothing scheduled after.

use Test::More tests => 3;
BEGIN { use_ok('Video::PlaybackMachine::Filler') };

use strict;

use lib qw(t/lib lib);

use Test::MockObject;

use Video::PlaybackMachine::MockScheduleTable;
use Video::PlaybackMachine::FillSegment;
use Video::PlaybackMachine::Schema;
use Video::PlaybackMachine::ScheduleTable::DB;
use Video::PlaybackMachine::Scheduler;
use Video::PlaybackMachine::TimeLayout::FixedTimeLayout;
use POE;
use POE::Session;

#########################

# Initialize the log file
my $conf = q(
log4perl.logger.Video		= ERROR, Screen1
log4perl.appender.Screen1	= Log::Log4perl::Appender::Screen
log4perl.appender.Screen1.layout = Log::Log4perl::Layout::SimpleLayout
);
Log::Log4perl::init(\$conf);


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

MAIN: {
  my $now = time();

  # Create a couple of segments with mock producers
  my $two_seg = make_segment(2, 0, 1);
  my $seven_seg = make_segment(7, 1, 0);

  # Spawn the Filler with appropriate segments
  my $filler = Video::PlaybackMachine::Filler->new( segments => [ $two_seg, $seven_seg] );
  $filler->spawn();

  # A little wonky. We're making a scheduler to pass around, but we're not spawning
  # it.
  my $scheduler = make_scheduler($filler);

  # Spin up a mock session to check on play_still calls
  # Here it's playing both Player and Scheduler
  POE::Session->create(
		       inline_states => {
					 _start => sub {
					   $two_seg->producer()->clear();
					   $seven_seg->producer()->clear();

					   $_[KERNEL]->alias_set('Player');
					   $_[KERNEL]->alias_set('Scheduler');
					   $_[KERNEL]->post('Filler', 'start_fill', $scheduler);
					   $_[KERNEL]->delay('check', 1);
					 },
					 check => sub {
					   ok( $two_seg->producer()->called('start'), 'Two start' );
					   ok( ! $seven_seg->producer()->called('start'), 'Seven start' );
					   $_[KERNEL]->post('Filler', 'still_ready', 'test', 2);
					 },
					 play_still => sub {
					   is($_[ARG0], 'test', 'play_still arg');
					   ok_time($now + 1, 'play_still');
					 },
					 wait_for_scheduled => sub {
					   ok_time($now+3, 'wait_for_scheduled');
					 }
					}
		       );

  POE::Kernel->run();

}

sub ok_time {
  my ($exp_time, $name) = @_;

  my $time_diff = abs(time() - $exp_time);

  ok($time_diff < 2, "$name call: $time_diff");

}

sub make_scheduler {
  my ($filler) = @_;
  
  # Create a Scheduler with some programming starting in 5 seconds
  my $sched_table = make_temp_schedule();
  add_entry($sched_table, 5, 1);
  my $scheduler = Video::PlaybackMachine::Scheduler->new(
  	filler => $filler,
  	schedule_table => $sched_table
  );
  return $scheduler;
}

sub make_segment {
  my ($seconds, $order, $priority) = @_;

  my $producer = Test::MockObject->new();
  $producer->set_true('start');
  $producer->set_true('is_available');
  $producer->mock('get_next', sub { $_[0] + 1 });
  $producer->set_always('time_layout',
			Video::PlaybackMachine::TimeLayout::FixedTimeLayout->new($seconds));
  return Video::PlaybackMachine::FillSegment->new(
						  name => "$seconds seconds",
						  sequence_order => $order,
						  priority_order => $priority,
						  producer => $producer
						  );

}

sub make_temp_schedule {
	my $schema = Video::PlaybackMachine::Schema->connect(
		'dbi:SQLite:dbname=:memory:', '', ''
	);
	$schema->deploy( { 'add_drop_table' => 0 } );
	
	$schema->resultset('Schedule')->create({
		'name' => 'test'
	});
	
	my $schedule_table = Video::PlaybackMachine::ScheduleTable::DB->new(
		'schema' => $schema,
		'schedule_name' => 'test'
	);
}

sub add_entry {
	my ($schedule_table, $start, $duration) = @_;
	
	my $schema = $schedule_table->schema();
	
	my $mrl = '/dev/null/fake' . $duration;
	
	my $schedule = $schema->resultset('Schedule')->find({name => 'test'});
	
	my $movie_info = $schema->resultset('MovieInfo')->find_or_create({ 'mrl' => $mrl, duration => $duration });
	my $entry = $schema->resultset('ScheduleEntry')->create({ 
		'mrl' => $mrl, 
		'start_time' => time() + $start,
		'schedule_id' => $schedule->schedule_id
	});
	my $end = $schema->resultset('ScheduleEntryEnd')->create({ 
		'schedule_entry_id' => $entry->schedule_entry_id(),
		'stop_time' => $entry->start_time() + $movie_info->duration()
 	});
	return $entry;
}

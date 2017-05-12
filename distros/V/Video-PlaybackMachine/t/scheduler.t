#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::MockObject::Extends;

use Video::PlaybackMachine::Schema;
use Video::PlaybackMachine::ScheduleTable::DB;
use Video::PlaybackMachine::Scheduler;
use Video::PlaybackMachine::Filler;

TESTS: {
	test_time_to_next();
	done_testing();
}

###
### Tests
###

sub test_time_to_next {
	my $scheduler = make_scheduler();
	
	is($scheduler->get_time_to_next(), 10);

	return;
}

####
#### Subroutines
####

sub make_scheduler {

	my $schedule_table = make_temp_schedule();
	
	add_entry( $schedule_table, 10, 20 );
	
	my $scheduler_obj = Video::PlaybackMachine::Scheduler->new(
		'schedule_table' => $schedule_table,
		'filler' => Video::PlaybackMachine::Filler->new()
	);
	
	my $scheduler = Test::MockObject::Extends->new( $scheduler_obj );
	
	$scheduler->set_always( 'time', 0 );
	
	return $scheduler;
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
		'start_time' => $start,
		'schedule_id' => $schedule->schedule_id
	});
	my $end = $schema->resultset('ScheduleEntryEnd')->create({ 
		'schedule_entry_id' => $entry->schedule_entry_id(),
		'stop_time' => $entry->start_time() + $movie_info->duration()
 	});
	return $entry;
}

#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use Video::PlaybackMachine::DB;
use Video::PlaybackMachine::Config;

@ARGV==2 or die "Usage: $0 START_TIME DURATION\n";

my ($start_time, $duration) = @ARGV;

MAIN: {

	my $schema = Video::PlaybackMachine::DB->schema();
	my $config = Video::PlaybackMachine::Config->config();
	my $schedule = $schema->resultset('Schedule')->find({'name' => $config->schedule});
	
	my @results = $schedule->movie_conflicts($start_time, $duration);
	
	if (scalar @results) {
		foreach my $conflict (@results) {
			print "Conflict: ", $conflict->mrl(), "\n";
		}
	}
	else {
		print "No conflicts.\n";
	}

}

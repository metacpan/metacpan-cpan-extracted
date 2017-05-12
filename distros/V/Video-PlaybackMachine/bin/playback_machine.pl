#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use Getopt::Long;

use Log::Log4perl;

use Video::PlaybackMachine::Config;

use Video::PlaybackMachine;

our $config = Video::PlaybackMachine::Config->config();

MAIN: {

    if ( $config->daemonize() ) {
	my $start_time = time();

	while (1) {

        # Spawn off a child to do actual running
        my $pid;
        if ( my $pid = fork ) {
            sleep 5;
            wait;
        }
        else {

            open( STDERR, '>>' . $config->stderr_log() )
              or die "Couldn't open '"
              . $config->stderr_log()
              . "' for STDERR log: $!; stopped";

            Log::Log4perl::init( \( $config->log_config() ) );

            Video::PlaybackMachine->run($start_time);
        }

    }

    }
    else {
	Video::PlaybackMachine->run(undef, 1);
    }

}


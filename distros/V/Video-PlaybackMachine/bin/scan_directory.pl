#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use Video::PlaybackMachine::Schema;
use Video::PlaybackMachine::DirectoryScanner;
use Getopt::Long;

my ($directory, $db_file) = @ARGV;

MAIN: {
	
	my $schema = Video::PlaybackMachine::Schema->connect(
		"dbi:SQLite:dbname=$db_file", 
		'', 
		''
	);

	my $scanner = Video::PlaybackMachine::DirectoryScanner->new(
		schema => $schema,
		directories => [$directory]
	);
	
	$scanner->scan();
}
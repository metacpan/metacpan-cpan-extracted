package Video::PlaybackMachine::DB;

our $VERSION = '0.09'; # VERSION


use strict;
use warnings;

=pod

=head1 NAME

Video::PlaybackMachine::DB

=head1 DESCRIPTION

Singleton database class for PlaybackMachine.

=cut

use Carp;

use Video::PlaybackMachine::Config;
use Video::PlaybackMachine::Schema;


####################### Module Constants #########################

our $Database_Name = Video::PlaybackMachine::Config->config()->database();

our $Schema;

####################### Class Methods ############################

sub schema {
	my $type = shift;
	
	unless ( defined($Schema) && $Schema->storage->connected() ){
		$Schema = Video::PlaybackMachine::Schema->connect("dbi:SQLite:dbname=$Database_Name", '', '');
	}
	
	return $Schema;
}

sub db {
	my $type = shift;

	my $Schema = $type->schema(@_);
	
	return $Schema->storage->dbh;
}



1;

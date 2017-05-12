#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use autodie;

use Video::PlaybackMachine::Schema;
use Text::CSV;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::TimeZone::UTC;
use Video::Xine;
use Video::Xine::Stream ':meta_constants';
use POSIX 'ceil';
use Getopt::Long;

our $Erase_Flag = 0;

GetOptions(
	'erase' => \$Erase_Flag
);

my ($schedule_name, $csv_file, $db_file) = @ARGV;

MAIN: {

	my $csv = Text::CSV->new( { 'binary' => 1 } )
		or die 'Cannot use CSV: ' . Text::CSV->error_diag();

	open(my $fh, '<:encoding(utf8)', $csv_file);
	
	my $strp_spreadsheet = DateTime::Format::Strptime->new(
		pattern => '%m/%d/%Y %T',
		time_zone => DateTime::TimeZone::UTC->new(),
		on_error => 'croak'
	);
	
	my $strp_epoch = DateTime::Format::Strptime->new(
		pattern => '%s',
		time_zone => DateTime::TimeZone::UTC->new(),
		on_error => 'croak'
	);
	
	if ($Erase_Flag && -e $db_file) {
		rename($db_file, "$db_file.old");
	}
	
	my $schema = Video::PlaybackMachine::Schema->connect(
		"dbi:SQLite:dbname=$db_file", 
		'', 
		''
	);
	
	if ($Erase_Flag) {
		$schema->deploy({ 'add_drop_table' => 0 });
	}
	
	my $schedule = $schema->resultset('Schedule')->create({ 'name' => $schedule_name });
	
	# Skip header line
	my $header = $csv->getline( $fh );
	
	my $entry_rs = $schema->resultset('ScheduleEntry');
	my $movie_info_rs = $schema->resultset('MovieInfo');
	my $entry_end_rs = $schema->resultset('ScheduleEntryEnd');
	
	my $xine = Video::Xine->new();
	
    my $vo = Video::Xine::Driver::Video->new($xine, 'none');
    my $ao = Video::Xine::Driver::Audio->new($xine, 'none');
    my $stream = $xine->stream_new($ao, $vo);
	
	ROW: while ( my $row = $csv->getline( $fh ) ) {
		my ($start_str, $mrl) = @$row;
		length($start_str) or next;
		
		my $start_dt = $strp_spreadsheet->parse_datetime( $start_str );
				
		my $start_epoch = $strp_epoch->format_datetime( $start_dt );
		
		$stream->open($mrl) or die "Couldn't open '$mrl'";
		my (undef, undef, $length_millis) = $stream->get_pos_length();
		my $title = $stream->get_meta_info(XINE_META_INFO_TITLE);
		if ( defined $title ) {
			print STDERR "$title\n";
		}
		$stream->close();
		
		my $length_secs = ceil( $length_millis / 1000 );
		
		my @conflicts = $schedule->movie_conflicts( $start_epoch, $length_secs );
		
		if ( scalar @conflicts ) {
			print STDERR "Movie '$title' conflicts with: ",
				join(', ', map { $_->mrl() } @conflicts ),
				"\n";
			next ROW;
		}
		
		my $entry = $entry_rs->create({ 'schedule_id' => $schedule->schedule_id, 
							'mrl' => $mrl,
							'start_time' => $start_epoch
							});
		
		$movie_info_rs->create({'mrl' => $mrl,
								'duration' => $length_secs,
								'title' => $title
							   });
							   
		$entry_end_rs->create({ 'schedule_entry_id' => $entry->schedule_entry_id(),
								'stop_time' => $start_epoch + $length_secs
							});
	}
}

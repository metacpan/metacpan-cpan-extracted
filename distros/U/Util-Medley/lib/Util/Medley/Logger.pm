package Util::Medley::Logger;
$Util::Medley::Logger::VERSION = '0.007';
use Modern::Perl;
use Moose;
use Method::Signatures;
use namespace::autoclean;
use Carp;
use Data::Printer alias => 'pdump';
use File::Path 'make_path';

with 'Util::Medley::Roles::Attributes::DateTime';

=head1 NAME

Util::Medley::Logger - Yet another class for logging.

=head1 VERSION

version 0.007

=cut

=head1 SYNOPSIS

  my $log = Util::Medley::Logger->new;
  
  $log->fatal($msg);   
  $log->error($msg);
  $log->warn($msg);
  $log->info($msg);
  $log->verbose(Smsg);
  $log->debug($msg);
 
  $log->deprecated("old()", "new()");
  
=cut

=head1 DESCRIPTION

A simple logging class.  By default all logs are written to stderr.

=cut

#########################################################################################

use constant LOG_LEVELS => 'debug', 'verbose', 'info', 'warn', 'error', 'fatal';
use constant LOG_LEVEL_DEFAULT  => 'info';
use constant LOG_DETAIL_DEFAULT => 3;
use constant LOG_DETAIL_MIN     => 1;
use constant LOG_DETAIL_MAX     => 6;
use constant LOG_FRAMES_DEFAULT => 2;

#########################################################################################

=head1 ATTRIBUTES

=head2 filename (<str>)

If provided, indicates where to write log messages.  This will not disable
stderr.  To do that use disable_stderr(). 

=cut

has filename => (
	is => 'rw',
	isa => 'Str'
);

=head2 logDetail (<int>)

Used to indicate how much detail to output with each message.  Here is a 
breakdown:

  1 - <msg>
  2 - [level] <msg>
  3 - [level] [date] <msg>
  4 - [level] [date] [pid] <msg>
  5 - [level] [date] [pid] [caller($frames)] <msg>

Default: 3

=head3 environment vars:

  - MEDLEY_LOG_DETAIL=<int>

=cut

has logDetail => (
	is      => 'rw',
	isa     => 'Int',
	lazy    => 1,
	builder => '_getLogDetail',
);

#########################################################################################

=head2 logFrames (<int>)

Used to indicate how many frames to go back when logDetail invokes the caller()
function.

Default: 2

=head3 environment vars:

  - MEDLEY_LOG_FRAMES=<frames number>

=cut

has logFrames => (
	is      => 'rw',
	isa     => 'Int',
	lazy    => 1,
	builder => '_getLogFrames',
);

#########################################################################################

=head2 logLevel (<string>) 

Indicates what level of log detail you want.

Levels (in order of severity):

  - debug
  - verbose
  - info
  - warn
  - error
  - fatal

Default: info

=head3 environment vars:

These are mutually exclusive.

  - MEDLEY_LOG_LEVEL=<level string>
  - MEDLEY_VERBOSE=<bool>
  - MEDLEY_DEBUG=<bool>

=cut

has logLevel => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_getLogLevel',
);

#########################################################################################

=head2 disable_stderr (optional)

If provided and true, will disable logging messages to stderr.  You should use
the 'filename' attribute if you provide true.

=cut

has disable_stderr => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

#########################################################################################

has _fh => (
	is => 'rw',
	lazy => 1,
	builder => '_buildFh',
);

has _logLevel_map => (
	is      => 'ro',
	isa     => 'HashRef[Int]',
	lazy    => 1,
	builder => '_buildLogLevelMap',
);

#########################################################################################

=head1 METHODS

=head2 fatal($msg)

Writes a fatal message to the log and exits with 1.

=cut

method fatal (Str $msg) {

	my $type = 'fatal';
	
	my $line = $self->_assembleMsg(
		type => $type,
		msg  => $msg,
	);

	$self->_printMsg($line);
	exit 1;
}

=head2 error($msg)

Writes an error message to the log.

=cut

method error (Str $msg) {

	my $type = 'error';

	if ( $self->_isLogLevelEnabled($type) ) {

		my $line = $self->_assembleMsg(
			type => $type,
			msg  => $msg,
		);

		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

=head2 warn($msg)

Writes a warn message to the log.

=cut

method warn (Str $msg) {

	my $type = 'warn';

	if ( $self->_isLogLevelEnabled($type) ) {

		my $line = $self->_assembleMsg(
			type => $type,
			msg  => $msg,
		);

		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

=head2 info($msg)

Writes an info message to the log.

=cut

method info (Str $msg) {

	my $type = 'info';

	if ( $self->_isLogLevelEnabled($type) ) {

		my $line = $self->_assembleMsg(
			type => $type,
			msg  => $msg,
		);

		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

=head2 verbose($msg)

Writes a verbose message to the log.

=cut

method verbose (Str $msg) {

	my $type = 'verbose';

	if ( $self->_isLogLevelEnabled($type) ) {

		my $line = $self->_assembleMsg(
			type => $type,
			msg  => $msg,
		);

		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

=head2 debug($msg)

Writes a debug message to the log.

=cut

method debug (Str $msg) {

	my $type = 'debug';
	
	if ( $self->_isLogLevelEnabled($type) ) {
		
		my $line = $self->_assembleMsg(
			type => $type,
			msg  => $msg,
		);
		
		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

=head2 deprecated($old, $new)

Writes a deprecated message to the log.  First arg is the old method/sub. 
Second arg is the new method/sub.

=cut

method deprecated (Str $orig, Str $new) {

	if ( $self->_isLogLevelEnabled('warn') ) {

		my $msg = sprintf "%s is deprecated by %s.\n", $orig, $new;

		my $line = $self->_assembleMsg(
			type => 'deprecated',
			msg  => $msg,
		);

		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

=head2 getLogLevels

Returns an array of all possible levels in severity order.

=cut

method getLogLevels {
	
	return LOG_LEVELS();
}

######################################################################

method _printMsg (Str $line) {

	if (!$self->disable_stderr) {
		print STDERR "$line\n";
	}
	
	if ($self->filename) {
		my $fh = $self->_fh;
		print $fh "$line\n";	
	}
}

method _assembleMsg (Str :$type!,
                     Str :$msg) {

	my $frames = $self->logFrames;
	my $detail = $self->logDetail;
	my @msg;
	
	if ( $detail > 1 ) {
		push @msg, uc "[$type]";
	}

	if ( $detail > 2 ) {
		push @msg, sprintf '[%s]', $self->DateTime->localdatetime();
	}

	if ( $detail > 3 ) {
		push @msg, sprintf '[%d]', $$;
	}

	if ( $detail > 4 ) {
		push @msg, sprintf '[%s]', ( caller($frames) )[3];
	}

	if ( $detail > 5 ) {
		push @msg, sprintf '[line %d]', ( caller($frames) )[2];
	}

	push @msg, $msg;

	return join( ' ', @msg );
}

method _getLogDetail () {

	my $detail;
	if ( $ENV{MEDLEY_LOG_DETAIL} ) {
		$detail = $ENV{MEDLEY_LOG_DETAIL};
	}
	else {
		$detail = LOG_DETAIL_DEFAULT();
	}

	if ( !$self->_isLogDetailValid($detail) ) {
		confess "log detail level $detail is invalid";
	}

	return $detail;
}

method _getLogLevel () {

	my $level;
	if ( $ENV{MEDLEY_DEBUG} ) {
		$level = 'debug';
	}
	elsif ( $ENV{MEDLEY_VERBOSE} ) {
		$level = 'verbose';
	}
	elsif ( $ENV{MEDLEY_LOG_LEVEL} ) {
		$level = $ENV{MEDLEY_LOG_LEVEL};
	}
	else {
		$level = LOG_LEVEL_DEFAULT();
	}

	if ( !$self->_isLogLevelValid($level) ) {
		confess "log level $level is invalid";
	}

	return $level;
}

method _isLogLevelValid (Str $level) {

	if ( $self->_logLevel_map->{$level} ) {
		return 1;
	}

	return 0;
}

method _isLogDetailValid (Int $detail) {

	if ( $detail >= LOG_DETAIL_MIN() ) {
		if ( $detail <= LOG_DETAIL_MAX() ) {
			return 1;
		}
	}

	return 0;
}

method _isLogLevelEnabled (Str $level) {

	my $cutoff = $self->_logLevelToInt( $self->logLevel );
	my $want   = $self->_logLevelToInt($level);
	
	if ( $cutoff <= $want ) {
		return 1;
	}

	return 0;
}

method _logLevelToInt (Str $level) {
	
	if(defined $self->_logLevel_map->{$level} ) {
		 return $self->_logLevel_map->{$level}	
	}
	
	confess "unknown log level: $level";
}

method _getLogFrames {

	my $frames = LOG_FRAMES_DEFAULT() => 1;
	if ( $ENV{MEDLEY_LOG_FRAMES} ) {
		$frames = $ENV{MEDLEY_LOG_FRAMES};
	}

	return $frames;
}

method _buildLogLevelMap {

	my $i = 0;
	my %map;
	foreach my $level ( LOG_LEVELS() ) {
		$map{$level} = $i;
		$i++;
	}

	return \%map;
}

method _buildFh {

	if ($self->filename) {
		
		my $filename = $self->filename;
		make_path(dirname($filename));
		
		my $fh;
		open($fh, '>>', $self->filename) or confess "failed to open $filename: $!"; 
		
		return $fh;
	}	
}

1;

package Util::Medley::Logger;
$Util::Medley::Logger::VERSION = '0.024';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Carp;
use Data::Printer alias => 'pdump';
use FileHandle;
use Fcntl ":flock";

# in order to prevent circular deps between this and File.pm, use the 
# originals...
use File::Path 'make_path';
use File::Basename;


with 'Util::Medley::Roles::Attributes::DateTime';

=head1 NAME

Util::Medley::Logger - Yet another class for logging.

=head1 VERSION

version 0.024

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
use constant LOG_LEVEL_DEFAULT  	  => 'info';
use constant LOG_DETAIL_LEVEL_DEFAULT => 3;
use constant LOG_DETAIL_LEVEL_MIN     => 1;
use constant LOG_DETAIL_LEVEL_MAX     => 6;
use constant LOG_FRAMES_DEFAULT 	  => 2;

#########################################################################################

=head1 ATTRIBUTES

=head2 disableStderr

If provided and true, will disable logging messages to stderr.  You should use
the 'filename' attribute if you provide true.

=over

=item type: Bool

=item default: 0

=back

=cut

has disableStderr => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

=head2 filename

If provided, indicates where to write log messages.  This will not disable
stderr.  To do that use disableStderr(). 

Note that file locking is used when writing to a file.  This allows you to 
have multiple processes writing to the same log file without stomping on each
other.

=over

=item type: Str

=item default: undef

=back

=cut

has filename => (
	is => 'rw',
	isa => 'Str'
);

=head2 logDetailLevel (<int>)

Used to indicate how much detail to output with each message.  Here is a 
breakdown:

  1 - <msg>
  2 - [level] <msg>
  3 - [level] [date] <msg>
  4 - [level] [date] [pid] <msg>
  5 - [level] [date] [pid] [caller($frames)] <msg>

=over

=item type: Bool

=item default: 3

=item env var: MEDLEY_LOG_DETAIL_LEVEL

=back

=cut

has logDetailLevel => (
	is      => 'rw',
	isa     => 'Int',
	lazy    => 1,
	builder => '_getLogDetailLevel',
);

=head2 logDetailLevelDebug

Get or set the logDetailLevelDebug value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_DEBUG
 
=back
 
=cut

has logDetailLevelDebug => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelDebug',
);


=head2 logDetailLevelVerbose

Get or set the logDetailLevelVerbose value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_VERBOSE
 
=back
 
=cut

has logDetailLevelVerbose => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelVerbose',
);


=head2 logDetailLevelInfo

Get or set the logDetailLevelInfo value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_INFO
 
=back
 
=cut

has logDetailLevelInfo => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelInfo',
);


=head2 logDetailLevelWarn

Get or set the logDetailLevelWarn value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_WARN
 
=back
 
=cut

has logDetailLevelWarn => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelWarn',
);


=head2 logDetailLevelError

Get or set the logDetailLevelError value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_ERROR
 
=back
 
=cut

has logDetailLevelError => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelError',	
);


=head2 logDetailLevelFatal

Get or set the logDetailLevelFatal value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_FATAL
 
=back
 
=cut

has logDetailLevelFatal => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelFatal',	
);


=head2 logDetailLevelDeprecated

Get or set the logDetailLevelDeprecated value.  This overrides the logDetailLevel.

=over

=item type: Int

=item default: undef

=item env var: MEDLEY_LOG_DETAIL_LEVEL_DEPRECATED
 
=back
 
=cut

has logDetailLevelDeprecated => (
	is      => 'rw',
	isa     => 'Int|Undef',
	lazy 	=> 1,
	builder => '_buildLogDetailLevelDeprecated',
);


=head2 logFrames

Used to indicate how many frames to go back when logDetailLevel invokes the caller()
function.  In most cases you shouldn't have to bother with this.

=over

=item type: Int

=item default: 2

=item env var: MEDLEY_LOG_FRAMES
 
=back

=cut

has logFrames => (
	is      => 'rw',
	isa     => 'Int',
	lazy    => 1,
	builder => '_getLogFrames',
);


=head2 logLevel

Indicates what level of log detail you want.

Levels (in order of severity):

  - debug
  - verbose
  - info
  - warn
  - error
  - fatal

=over

=item type: Str

=item default: info

=item env var: MEDLEY_LOG_LEVEL

=back
 
=cut

has logLevel => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_getLogLevel',
);


=head2 utf8

Flag to toggle utf8 mode.

=over

=item type: Bool

=item default: 0

=back
 
=cut

has utf8 => (
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

has _logLevelMap => (
	is      => 'ro',
	isa     => 'HashRef[Int]',
	lazy    => 1,
	builder => '_buildLogLevelMap',
);

#########################################################################################

=head1 METHODS

=cut

#########################################################################################

=head2 debug

Writes a debug message to the log.

=over

=item usage:

 $util->debug($msg);
 
 $util->debug(msg => $msg);

=item args:

=over

=item msg [Str]

The message to log.

=back

=back

=cut

multi method debug (Str $msg) {

	my $type = 'debug';
	
	if ( $self->_isLogLevelEnabled($type) ) {
		
		my $line = $self->_assembleMsg(
			type => $type,
			msg  => $msg,
			detailLevel => $self->logDetailLevelDebug,
		);
		
		$self->_printMsg($line);
		return 1;
	}

	return 0;
}

multi method debug (Str :$msg!) {

	return $self->debug($msg);
}


=head2 deprecated

Writes a deprecated message to the log.  First arg is the original method/sub. 
Second arg is the new method/sub.

=over

=item usage:

 $util->deprecated($orig, $new);
 
 $util->deprecated(orig => $orig, new => $new);

=item args:

=over

=item orig [Str]

Name of the deprecated method.

=item new [Str]

Name of the new method.

=back

=back

=cut

multi method deprecated (Str $orig, Str $new) {

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

multi method deprecated (Str :$orig!, Str :$new!) {

	return $self->deprecated($orig, $new);
}


=head2 error

Writes an error message to the log.

=over

=item usage:

 $util->error($msg);
 
 $util->error(msg => $msg);

=item args:

=over

=item msg [Str]

The message to log.

=back

=back

=cut

multi method error (Str $msg) {

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

multi method error (Str :$msg!) {

	return $self->error($msg);
}


=head2 fatal

Writes a fatal message to the log and exits with 1.

=over

=item usage:

 $util->fatal($msg);
 
 $util->fatal(msg => $msg);

=item args:

=over

=item msg [Str]

The message to log.

=back

=back

=cut

multi method fatal (Str $msg) {

	my $type = 'fatal';
	
	my $line = $self->_assembleMsg(
		type => $type,
		msg  => $msg,
	);

	$self->_printMsg($line);
	exit 1;
}

multi method fatal (Str :$msg!) {

	$self->fatal($msg);
}


=head2 getLogLevels

Returns an array of all possible levels in severity order.

=over

=item usage:

 @levels = $util->getLogLevels;
 
=back

=cut

method getLogLevels {
	
	return LOG_LEVELS();
}


=head2 info

Writes an info message to the log.

=over

=item usage:

 $util->info($msg);
 
 $util->info(msg => $msg);

=item args:

=over

=item msg [Str]

The message to log.

=back

=back

=cut

multi method info (Str $msg) {

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

multi method info (Str :$msg!) {

	return $self->info($msg);
}


=head2 verbose

Writes a verbose message to the log.

=over

=item usage:

 $util->verbose($msg);
 
 $util->verbose(msg => $msg);

=item args:

=over

=item msg [Str]

The message to log.

=back

=back

=cut

multi method verbose (Str $msg) {

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

multi method verbose (Str :$msg!) {

	return $self->verbose($msg);
}


=head2 warn

Writes a warn message to the log.

=over

=item usage:

 $util->warn($msg);
 
 $util->warn(msg => $msg);

=item args:

=over

=item msg [Str]

The message to log.

=back

=back

=cut

multi method warn (Str $msg) {

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

multi method warn (Str :$msg!) {

	return $self->warn($msg);
}

######################################################################

method _printMsg (Str $line) {

	if (!$self->disableStderr) {
		print STDERR "$line\n";
	}
	
	if ($self->filename) {
		my $fh = $self->_fh;
		flock($fh, LOCK_EX);
		print $fh "$line\n";	
	   	flock($fh, LOCK_UN);
	}
}

method _assembleMsg (Str 	   :$type!,
                     Str 	   :$msg!,
                     Int|Undef :$detailLevel) {

	my $frames = $self->logFrames;
	my $detail = $self->logDetailLevel if !$detailLevel;
	my @msg;
	
	if ( $detail > 1 ) {
		push @msg, uc "[$type]";
	}

	if ( $detail > 2 ) {
		push @msg, sprintf '[%s]', $self->DateTime->localDateTime();
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

method _getLogDetailLevel () {

	my $detail;
	if ( $ENV{MEDLEY_LOG_DETAIL_LEVEL} ) {
		$detail = $ENV{MEDLEY_LOG_DETAIL_LEVEL};
	}
	else {
		$detail = LOG_DETAIL_LEVEL_DEFAULT();
	}

	$self->_isLogDetailLevelValid($detail);

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

	if ( $self->_logLevelMap->{$level} ) {
		return 1;
	}

	return 0;
}

method _isLogDetailLevelValid (Int $detail) {

	if ( $detail >= LOG_DETAIL_LEVEL_MIN() ) {
		if ( $detail <= LOG_DETAIL_LEVEL_MAX() ) {
			return 1;
		}
	}

	confess "invalid logDetailLevel $detail";
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
	
	if(defined $self->_logLevelMap->{$level} ) {
		 return $self->_logLevelMap->{$level}	
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
	
		# append - all writes automatically go to the end of the file when
		# writing
		my $fh = FileHandle->new(">>$filename") or 
			confess "could not open $filename: $!";
			
		$fh->autoflush(1);
	
	    if( $self->utf8 ){
        	binmode( $fh, ":utf8" );
	    }	
		
		return $fh;
	}	
}

method _buildLogDetailLevelDebug {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_DEBUG}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_DEBUG};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

method _buildLogDetailLevelVerbose {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_VERBOSE}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_VERBOSE};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

method _buildLogDetailLevelInfo {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_INFO}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_INFO};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

method _buildLogDetailLevelWarn {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_WARN}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_WARN};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

method _buildLogDetailLevelError {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_ERROR}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_ERROR};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

method _buildLogDetailLevelFatal {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_FATAL}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_FATAL};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

method _buildLogDetailLevelDeprecated {

	if ($ENV{MEDLEY_LOG_DETAIL_LEVEL_DEPRECATED}) {
		my $level = $ENV{MEDLEY_LOG_DETAIL_LEVEL_DEPRECATED};
		$self->_isLogDetailLevelValid($level);
		return $level;
	}	
}

1;

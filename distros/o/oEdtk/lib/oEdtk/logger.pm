package oEdtk::logger;

use strict;

BEGIN {
	use Exporter ();
	use vars     qw($VERSION @ISA @EXPORT @EXPORT_OK $LOGGERLEVEL $WARN2LOGGER)
		;    #backward compatibility for Perls under 5.6

	$VERSION   = 2.1126;
	@ISA       = qw(Exporter);
	@EXPORT    = qw(logger);
	@EXPORT_OK = qw($LOGGERLEVEL $WARN2LOGGER);

	use warnings;
	use Data::Dumper qw(Dumper);
	use POSIX        qw(strftime);
}

$LOGGERLEVEL = 4;    # default log level
$WARN2LOGGER = 0;    # by default do not turn warn messsages to logger

my %hLEVEL = ( U => 8, D => 7, I => 6, P => 5, W => 4, A => 3, C => 0, E => -1 );
my %hLABEL = (
	8  => '8-USER-',
	7  => '7-DEBUG',
	6  => '6-INFO-',
	5  => '5-PARSE',
	4  => '4-WARN-',
	3  => '3-ALERT',
	2  => '2-ALERT',
	1  => '1-ALERT',
	0  => '0-CRITC',
	-1 => '-1 ERROR'
);

# Legacy error-number field, interpolated in the diagnostic message below.
my $FD;

sub logger {

	# CALL: &logger($messLevel, $logMess[, $MODIFY]);
	# CALL: &logger($messLevel, $logMess[, 2]); # increase LOGGERLEVEL
	# CALL: &logger($messLevel, $logMess[, Warn]); # set LOGGERLEVEL to Warn

	# to log blocking errors while using the die method:
	# open (IN, "<$nomfichier") or die &logger($NOK, "unable to open <$nomfichier>");

	# LOGGERLEVEL defines the log sensitivity (note: the MODIFY option can change it)
	# 8-> Debug (all), 7-> Information, 6-> Context, 5-> Follow, 4-> Warning, \$NOK-> Error
	# $. is the current line number on the current filehandle
	# $! current errno value
	# $0 perl script name

	my ( $messLevel, $logMess, $MODIFY ) = @_;
	my $fileHandle = 0;

	#my $FD=$!;
	#$FD =~s/(Bad)\s(file\sdescriptor)/$1 or No $2/io;
	$MODIFY  //= 0;    # default value, from 5.10 //= replaces ||=
	$logMess //= "";
	chomp($logMess);
	my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;    # %j day of year?

#warn  "LOGGER - MODIFY $MODIFY - @{[%hLEVEL]} => Dump : ". Dumper \%hLEVEL;
# PID :
# cat /proc/sys/kernel/pid_max
# The default value for this file, 32768, results in the same range of PIDs as on earlier kernels. On 32-bit platforms, 32768 is the maximum value for pid_max. On 64-bit systems, pid_max can be set to any value up to 2^22 (PID_MAX_LIMIT, approximately 4 million)
# alias sys_guid='sudo /sbin/blkid | grep "$(df -h / | sed -n 2p | cut -d" " -f1):" | grep -o "UUID=\"[^\"]*\" " | sed "s/UUID=\"//;s/\"//"'

	if ( $MODIFY =~ m/^\-{0,1}[1-4]$/ ) {
		$LOGGERLEVEL += $MODIFY;
		print STDERR
			" \>$now|$hLABEL{6}|PID-$$| LOGGERLEVEL set to $hLABEL{$LOGGERLEVEL}|FH-$fileHandle \n";

	}
	elsif ( $MODIFY =~ m/^([UDIPW])/ ) {
		$LOGGERLEVEL = $hLEVEL{$1};
		print STDERR
" \>$now|$hLABEL{6}|PID-$$| LOGGERLEVEL set to $hLABEL{$LOGGERLEVEL} ($MODIFY)|FH-$fileHandle \n";

		#		} elsif ($MODIFY !~m/\d/ && $MODIFY !~m/^([UDIPW])/) {
	}
	elsif ( $MODIFY !~ m/^([0UDIPW])/ ) {
		print STDERR
			" \>$now|$hLABEL{6}|PID-$$| logger - unknown modificator ($MODIFY)|FH-$fileHandle \n";
		print STDERR
" \>$now|$hLABEL{6}|PID-$$| logger - use : 8 => '8-USER-', 7 => '7-DEBUG', 6 => '6-INFO-' , 5 => '5-PARSE' , 4 => '4-WARN-' , 3/1 => '3-ALERT',  0 => '0-CRITC' , -1 => '-1 ERROR' |$FD|FH-$fileHandle \n";
	}

	$fileHandle += $. if $.;
	my $loggerMessage = " \>$now|$hLABEL{$messLevel}|PID-$$| $logMess|FH-$fileHandle";
	$loggerMessage .= "|PRG $0" if ( $messLevel <= 5 );
	$loggerMessage =~ s/\s+/ /g;

	if ( $messLevel <= 4 ) {
		warn "$loggerMessage\n";
	}
	elsif ( $messLevel <= $LOGGERLEVEL ) {
		print STDERR "$loggerMessage\n";
	}

	return $loggerMessage, "\n";
}

END { }
return 1;

=head1 NAME

oEdtk::logger - the oEdtk diagnostic logger

=head1 SYNOPSIS

    use oEdtk::logger;

    logger(2, 'a routine message');
    logger(-1, 'fatal: cannot open the config file');   # for die()

=head1 DESCRIPTION

The single live logger of the toolkit. It writes a formatted diagnostic line
(timestamp, level label, PID, message, file handle) to STDERR and returns the
line so a caller can reuse it in a C<die>. The contract -- which logger is
live, the event-to-level table, and the fd2 routing -- is recorded in
F<docs/integration/LOGGER.md> and pinned by F<t/int/67_logger_normalization.t>.

Do not change the exports: the public API is frozen against C<snap/M.json> by
F<t/int/01_api_M.t>.

=head1 FUNCTIONS

=head2 logger

    my ($line, $eol) = logger(2, $message, $modify);

Emit a diagnostic line at the given level. The first argument is the level, a
number from C<-1> (fatal) to C<8> (user); levels up to C<4> always emit
(through C<warn>), while higher levels emit only up to the current
C<$LOGGERLEVEL>. An optional third argument adjusts C<$LOGGERLEVEL>: an integer
delta in C<1..4>, or one of the letters C<U> C<D> C<I> C<P> C<W>. The message is
collapsed to single spaces and its file handle is appended. The formatted line
and a newline are returned.

=head2 $LOGGERLEVEL

    our $LOGGERLEVEL;

The emission ceiling, default C<4>. Messages above it are suppressed unless the
level is raised.

=head2 $WARN2LOGGER

    our $WARN2LOGGER;

Flag reserved to route C<warn> messages through the logger; off by default.

=head1 AUTHOR

The oEdtk team.

=cut

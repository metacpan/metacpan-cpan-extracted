package oEdtk::logger;    ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;

BEGIN {
	use Exporter ();
	use vars     qw($VERSION @ISA @EXPORT @EXPORT_OK);   #backward compatibility for Perls under 5.6

	$VERSION = 1.9062;
	@ISA     = qw(Exporter);
	@EXPORT =
		qw(logger logger_help logger_rc_list *LOGGER_OUT set_warn_to_logger set_logger_level _LEVEL_ _HELP_ _FAIL_ _SUCCESS_ _EXEC_ _WARN_ _INFO_ _FOLLW_ _CONTXT_ _DEBUG_);
	@EXPORT_OK = qw($VERSION $LOGGERLEVEL $WARN2LOGGER);

	use warnings;
	use Data::Dumper qw(Dumper);
	use POSIX        qw(strftime);

	#reset $! to a "clean" or "neutral" value that depends on the platform
	use IO::Handle;
	STDERR->clearerr();    # Reset $! for the STDERR handler
}

#usage:
#use logger qw(:DEFAULT);
# logger (_LEVEL_, "message");

{
	our $LOGGERLEVEL = 1;
	our $WARN2LOGGER = 0;
	*LOGGER_OUT = *STDERR;    # why messages don't bubble up into tracking?

	use constant _LEVEL_   => -2;    # in case of misuse
	use constant _HELP_    => -2;
	use constant _FAIL_    => -1;
	use constant _SUCCESS_ => 0;
	use constant _EXEC_    => 1;
	use constant _WARN_    => 4;
	use constant _INFO_    => 5;
	use constant _FOLLW_   => 6;
	use constant _DEBUG_   => 7;
	use constant _CONTXT_  => 8;

	my %hLETTER_LEVEL = (
		H => _HELP_,       # -2
		F => _FAIL_,       # -1
		E => _FAIL_,       # -1
		S => _SUCCESS_,    #  0
		X => _EXEC_,       #  1
		W => _WARN_,       #  4
		A => _WARN_,       #  4
		I => _INFO_,       #  5
		P => _INFO_,       #  5
		L => _FOLLW_,      #  6
		C => _CONTXT_,     #  8
		D => _DEBUG_,      #  7
		U => _CONTXT_,     #  8
	);

	use File::Basename;
	my $PROG = basename( $0, "" );

	my @label_LEVEL = (
		'SUCCESS', 'EXEC',    'ND_2',  'ND_3', 'WARN', 'INFO',
		'FOLLOW',  'CONTEXT', 'DEBUG', 'ND',   'ND'
	);    #keep lasts ND
	$label_LEVEL[_FAIL_] = 'FAILED';
	$label_LEVEL[_HELP_] = 'HELP';

	sub set_logger_level {
		$LOGGERLEVEL = shift;
		1;
	}

	sub set_warn_to_logger() {
		$WARN2LOGGER = 1;
		1;
	}

	sub logger {
		my ( $messLevel, $logMess, $modifier, @rcLogger ) = @_;

		# Normalization: letter -> integer level
		if ( defined $messLevel && $messLevel =~ /^([A-Z])$/i ) {
			my $key = uc($messLevel);
			if ( exists $hLETTER_LEVEL{$key} ) {
				$messLevel = $hLETTER_LEVEL{$key};
			}
			else {
				$messLevel = _LEVEL_;    # misuse level
				logger_help(0);
			}
		}

		if ( defined $modifier && $modifier =~ /^([A-Z])$/i ) {
			$modifier = $hLETTER_LEVEL{ uc($modifier) } // $LOGGERLEVEL;
		}
		$LOGGERLEVEL = ( $modifier || $LOGGERLEVEL );

		# IF THE MESSAGE IS OUTSIDE THE DEFINED LIMITS, WE DON'T WASTE TIME, WE EXIT
		if ( $messLevel > $LOGGERLEVEL && $messLevel ne _FAIL_ ) {
			return $messLevel;

			# IF THE MESSAGE IS A FAIL AND THERE IS NO STANDARD RETURN CODE, WE SET
			#  THE CODE 41 UNKNOWN ERROR 41
		}
		elsif ( $messLevel == _FAIL_ ) {
			if ( !($!) ) {
				$! = 41;
			}
			$rcLogger[0] = sprintf( "%0.3d", $! );

			# FLUSH TO SYNCHRONIZE MESSAGES
			$| = 1;

		}
		elsif ( $messLevel == _HELP_ ) {
			&logger_help();
			exit _SUCCESS_;

		}
		else {
			$rcLogger[0] = "000";
		}

		$rcLogger[1] = sprintf( "\>%s|", ( strftime "%Y-%m-%d %H:%M:%S", localtime ) );
		$rcLogger[2] = sprintf(
			" %-7s|FH-%07d|PID-%s|last RC: %0.3d|",
			$label_LEVEL[$messLevel] || 'ND',
			( $. || 0 ),
			$$, $!
		);
		$rcLogger[3] = sprintf( " %s|last RC: %0.3d-%s", $logMess, $!, $! );

		if ( $messLevel <= $LOGGERLEVEL && $messLevel > _FAIL_ ) {
			print LOGGER_OUT join( '', @rcLogger ) . "\n";

			#	} elsif ($messLevel == _FAIL_) {
			#		print $rcLogger[0] . $rcLogger[1] ."\n";
		}

		if ( $messLevel == _FAIL_ ) {

			# For die: we return a single string that contains everything
			return wantarray ? @rcLogger : join( '', @rcLogger );
		}

		return wantarray ? @rcLogger : $rcLogger[0];
	}

	sub logger_help {
		my $call_rc_list = shift || 0;
		print STDOUT <<"EOF";
HELP FOR LOGGER USE, AND RETURN CODES LIST.

Examples : 
 &logger(_HELP_);
 &logger(xxxxxx, "message" [, _DEBUG_]);
 &logger(xxxxxx, "message" [, n]);

Example for logging a fatal error :
 open (IN, "<\$filename") or die &logger(_FAIL_, "can't open <\$filename>");

	\$LOGGERLEVEL defines the sensitivity level for messages
	\$LOGGERLEVEL possible values :
	_FAIL_		=> level -1, fatal error, logger will look for the system error to report
	_SUCCESS_	=> level 0, treatment successfull
	_EXEC_		=> level 1, information message for evaluation
	_WARN_		=> level 4, WARN message
	_INFO_		=> level 5, message for significant information
	_FOLLW_		=> level 6, message for tracked information
	_CONTXT_	=> level 7, message for contextual information
	_DEBUG_		=> level 8, full debug level, general message for debug
	_HELP_		=> This message for information

Messages are filtered depend on \$LOGGERLEVEL preset.
Third parameter is used to change \$LOGGERLEVEL value.
\$LOGGERLEVEL is currently set to $LOGGERLEVEL.

EOF

		logger_rc_list() if ($call_rc_list);
	}

	sub logger_rc_list() {
		print "LIST OF APPLICATION RETURN CODES :\n";
		printf( "%0.3d: %s, %s\n", _SUCCESS_, $label_LEVEL[_SUCCESS_], "$PROG success" );
		for ( $! = 1 ; $! <= 133 ; $!++ ) {

			# SYSTEM ERRORS
			#$. is the current line number on the current filehandle
			#$! current errno value
			#$@ last error captured by eval
			#$0 perl script name
			printf( "%0.3d: %s\n", $!, $! );
		}
	}

}
1;

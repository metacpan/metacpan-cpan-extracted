use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::Logger;
use Data::Printer alias => 'pdump';
use Time::ParseDate;

use vars qw($STDERR);


my $log = Util::Medley::Logger->new;
ok($log);

ok( my @levels = $log->getLogLevels );

foreach my $level (@levels) {

	if ( $level eq 'fatal' ) {
		check_fatal();
	}
	else {
		check_output($level);
	}
}

done_testing;

#####################################

sub check_fatal {
	
	my $msg = 'foobar';
	my $pid = fork();
	die if not defined $pid;
	
	if ($pid) {

		# parent
		wait();
		my $exit = $? >> 8;
		ok( $exit == 1, "child exited with $exit (expected 1)" );  # just rely on exit status
	}
	else {
		# child
		close(STDERR);
		open( STDERR, '>', \$STDERR ) or die "can't open stderr: $!";
		my $log = Util::Medley::Logger->new( logLevel => 'debug' );

		ok( $log->fatal($msg), "writing message at fatal" );
		check_log_msg3( 'fatal', $msg );
	}

	# no point in testing that a message is dropped because you can't
	# block fatal
}

sub check_output {

	my $level = shift;
	
	my $msg = 'foobar';
	my $log = Util::Medley::Logger->new;

	foreach my $level ( $log->getLogLevels ) {
		foreach my $detail ( 1 .. 5 ) {
			check_log_msg( $level, $detail, 'debug');
			check_log_msg( $level, $detail, 'verbose');
			check_log_msg( $level, $detail, 'info');
			check_log_msg( $level, $detail, 'warn');
			check_log_msg( $level, $detail, 'error');
		}
	}
}

sub check_log_msg {

	my $log_level  = shift;
	my $log_detail = shift;
	my $write_level = shift;
	
	close(STDERR);
	open( STDERR, '>', \$STDERR ) or say "can't open stderr: $!";
	
	my $log = Util::Medley::Logger->new(
		logLevel  => $log_level,
		logDetailLevel => $log_detail
	);
	
	my $msg = ' foobar '; # this should get trimmed
	my $bool = $log->$write_level($msg);
	
	if ($log->_logLevelToInt($log_level) <= $log->_logLevelToInt($write_level)) {

		# expect output
		ok($bool);
		check_log_detail($log, $write_level);
	}
	else {
		# dropped
		ok( !$bool );
		ok( $STDERR eq '' );
	}
}


=pod
  1 - <msg>
  2 - [level] <msg>
  3 - [level] [date] <msg>
  4 - [level] [date] [pid] <msg>
  5 - [level] [date] [pid] [caller($frames)] <msg>
=cut

sub check_log_detail {

	my $log = shift;
	my $write_level = shift;
		
	my $stderr = $STDERR;
	chomp $stderr;

	if ( $log->logDetailLevel == 1 ) {
		ok( $stderr =~ /^\w+$/ );
	}
	elsif ($log->logDetailLevel == 2) {
		ok($stderr =~ /^\[(\w+)\] \w+$/);
		ok($1 eq uc($write_level));
	}
	elsif ($log->logDetailLevel == 3) {
		ok($stderr =~ /^\[(\w+)\] \[([\d\s\-\:]+)\] \w+$/);
		ok($1 eq uc($write_level));		
		ok(parsedate($2));
	}
	elsif ($log->logDetailLevel == 4) {
		ok($stderr =~ /^\[(\w+)\] \[([\d\s\-\:]+)\] \[\d+\] \w+$/);
		ok($1 eq uc($write_level));		
		ok(parsedate($2));
	}
	elsif ($log->logDetailLevel == 5) {
		ok($stderr =~ /^\[(\w+)\] \[([\d\s\-\:]+)\] \[\d+\] \[.+\] \w+$/);
		ok($1 eq uc($write_level));		
		ok(parsedate($2));
	}
	else {
		die "unknown detail level: " . $log->logDetailLevel;
	}
}


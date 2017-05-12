use strict;
use warnings;

use Test::More tests => 5;
use Test::Fatal;
use Test::Output;
use File::Temp;
use Data::Dumper;
use Log::Log4perl::Level;
use Capture::Tiny ':all';

use Zabbix::ServerScript;

subtest q(throws exception if environment variables are not set) => sub {
	ok exception { Zabbix::ServerScript::_set_logger() };
};

$ENV{BASENAME} = q(zabbix_server_script_test);
$ENV{ID} = q(zabbix_server_script_test);

my $i = 0;

subtest q(throws exception if log4perl config is wrong) => sub {
	my $log = $Zabbix::ServerScript::Config->{log};
	$Zabbix::ServerScript::Config->{log} = undef;
	ok exception { Zabbix::ServerScript::_set_logger() };

	$Zabbix::ServerScript::Config->{log} = q();
	ok exception { Zabbix::ServerScript::_set_logger() };
	$Zabbix::ServerScript::Config->{log} = $log;
};

subtest q(test category) => sub {
	Zabbix::ServerScript::_set_logger();
	is($logger->{category}, q(Zabbix.ServerScript), qq(If no logger is defined, default category Zabbix.ServerScript is used));
	is($ENV{LOG_CATEGORY}, $logger->{category}, qq(Environment variable LOG_CATEGORY is set));

	Zabbix::ServerScript::_set_logger({ logger => q() });
	is($logger->{category}, q(Zabbix.ServerScript.nolog), qq(If logger is disabled, category Zabbix.ServerScript.nolog is used));
	is($ENV{LOG_CATEGORY}, $logger->{category}, qq(Environment variable LOG_CATEGORY is set));

	Zabbix::ServerScript::_set_logger({ logger => q(test.category) });
	is($logger->{category}, q(test.category), qq(If custome logger category is specified, it is used instead of predefined ones));
	is($ENV{LOG_CATEGORY}, $logger->{category}, qq(Environment variable LOG_CATEGORY is set));

	Zabbix::ServerScript::_set_logger({ console => 1 });
	is($logger->{category}, q(Zabbix.ServerScript.console), qq(If output to console is requested, category Zabbix.ServerScript.console is used));
	is($ENV{LOG_CATEGORY}, $logger->{category}, qq(Environment variable LOG_CATEGORY is set));

	Zabbix::ServerScript::_set_logger({ logger => q(), console => 1 });
	is($logger->{category}, q(Zabbix.ServerScript.nolog), qq(If output to console is requested, but logger is disabled, category Zabbix.ServerScript.nolog is used));
	is($ENV{LOG_CATEGORY}, $logger->{category}, qq(Environment variable LOG_CATEGORY is set));
};

subtest q(check console logging) => sub {
	# test levels
	Zabbix::ServerScript::_set_logger({ console => 1 });
	$i++;
	stderr_like(sub { $logger->warn(qq(Test message $i)) }, qr(Test message $i), q(Log to STDERR if 'console' option is specified));
	$i++;
	stderr_unlike(sub { $logger->info(qq(Test message $i)) }, qr(Test message $i), q(Not log INFO and below by default));

	# test verbosity
	Zabbix::ServerScript::_set_logger({ console => 1, verbose => 1 });
	$i++;
	stderr_like(sub { $logger->info(qq(Test message $i)) }, qr(Test message $i), q(Log INFO in STDERR when increased verbosity to 1));
	$i++;
	stderr_unlike(sub { $logger->debug(qq(Test message $i)) }, qr(Test message $i), q(Not log DEBUG and below in STDERR when increased verbosity to 1));

	# test debug
	Zabbix::ServerScript::_set_logger({ console => 1, debug => 1 });
	$i++;
	stderr_like(sub { $logger->debug(qq(Test message $i)) }, qr(Test message $i), q(Log DEBUG in STDERR when debug is enabled));

	# test unwanted STDERR
	Zabbix::ServerScript::_set_logger();
	$i++;
	stderr_unlike(sub { $logger->fatal(qq(Test message $i)) }, qr(Test message $i), q(Not log to STDERR when no logger is defined));

	Zabbix::ServerScript::_set_logger({ logger => q() });
	$i++;
	stderr_unlike(sub { $logger->fatal(qq(Test message $i)) }, qr(Test message $i), q(Not log to STDERR when logging is disabled));

	Zabbix::ServerScript::_set_logger({ console => 0 });
	$i++;
	stderr_unlike(sub { $logger->fatal(qq(Test message $i)) }, qr(Test message $i), q(Not log to STDERR when console logging is disabled));
};

sub read_file_contents {
	my ($fh) = @_;
	return do { local $/; <$fh> };
}

sub set_file_logger {
	my ($opt) = @_;
	$opt = {} unless defined $opt;
	my ($log_fh, $log_filename) = File::Temp::tempfile(q(/tmp/test_log.XXXXXX), UNLINK => 1);
	$opt->{log_filename} = $log_filename;
	Zabbix::ServerScript::_set_logger($opt);
	return $log_fh;
}

sub log_to_file {
	my ($log_level, $opt) = @_;
	my $log_fh = set_file_logger($opt);
	$i++;
	$logger->log($log_level, qq(Test message $i));
	my $content = read_file_contents($log_fh);
	close($log_fh);
	return $content;
}

subtest q(check file logging) => sub {
	my $content;
	my $log_fh;

	like(exception { Zabbix::ServerScript::_set_logger({ log_filename => q() }) }, qr(Cannot log to empty filename), q(Throws exception if empty log filename is specified));

	$content = log_to_file($FATAL);
	like($content, qr(Test message $i), q(Log to file by default));

	$content = log_to_file($FATAL, { logger => q() });
	unlike($content, qr(Test message $i), q(Not log to file when logging is disabled));

	my $stderr = capture_stderr {
		$content = log_to_file($FATAL, { console => 1 });
	};
	like($content, qr(Test message $i), q(Log to file even if console logging is enabled));
	like($stderr, qr(Test message $i), q(Logs the same message to file and STDERR even if console logging is enabled));

	# test die/warn
	$ENV{ZBX_TESTING} = 1;
	$log_fh = set_file_logger();
	$i++;
	my $pid = fork() or die(qq(Test message $i));;
	while (wait() != -1) {}
	$content = read_file_contents($log_fh);
	like($content, qr(Test message $i), q('die' message goes to file));
	close($log_fh);

	$ENV{ZBX_TESTING} = 0;
	$log_fh = set_file_logger();
	eval {
		$i++;
		die(qq(Test message $i));
	} or do {
		$content = read_file_contents($log_fh);
		unlike($content, qr(Test message $i), q(Eval 'die' message doesn't go to file));
	};
	close($log_fh);

	$log_fh = set_file_logger();
	$i++;
	$pid = fork();
	if (!$pid){
		warn(qq(Test message $i));;
		exit;
	}
	while (wait() != -1) {}
	$content = read_file_contents($log_fh);
	like($content, qr(Test message $i), q('warn' message goes to file));
	close($log_fh);
};

done_testing;

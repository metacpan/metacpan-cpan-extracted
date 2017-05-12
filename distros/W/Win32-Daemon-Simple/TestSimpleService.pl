END {Log("ERROR: $@") if $@}
use strict;
use File::Spec;
use Win32::Daemon;
use Win32::Daemon::Simple
	Service => 'TestSimpleService',
	Name => 'Test Simple Service',
	Version => '2.0',
	Info => {
		display =>  'Test Simple Service',
		description => 'Test Service for Win32::Daemon::Simple',
		user    =>  '',
		pwd     =>  '',
		interactive => 0,
	},
	Params => {
		Tick => 0,
		Talkative => 0,
		Interval => 1,
		LogFile => "TestSimple.log",
		Description => <<'*END*',
Tick : (0/1) controls whether the service writes a "tick" message to
  the log once a minute if there's nothing to do
Talkative : (0/1) controls the amount of logging information
Interval : how often does the service look for new or modified files
  (in minutes)
*END*
	},
	param_modify => {
		LogFile => sub {File::Spec->rel2abs($_[0])},
		tAlkative => sub {undef},
	};

LogNT("Running as ".SERVICEID);
ServiceLoop(\&doSomething);
Log("Going down");
exit;

sub doSomething {
	Log("Doing something");
	sleep(5 + rand(5)); # process your task
	Log("Done something");
}

__END__

# not so simple
sub doSomething {
	Log("Doing something");
	foreach (1..5) {
		Log " task $_";
		sleep(5 + rand(5)); # process the task
		Log "  done $_";
		DoEvents(
			sub {LogNT "Thanks, I'll take a nap."}, # pause
			sub {LogNT "OK, back to work."}, # unpause
			sub {LogNT "Mama they killed me!"; return 1} # stop
		);
	}
	Log("Done something");
}

# ever worse
sub doSomething {
	Log("Doing something");
	sleep(1 + rand(5)); # prepare for the tasks
	LogNT " on to the tasks...";
	foreach (1..5) {
		Log "  task $_";
		sleep(5 + rand(5)); # process the task
		Log "   done $_";

		last if (SERVICE_STOP_PENDING == DoEvents(
			sub {Log "Thanks, I'll take a nap."}, # pause
			sub {Log "OK, back to work."}, # unpause
			sub {Log "Mama they wanna kill me!"; return 0} # stop
		));
	}
	LogNT " done all tasks";
	sleep(1 + rand(5)); # cleanup after the tasks
	Log("Done something");
}

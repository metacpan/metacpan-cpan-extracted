use strict;
use warnings;

# FIXME: use a temporary directory, not t/fixtures

use Test::Most;
# use Test::Warnings;
# use Test::Strict;
# use Test::Vars;
# use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::HTTP::Scenario;
use Test::HTTP::Scenario::Adapter::LWP;
use LWP::UserAgent;
use IO::Socket::INET;
use HTTP::Server::Simple::CGI;

BEGIN {
	require File::Path;
	File::Path::make_path('t/fixtures');
}

local $SIG{__WARN__} = sub {
	diag "WARNING DURING REPLAY: @_";
};

my $orig_request = LWP::UserAgent->can('request');

{
	package Local::HTTP::Server;
	use strict;
	use warnings;
	use parent 'HTTP::Server::Simple::CGI';

	sub handle_request {
		my ($self, $cgi) = @_;
		my $path = $cgi->path_info || '/';

		print "HTTP/1.0 200 OK\r\n";
		print "Content-Type: text/plain\r\n\r\n";

		print $path eq '/hello' ? 'hello world' : 'unknown';
	}
}

my $PORT = 50080;
my $URL  = "http://127.0.0.1:$PORT/hello";

sub _wait_for_port {
    my ($port, $timeout) = @_;
    my $start = time;

    while (time - $start < $timeout) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
        );
        return 1 if $sock;
        select undef, undef, undef, 0.05;
    }

    BAIL_OUT("Server on port $port did not start in time");
}

sub _start_server {
	my $server = Local::HTTP::Server->new($PORT);

	my $pid;

	if ($^O eq 'MSWin32') {
		# Windows: HTTP::Server::Simple provides background()
		$pid = $server->background();
	} else {
		# Unix-like: fork works normally
		$pid = fork();
		BAIL_OUT('fork failed') unless defined $pid;

		if ($pid == 0) {
			$server->run;
			exit 0;
		}
	}

	_wait_for_port($PORT, 5);
	return $pid;
}

sub _stop_server {
	my ($pid) = @_;
	return unless $pid;

	if ($^O eq 'MSWin32') {
		# background() on Windows uses Win32::Process internally
		kill 'TERM', $pid;
		sleep 1;
	} else {
		kill 'TERM', $pid;
		waitpid $pid, 0;
	}
}

#----------------------------------------------------------------------#
# Record
#----------------------------------------------------------------------#

subtest 'record scenario from local HTTP server' => sub {
	my $pid = _start_server();
	my $ua  = LWP::UserAgent->new;

	my $file = 't/fixtures/integration_hello.yaml';
	unlink $file if -e $file;

	my $adapter = Test::HTTP::Scenario::Adapter::LWP->new;   # <-- create adapter

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'integration_hello',
		file	=> $file,
		mode	=> 'record',
		adapter => $adapter,								  # <-- pass object
	);

	$sc->run(sub {
		my $res = $ua->get($URL);
		ok $res->is_success;
		is $res->decoded_content, 'hello world';
	});

	$sc->_save_if_needed;

	ok -e $file, 'fixture file written';

	_stop_server($pid);
};

#----------------------------------------------------------------------#
# Replay
#----------------------------------------------------------------------#

subtest 'replay scenario without server' => sub {
	my $ua  = LWP::UserAgent->new;
	my $file = 't/fixtures/integration_hello.yaml';

	ok -e $file, 'fixture exists';

	my $adapter = Test::HTTP::Scenario::Adapter::LWP->new;   # <-- new adapter

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'integration_hello',
		file	=> $file,
		mode	=> 'replay',
		adapter => $adapter,								  # <-- pass object
	);

	$sc->run(sub {
		my $res = $ua->get($URL);
		ok $res->is_success;
		is $res->decoded_content, 'hello world';
	});

	# let $sc and $adapter go out of scope here
	unlink $file;
};

#----------------------------------------------------------------------#
# Multiple interactions, strict mode, and diffing
#----------------------------------------------------------------------#

subtest 'multiple interactions record + replay' => sub {
	my $file = 't/fixtures/multi.yaml';
	unlink $file if -e $file;

	my $pid = _start_server();
	my $ua  = LWP::UserAgent->new;

	my $adapter = Test::HTTP::Scenario::Adapter::LWP->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'multi',
		file	=> $file,
		mode	=> 'record',
		adapter => $adapter,
	);

	$sc->run(sub {
		my $r1 = $ua->get("http://127.0.0.1:$PORT/hello");
		ok $r1->is_success;
		my $r2 = $ua->get("http://127.0.0.1:$PORT/hello");
		ok $r2->is_success;
	});

	ok -e $file, 'multi fixture written';
	_stop_server($pid);

	# replay
	my $adapter2 = Test::HTTP::Scenario::Adapter::LWP->new;

	my $sc2 = Test::HTTP::Scenario->new(
		name	=> 'multi',
		file	=> $file,
		mode	=> 'replay',
		adapter => $adapter2,
	);

	$sc2->run(sub {
		my $r1 = $ua->get("http://127.0.0.1:$PORT/hello");
		ok $r1->is_success;
		my $r2 = $ua->get("http://127.0.0.1:$PORT/hello");
		ok $r2->is_success;
	});
	unlink $file;
};

#----------------------------------------------------------------------#
# Strict mode: unused interactions cause failure
#----------------------------------------------------------------------#

subtest 'strict mode enforces full consumption' => sub {
	my $file = 't/fixtures/strict.yaml';
	unlink $file if -e $file;

	# record two interactions
	my $pid = _start_server();
	my $ua  = LWP::UserAgent->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'strict',
		file	=> $file,
		mode	=> 'record',
		adapter => Test::HTTP::Scenario::Adapter::LWP->new,
	);

	$sc->run(sub {
		$ua->get("http://127.0.0.1:$PORT/hello");
		$ua->get("http://127.0.0.1:$PORT/hello");
	});

	_stop_server($pid);

	# replay only one → strict mode should croak
	my $sc2 = Test::HTTP::Scenario->new(
		name	=> 'strict',
		file	=> $file,
		mode	=> 'replay',
		strict  => 1,
		adapter => Test::HTTP::Scenario::Adapter::LWP->new,
	);

	dies_ok {
		$sc2->run(sub {
			$ua->get("http://127.0.0.1:$PORT/hello");   # only one request
		});
	} 'strict mode croaks when not all interactions are consumed';
	unlink $file;
};

#----------------------------------------------------------------------#
# Diffing: mismatched request produces enriched exception
#----------------------------------------------------------------------#

subtest 'diffing shows mismatch details' => sub {
	my $file = 't/fixtures/diff.yaml';
	unlink $file if -e $file;

	# record one interaction
	my $pid = _start_server();
	my $ua  = LWP::UserAgent->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'diff',
		file	=> $file,
		mode	=> 'record',
		adapter => Test::HTTP::Scenario::Adapter::LWP->new,
	);

	$sc->run(sub {
		$ua->get("http://127.0.0.1:$PORT/hello");
	});

	_stop_server($pid);

	# replay with wrong URI → diff should appear in exception message
	my $sc2 = Test::HTTP::Scenario->new(
		name	=> 'diff',
		file	=> $file,
		mode	=> 'replay',
		diffing => 1,
		adapter => Test::HTTP::Scenario::Adapter::LWP->new,
	);

	dies_ok {
		$sc2->run(sub {
			$ua->get("http://127.0.0.1:$PORT/wrong");
		});
	} 'mismatched request dies';

	my $error = $@;

	unlink $file;
	like $error, qr/Expected uri:.*hello/s,
		'diff output contains expected URI';
	like $error, qr/Got uri:.*wrong/s,
		'diff output contains actual URI';
};

#----------------------------------------------------------------------#
# No warnings on mismatch (edge-case compatibility)
#----------------------------------------------------------------------#

subtest 'mismatch produces no warnings (only exception)' => sub {
	my $file = 't/fixtures/nowarn.yaml';
	unlink $file if -e $file;

	# record one interaction
	my $pid = _start_server();
	my $ua  = LWP::UserAgent->new;

	my $sc = Test::HTTP::Scenario->new(
		name	=> 'nowarn',
		file	=> $file,
		mode	=> 'record',
		adapter => Test::HTTP::Scenario::Adapter::LWP->new,
	);

	$sc->run(sub {
		$ua->get("http://127.0.0.1:$PORT/hello");
	});

	_stop_server($pid);

	# replay with wrong URI → must die, but produce NO warnings
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $sc2 = Test::HTTP::Scenario->new(
		name	=> 'nowarn',
		file	=> $file,
		mode	=> 'replay',
		diffing => 1,
		adapter => Test::HTTP::Scenario::Adapter::LWP->new,
	);

	dies_ok {
		$sc2->run(sub {
			$ua->get("http://127.0.0.1:$PORT/wrong");
		});
	} 'mismatch dies cleanly';

	unlink $file;
	is scalar(@warnings), 0, 'no warnings emitted on mismatch';
};

#----------------------------------------------------------------------#
# GLOBAL TEARDOWN
#----------------------------------------------------------------------#
rmdir('t/fixtures');

is(
	LWP::UserAgent->can('request'),
	$orig_request,
	'LWP::UserAgent::request restored after all scenarios'
);

done_testing();

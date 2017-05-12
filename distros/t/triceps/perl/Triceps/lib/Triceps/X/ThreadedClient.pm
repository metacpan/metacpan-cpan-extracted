#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A simple multithreaded client for the send-expect sequences.
# It has been written for the unit testing of the server examples
# but can have other initeresting uses.
# It's of very decent quality but needs the official tests.

use strict;

##############################
# the client for automated testing

package Triceps::X::ThreadedClient;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;
use IO::Socket;
use IO::Socket::INET;
use Triceps;
use Triceps::X::ThreadedServer qw(printOrShut);

# For whatever reason, Linux signals SIGPIPE when writing on a closed
# socket (and it's not a pipe). So intercept it.
sub interceptSigPipe
{
	if (!$SIG{PIPE}) {
		$SIG{PIPE} = sub {};
	}
}

# and intercept SIGPIPE by default on import
&interceptSigPipe();

# The client app has the following threads:
# * Global/main thread: controls the execution, sends the requests to the
#   other threads, eventually collects all the inputs from the sockets.
# * Per-client threads, as described below
# * Collector thread that collects the inputs from the client threads
#   and waits for patterns in it; eventually passes the collected
#   inputs to the main thread.

# Each client consists of the following threads:
# * writer: writes to the socket
# * reader: reads from the socket, passes data to the collector thread

# The collector thread that handles the data received from the clients.
#
# Options: the standard thread set.
#
sub collectorT # (@opts)
{
	my $myname = "Triceps::X::ThreadedClient::collectorT";
	my $opts = {};
	&Triceps::Opt::parse($myname, $opts, {@Triceps::Triead::opts}, @_);
	undef @_;
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $tname = $opts->{thread};
	my $unit = $owner->unit();

	# a message read from or to be written to a client's connection
	my $rtMsg = Triceps::RowType->new(
		client => "string", # client name
		text => "string", # text of the message
	);

	# a control message from the global thread
	my $rtCtl = Triceps::RowType->new(
		cmd => "string", # the command to execute
		client => "string", # client on which the command applies
		arg => "string", # the command argument
	);

	my $faSend = $owner->makeNexus( # messages to be sent to the client writers
		name => "send",
		labels => [
			msg => $rtMsg, # data messages
			close => $rtMsg, # request to shut down either side of the socket (text is ignored)
		],
		import => "writer",
	);
	my $faRecv = $owner->makeNexus( # messages to received from the client readers
		name => "receive",
		labels => [
			msg => $rtMsg,
		],
		import => "reader",
	);

	my $faCtl = $owner->makeNexus( # control messages to collector
		name => "ctl",
		labels => [
			msg => $rtCtl,
		],
		import => "reader",
	);
	my $faReply = $owner->makeNexus( # replies to the control messages from the collector
		name => "reply",
		labels => [
			msg => $rtCtl,
			done => $rtCtl, # marks the end of multi-message responses (the contents of the row is ignored)
		],
		reverse => 1,
		import => "writer",
	);

	my $lbRepMsg = $faReply->getLabel("msg");
	my $lbRepDone = $faReply->getLabel("done");

	#### state of the clients ###

	my %recv; # the received data, keyed by the client, as one line
	my %newrecv; # the latest received data, keyed by the client;
		# this is the data since the last match requested was found,
		# stored as an array of lines; after it's expected,
		# gets sent to the main thread and then thrown away;
		# the expect walks it until the first match, and the further
		# lines are left alone for the further expects
	my %pattern; # the pattern to match in the received data, keyed by the client

	#### local functions ###

	# Check if the client's new data matches its pattern, and if so then
	# move its data to %recv and sent a reply to the global thread.
	my $checkPattern = sub { # ($client)
		my $client = shift;
		if (exists $pattern{$client} && exists $newrecv{$client}) {
			my $p = $pattern{$client};

			my $sz = $#{$newrecv{$client}};
			my $i;
			for ($i = 0; $i <= $sz; $i++) {
				if ($newrecv{$client}[$i] =~ /$p/) {
					my $text;
					for (my $j = 0; $j <= $i; $j++) {
						$text .= shift(@{$newrecv{$client}});
					}
					if ($#{$newrecv{$client}} < 0) {
						delete $newrecv{$client};
					}
					delete $pattern{$client};
					$unit->makeHashCall($lbRepMsg, "OP_INSERT", 
						cmd => "expect",
						client => $client,
						arg => $text,
					);
					last;
				}
			}
			# If received an EOF, report an error immediately.
			if ($i > $sz && $newrecv{$client}[$sz] eq "__EOF__\n") {
				$unit->makeHashCall($lbRepMsg, "OP_INSERT", 
					cmd => "error",
					client => $client,
					arg => "Unexpected EOF when expecting " . $pattern{$client},
				);
				delete $pattern{$client};
			}
		}
	};

	### rest of the logic ###

	$faRecv->getLabel("msg")->makeChained("lbRecv", undef, sub {
		my ($client, $text) = $_[1]->getRow()->toArray();
		push @{$newrecv{$client}}, $text;
		&$checkPattern($client);
	});

	$faCtl->getLabel("msg")->makeChained("lbCtl", undef, sub {
		my ($cmd, $client, $arg) = $_[1]->getRow()->toArray();
		if ($cmd eq "expect") {
			# expect a certain pattern from a client
			$pattern{$client} = qr/$arg/m;
			&$checkPattern($client); # might be already received
		} elsif ($cmd eq "cancel") {
			# if not replied already, confirm the cancellation
			if (exists $pattern{$client}) {
				$unit->makeHashCall($lbRepMsg, "OP_INSERT", 
					cmd => "error",
					client => $client,
					arg => "Timed out when expecting " . $pattern{$client},
				);
				delete $pattern{$client};
			}
		} else {
			confess "$myname: received an unknown command '$cmd'";
		}
	});

	$owner->readyReady();
	$owner->mainLoop();
}

# Thread that sends data to the socket.
#
# Options:
#
# client => $clientName
# Name of the client.
#
# debug => 0/1
# (optional) Enables the immediate printout, for debugging.
# Default: 0.
sub clientSendT # (@opts)
{
	my $myname = "Triceps::X::ThreadedClient::clientSendT";
	my $opts = {};
	&Triceps::Opt::parse($myname, $opts, {@Triceps::Triead::opts,
		client => [ undef, \&Triceps::Opt::ck_mandatory ],
		debug => [ 0, undef ],
	}, @_);
	undef @_;
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $unit = $owner->unit();
	my ($tsock, $sock) = $owner->trackDupFile($opts->{client}, ">");

	my $faSend = $owner->importNexus(
		from => "collector/send",
		import => "reader",
	);

	$faSend->getLabel("msg")->makeChained("lbSend", undef, sub {
		my ($client, $text) = $_[1]->getRow()->toArray();
		if ($opts->{client} eq $client) {
			if ($opts->{debug}) {
				printf("\nclientSendT %s: %s\n", $opts->{client}, $text);
			}
			printOrShut($app, $opts->{fragment}, $sock, $text);
		}
	});
	$faSend->getLabel("close")->makeChained("lbClose", undef, sub {
		my ($client, $text) = $_[1]->getRow()->toArray();
		if ($opts->{client} eq $client) {
			if ($opts->{debug}) {
				printf("clientSendT %s: SHUT_", $opts->{client}, $text);
			}
			if ($text eq "RD") {
				$sock->shutdown(0);
			} elsif ($text eq "WR") {
				$sock->shutdown(1);
			} elsif ($text eq "RDWR") {
				$sock->shutdown(2);
			} else {
				confess "$myname: unknown argument for close '$text'";
			}
		}
	});

	$owner->readyReady();
	$owner->mainLoop();
	if ($opts->{debug}) {
		my ($t, $m) = $app->getAborted();
		printf("\nclientSendT %s: exit %d %s\n", $opts->{client}, $owner->isRqDead(), $m);
	}
};

# Thread that receives data from the socket.
#
# Options:
#
# client => $clientName
# Name of the client.
#
# debug => 0/1
# (optional) Enables the immediate printout, for debugging.
# Default: 0.
sub clientRecvT # (@opts)
{
	my $myname = "Triceps::X::ThreadedClient::clientRecvT";
	my $opts = {};
	&Triceps::Opt::parse($myname, $opts, {@Triceps::Triead::opts,
		client => [ undef, \&Triceps::Opt::ck_mandatory ],
		debug => [ 0, undef ],
	}, @_);
	undef @_;
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $unit = $owner->unit();
	my ($tsock, $sock) = $owner->trackDupFile($opts->{client}, "<");

	my $faRecv = $owner->importNexus(
		from => "collector/receive",
		import => "writer",
	);

	my $lbRecv = $faRecv->getLabel("msg");

	$owner->readyReady();

	while (<$sock>) {
		if ($opts->{debug}) {
			printf("\nclientRecvT %s: %s\n", $opts->{client}, $_);
		}
		$unit->makeHashCall($lbRecv, "OP_INSERT", 
			client => $opts->{client},
			text => $_,
		);
		$owner->flushWriters();
	}
	if ($opts->{debug}) {
		printf("\nclientRecvT %s: __EOF__\n", $opts->{client});
	}
	# also explicitly mark the end of data
	$unit->makeHashCall($lbRecv, "OP_INSERT", 
		client => $opts->{client},
		text => "__EOF__\n",
	);
}

# The object is instantiated in the global/main thread.
#
# DOES NOT MARK THE MAIN THREAD AS READY.
#
# Options:
#
# owner => $TrieadOwner
# The thread owner wher this object is instantiated.
#
# port => $port
# (optional) Server port number, to which the clients will connect.
# Can be overridden in startClient(). The port must be specified in
# at least one of two places.
#
# timeout => $float
# (optional) The defalut timeout for expect() calls, in seconds (possibly fractional).
# 0 or undef means "unlimited".
# Default: undef.
#
# totalTimeout => $float
# (optional) The timeout for the whole connection.
# Default: undef.
#
# debug => 0/1/2
# (optional) Enable the debugging printout of the trace as it comes in.
# The level of 2 enables the printing of status right from the sender and received threads.
# Default: 0.
#
sub new # ($class, @opts)
{
	my $myname = "Triceps::X::ThreadedClient::new";
	my $class = shift;
	my $self = {};
	&Triceps::Opt::parse($class, $self, {
		owner => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::TrieadOwner") } ],
		port => [ undef, undef ],
		timeout => [ undef, undef ],
		totalTimeout => [ undef, undef ],
		debug => [ 0, undef ],
	}, @_);

	my $owner = $self->{owner};

	$self->{trace} = ""; # trace of all the data sent and expected
	$self->{expectDone} = 0; # not done yet
	$self->{error} = undef; # no error yet
	$self->{errorTrace} = undef; # errors-only trace; no error yet

	if (defined $self->{totalTimeout} && $self->{totalTimeout} > 0) {
		$self->{deadline} = &Triceps::now() + $self->{totalTimeout};
	}

	# start the collector thread, it will define all the nexuses
	Triceps::Triead::start(
		app => $owner->app()->getName(),
		thread => "collector",
		main => \&collectorT,
	);

	# the sending nexus will be used to send directly to clients
	$self->{faSend} = $owner->importNexus(
		from => "collector/send",
		import => "writer",
	);
	# the control nexuses from the collector
	$self->{faCtl} = $owner->importNexus(
		from => "collector/ctl",
		import => "writer",
	);
	$self->{faReply} = $owner->importNexus(
		from => "collector/reply",
		import => "reader",
	);

	$self->{faReply}->getLabel("msg")->makeChained("lbReplyExpect", undef, sub {
		my ($cmd, $client, $arg) = $_[1]->getRow()->toArray();
		if ($cmd eq "expect") {
			my $ptext = $arg;
			$ptext =~ s/^/$client|/gm;
			$self->{trace} .= $ptext;
			if ($self->{debug}) {
				print $ptext;
			}
			$self->{expectDone} = 1;
		} elsif ($cmd eq "error") {
			# save the error in trace, so that it will be easily printed.
			my $ptext = $arg . "\n";
			$ptext =~ s/^/$client|/gm;
			$self->{trace} .= $ptext;
			$self->{errorTrace} .= $ptext;
			if ($self->{debug}) {
				print $ptext;
			}

			$self->{error} = $arg;
			$self->{expectDone} = 1;
		}
	});

	bless $self, $class;
	return $self;
}

# Shut down the app on destruction.
sub DESTROY # ($self)
{
	my $myname = "Triceps::X::ThreadedClient::DESTROY";
	my $self = shift;
	if ($self->{debug} >= 2) {
		print "Triceps::X::ThreadedClient::DESTROY\n";
	}
	$self->{owner}->app()->shutdown();
}

# Start the client connection and the threads for it.
# Waits for the connection setup to complete.
#
# @param client - the client name
sub startClient # ($self, $client, [$port])
{
	my $myname = "Triceps::X::ThreadedClient::startClient";
	my $self = shift;
	my $client = shift;
	my $port = shift;

	my $owner = $self->{owner};
	my $app = $owner->app();

	if (!$port) {
		$port = $self->{port};
		confess "$myname: missing port number, must specify in either new() or startClient()" 
			unless ($port);
	}
	if ($self->{debug}) {
		print "$myname: port ", $port, "\n";
	}

	my $sock = IO::Socket::INET->new(
		Proto => "tcp",
		PeerAddr => "localhost",
		PeerPort => $port,
	) or confess "$myname: socket failed: $!";

	my $ptext = "> connect $client\n";
	$self->{trace} .= $ptext;
	if ($self->{debug}) {
		print $ptext;
	}

	# the client threads will dup; the socket name must be the
	# same as the client name, as expected by the send/recv threads
	$app->storeFile($client, $sock);

	Triceps::Triead::start(
		app => $owner->app()->getName(),
		thread => "send_$client",
		fragment => "client_$client",
		main => \&clientSendT,
		client => $client,
		debug => ($self->{debug} >= 2),
	);

	Triceps::Triead::start(
		app => $owner->app()->getName(),
		thread => "recv_$client",
		fragment => "client_$client",
		main => \&clientRecvT,
		client => $client,
		debug => ($self->{debug} >= 2),
	);

	$owner->readyReady();
	$app->closeFd($client);
}

# Send data to a client.
#
# @param client - the client name
# @param text - the text to send
sub send # ($self, $client, $text)
{
	my $myname = "Triceps::X::ThreadedClient::send";
	my $self = shift;
	my $client = shift;
	my $text = shift;

	my $ptext = $text;
	$ptext =~ s/^/> $client|/gm;
	$self->{trace} .= $ptext;
	if ($self->{debug}) {
		print $ptext;
	}

	my $owner = $self->{owner};
	$owner->unit()->makeHashCall($self->{faSend}->getLabel("msg"), "OP_INSERT",
		client => $client,
		text => $text,
	);
	$owner->flushWriters();
}

# Send a socket shutdown request to a client.
#
# @param client - the client name
# @param how - one of "RD", "WR", "RDWR"
sub sendClose # ($self, $client, $how)
{
	my $myname = "Triceps::X::ThreadedClient::sendClose";
	my $self = shift;
	my $client = shift;
	my $how = shift;

	my $ptext = "> close $how $client\n";
	$self->{trace} .= $ptext;
	if ($self->{debug}) {
		print $ptext;
	}

	my $owner = $self->{owner};
	$owner->unit()->makeHashCall($self->{faSend}->getLabel("close"), "OP_INSERT",
		client => $client,
		text => $how,
	);
	$owner->flushWriters();
}

# Expect data from a client.
#
# @param client - the client name
# @param pattern - string containing a regexp pattern to expect
# @param timeout - the timeout for this call; if not defined then use default
#        as specified in new(); if <= 0 then unlimited; the expllicit timeout
#        overrides both the timeout and totalTimeout from new()
sub expect # ($self, $client, $pattern, [$timeout])
{
	my $myname = "Triceps::X::ThreadedClient::expect";
	my $self = shift;
	my $client = shift;
	my $pattern = shift;
	my $timeout = shift;
	my $limit = 0.;

	if (defined $timeout) {
		if ($timeout > 0.) {
			$limit = Triceps::now() + $timeout;
		}
	} else {
		$timeout = $self->{timeout};
		if (defined $timeout) {
			$limit = Triceps::now() + $timeout;
		}
		if (defined $self->{deadline}) {
			if ($limit == 0. || $limit > $self->{deadline}) {
				$limit = $self->{deadline};
				my $now = &Triceps::now();
				if ($now >= $limit) {
					$@ = "Timed out when expecting " . qr/$pattern/m;
					my $ptext = "$client|$@\n";
					$self->{trace} .= $ptext;
					$self->{errorTrace} .= $ptext;
					if ($self->{debug}) {
						print $ptext;
					}
					return;
				}
			}
		}
	}

	my $owner = $self->{owner};
	my $app = $owner->app();

	$self->{error} = undef;
	$self->{expectDone} = 0;

	if ($self->{debug} > 1) {
		print "expect: $pattern\n"
	}

	$owner->unit()->makeHashCall($self->{faCtl}->getLabel("msg"), "OP_INSERT",
		cmd => "expect",
		client => $client,
		arg => $pattern,
	);
	$owner->flushWriters();

	if ($limit > 0.) {
		while(!$self->{expectDone} && $owner->nextXtrayTimeLimit($limit)) { }
		# on timeout reset the expect and have that confirmed
		if (!$self->{expectDone}) {
			$owner->unit()->makeHashCall($self->{faCtl}->getLabel("msg"), "OP_INSERT",
				cmd => "cancel",
				client => $client,
			);
			$owner->flushWriters();
			# wait for confirmation
			while(!$self->{expectDone} && $owner->nextXtray()) { }
		}
	} else {
		while(!$self->{expectDone} && $owner->nextXtray()) { }
	}


	if ($app->isAborted()) {
		confess "$myname: app is aborted";
	}
	$@ = $self->{error};
}

# Get the collected trace.
# @return - the trace text
sub getTrace # ($self)
{
	my $self = shift;
	return $self->{trace};
}

# Get the collected trace of errors only.
# @return - the error trace text
sub getErrorTrace # ($self)
{
	my $self = shift;
	return $self->{errorTrace};
}

1;

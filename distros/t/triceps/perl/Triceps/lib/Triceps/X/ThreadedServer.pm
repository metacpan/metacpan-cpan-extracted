#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Infrastructure for a multi-threaded server.
# It's of very decent quality but needs the official tests.

use strict;

package Triceps::X::ThreadedServer;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;
use Errno qw(EINTR EAGAIN);
use IO::Socket;
use IO::Socket::INET;
use Triceps;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	printOrShut
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

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

# Start a threaded server listening on a socket, with a given or automatically
# allocated port number. It's the automatic port number allocation and the
# ability to get this port number back that makes this function useful.
#
# Examples of usage:
# {
#     my ($port, $pid) = threadedStartServer(
#             app => "chat",
#             main => \&ListenerT,
#             port => 0,
#             fork => 1,
#     );
#     print "port $port\n";
#     waitpid($pid, 0);
# }
# {
#     my ($port, $pid) = threadedStartServer(
#             app => "chat",
#             main => \&ListenerT,
#             port => 12345,
#             fork => 0,
#     );
# }
# {
#     my ($port, $thread) = threadedStartServer(
#             app => "chat",
#             main => \&ListenerT,
#             port => 0,
#             fork => -1,
#     );
#     print "port $port\n";
#     $thread->join();
# }
#
# Options:
#
# app => $appName
# Name of the application
#
# thread => $threadName
# (optional) Name for the App's first thread.
# Default: "global".
#
# main => \&mainFunc
# Main function for the App's first thread.
#
# port => $port
# Port number. Use 0 to select the port automatically.
#
# socketName => $name
# (optional) Name to use for passing the socket to the main thread.
# Default: "$threadName.listen". The main thread gets the full responsibility
# for the socket, so it should use trackGetFile().
#
# fork => 0/1/-1
# (optional) Tells how to fork the server:
#   0 - don't fork, run the App's harvester thread here
#   > 0 - fork a new process for the server
#   < 0 - run the server in this process but start a new thread for the
#       harvester
# Default: 1 (> 0).
#
# Extra options are passed through. The default set of options is:
#   app - the $appName
#   thread - the $threadName
#   main => main function (\&mainFunc)
#   socketName => name of socket stored in the App
# The port and fork are not passed through.
#
# @returns - pair ($port, $pid_or_thread): the port number on which the server is
#          listening and depending on the fork option, either the PID of the new
#          process that can be waited (fork > 0) or the thread object of the harvester 
#          thread that it can be joined or detached (fork < 0), or undef (fork == 0).
#          Obviously, if fork == 0, the port number returned is not very useful either.
sub startServer # ($optName => $optValue, ...)
{
	my $myname = "Triceps::X::ThreadedServer::startServer";
	my $opts = {};
	my @myOpts = (
		app => [ undef, \&Triceps::Opt::ck_mandatory ],
		thread => [ "global", undef ],
		main => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "CODE") } ],
		port => [ undef, \&Triceps::Opt::ck_mandatory ],
		socketName => [ undef, undef ],
		fork => [ 1, undef ],
	);
	&Triceps::Opt::parse($myname, $opts, {
		@myOpts,
		'*' => [],
	}, @_);

	if (!defined $opts->{socketName}) {
		$opts->{socketName} = $opts->{thread} . ".listen";
	}

	my $srvsock = IO::Socket::INET->new(
		Proto => "tcp",
		LocalPort => $opts->{port},
		Listen => 10,
	) or confess "$myname: socket creation failed: $!";
	my $port = $srvsock->sockport() or confess "$myname: sockport failed: $!";

	if ($opts->{fork} > 0)  {
		my $pid = fork();
		confess "$myname: fork failed: $!" unless defined $pid;
		if ($pid) {
			# parent
			$srvsock->close();
			return ($port, $pid);
		}
		# for the child, fall through
	}

	# make the app explicitly, to put the socket into it first
	my $app = Triceps::App::make($opts->{app});
	$app->storeCloseFile($opts->{socketName}, $srvsock);
	Triceps::Triead::start(
		app => $opts->{app},
		thread => $opts->{thread},
		main => $opts->{main},
		socketName => $opts->{socketName},
		&Triceps::Opt::drop({ @myOpts }, \@_),
	);
	my $tharvest;
	if ($opts->{fork} < 0) {
		@_ = (); # prevent the Perl object leaks
		$tharvest = threads->create(sub {
			# In case of errors, the Perl's join() will transmit the error 
			# message through.
			Triceps::App::find($_[0])->harvester();
		}, $opts->{app}); # app has to be passed by name
	} else {
		$app->harvester();
	}
	if ($opts->{fork} > 0) {
		exit 0; # the forked child process
	}

	return ($port, $tharvest);
}

# The thread-based logic to accept connections on a socket
# and start the new threads for them.
#
# Options:
# 
# owner => $owner
# The TrieadOwner object of the thread where this function runs.
#
# socket => $socket
# The IO::Socket object on which to accept the connections.
#
# prefix => $prefix
# The prefix that will be used to form the name of the created
# handler threads, their fragments, and the socket objects passed to them.
# The prefix will have the sequential integer values appended to it.
#
# handler => \&TrieadMainFunc
# The main function for the created handler threads.
#
# Extra options are passed through. The default set of options is:
#   app - the App name (found from $owner)
#   thread - name of thread (formed from $prefix)
#   fragment => name of fragment (same as name of the thread, formed from $prefix)
#   main => main function (\&TrieadMainFunc)
#   socketName => name of socket stored in the App (same as name of the thread, 
#     formed from $prefix), the handler thread's responsibility is to make the
#     app forget it, such as by using trackGetFile().
# The options "prefix" and "handler" are not passed through.
#
sub listen # ($optName => $optValue, ...)
{
	my $myname = "Triceps::X::ThreadedServer::listen";
	my $opts = {};
	my @myOpts = (
		owner => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::TrieadOwner") } ],
		socket => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "IO::Socket") } ],
		prefix => [ undef, \&Triceps::Opt::ck_mandatory ],
		handler => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "CODE") } ],
		pass => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
	);
	&Triceps::Opt::parse($myname, $opts, {
		@myOpts,
		'*' => [],
	}, @_);
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $prefix = $opts->{prefix};
	my $sock = $opts->{socket};

	my $clid = 0; # client id

	while(!$owner->isRqDead()) {
		my $client = $sock->accept();
		if (!defined $client) {
			my $err = "$!"; # or the text message will be reset by isRqDead()
			if ($owner->isRqDead()) {
				last;
			} elsif($!{EAGAIN} || $!{EINTR}) { # numeric codes don't get reset
				next;
			} else {
				confess "$myname: accept failed: $err";
			}
		}
		$clid++;
		my $cliname = "$prefix$clid";
		$app->storeCloseFile($cliname, $client);

		Triceps::Triead::start(
			app => $app->getName(),
			thread => $cliname,
			fragment => $cliname,
			main => $opts->{handler},
			socketName => $cliname,
			&Triceps::Opt::drop({ @myOpts }, \@_),
		);

		# Doesn't wait for the new thread(s) to become ready.
	}
}

# Sends the data to a socket, on error shuts down the app fragment.
#
# @param app - App object or name, where the current thread belongs
# @param fragment - name of the fragment where the current thread belongs
#        (this is the app fragment that will be shut down on error)
# @param sock - the socket file descriptor to print to
# @param text - arguments for print
sub printOrShut # ($app, $fragment, $sock, @text)
{
	my $app = shift;
	my $fragment = shift;
	my $sock = shift;

	undef $!;
	print $sock @_;
	$sock->flush();

	if ($!) { # can't write, so shutdown
		Triceps::App::shutdownFragment($app, $fragment);
	}
}

1;

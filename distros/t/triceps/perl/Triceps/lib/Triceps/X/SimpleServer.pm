#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A simple server implementation used in the Query examples.
# It contains many simplifications and is not of production quality.

use strict;

package Triceps::X::SimpleServer;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;
use Errno qw(EINTR EAGAIN);
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use IO::Socket;
use IO::Socket::INET;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	outBuf outCurBuf mainLoop startServer makeExitLabel makeServerOutLabel
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

#########################
# The server infrastructure

# the socket and buffering control for the main loop;
# they are all indexed by a unique id
our %clients; # client sockets
our %inbufs; # input buffers, collecting the whole lines
our %outbufs; # output buffers
our $poll; # the poll object
our $cur_cli; # the id of the current client being processed
our $srv_exit; # exit when all the client connections are closed

# Writing to the output buffers. Will also trigger the polling to
# actually send the output data to the client's socket.
#
# @param id - the client id, as generated on the client connection
#        (if the client already disconnected, this call will 
#        have no effect)
# @param string - the string to write
sub outBuf # ($id, $string)
{
	my $id = shift;
	my $line = shift;
	if (exists $clients{$id}) {
		$outbufs{$id} .= $line;
		# If there is anything to write on a buffer, stop reading from it.
		$poll->mask($clients{$id} => POLLOUT);
	}
}

# Write to the output buffer of the current client (as set in $cur_cli
# by the main loop).
#
# @param string - the string to write
sub outCurBuf # ($string)
{
	outBuf($cur_cli, @_);
}

# Close the client connection. This doesn't flush the ouput buffer,
# so it must be called only after the flush is done, or if the flush
# can not be done (such as, if the client has dropped the connection).
# It does delete all the client-related data.
#
# @param id - the client id, as generated on the client connection
# @param h - the socket handle of the client
sub _closeClient # ($id, $h)
{
	my $id = shift;
	my $h = shift;
	$poll->mask($h, 0);
	$h->close();
	delete $clients{$id}; # OK per Perl manual even when iterating
	delete $inbufs{$id};
	delete $outbufs{$id};
}

# The server main loop. Runs with the specified server socket.
# Accepts the connections from it, then polls the connections for
# input, reads the data in CSV and dispatches it using the labels hash.
#
# XXX Caveats:
# The way this works, if there is no '\n' before EOF,
# the last line won't be processed.
# Also, the whole output for all the input will be buffered
# before it can be sent.
#
# @param srvsock - the server socket handle
# @param labels - Reference to the label hash, that contains the
#        mappings used to dispatch the input, in either of formats:
#          name => label_object
#          name => code_reference
#        The input from the clients is parsed as CSV with the 1st field
#        containing the label name.  Then if the looked up dispatch is an
#        actual label, the rest of CSV fields are: the 2nd the opcode, and the rest
#        the data fields in the order of the label's row type. If the
#        looked up dispatch is a Perl sub reference, just the whole input
#        line is passed to it as an argument.
sub mainLoop # ($srvsock, $%labels)
{
	my $srvsock = shift;
	my $labels = shift;

	my $client_id = 0; # unique strings
	our $poll = IO::Poll->new();

	$srvsock->blocking(0);
	$poll->mask($srvsock => POLLIN);
	$srv_exit = 0;

	while(!$srv_exit || keys %clients != 0) {
		my $r = $poll->poll();
		confess "poll failed: $!" if ($r < 0 && ! $!{EAGAIN} && ! $!{EINTR});

		if ($poll->events($srvsock)) {
			while(1) {
				my $client = $srvsock->accept();
				if (defined $client) {
					$client->blocking(0);
					$clients{++$client_id} = $client;
					# &send("Accepted client $client_id\n");
					$poll->mask($client => (POLLIN|POLLHUP));
				} elsif($!{EAGAIN} || $!{EINTR}) {
					last;
				} else {
					confess "accept failed: $!";
				}
			}
		}

		my ($id, $h, $mask, $n, $s);
		while (($id, $h) = each %clients) {
			no warnings; # or in tests prints a lot of warnings about undefs

			$cur_cli = $id;
			$mask = $poll->events($h);
			if (($mask & POLLHUP) && !defined $outbufs{$id}) {
				# &send("Lost client $client_id\n");
				_closeClient($id, $h);
				next;
			}
			if ($mask & POLLOUT) {
				$s = $outbufs{$id};
				$n = $h->syswrite($s);
				if (defined $n) {
					if ($n >= length($s)) {
						delete $outbufs{$id};
						# now can accept more input
						$poll->mask($h => (POLLIN|POLLHUP));
					} else {
						substr($outbufs{$id}, 0, $n) = '';
					}
				} elsif(! $!{EAGAIN} && ! $!{EINTR}) {
					warn "write to client $id failed: $!";
					_closeClient($id, $h);
					next;
				}
			}
			if ($mask & POLLIN) {
				$n = $h->sysread($s, 10000);
				if ($n == 0) {
					# &send("Lost client $client_id\n");
					_closeClient($id, $h);
					next;
				} elsif ($n > 0) {
					$inbufs{$id} .= $s;
				} elsif(! $!{EAGAIN} && ! $!{EINTR}) {
					warn "read from client $id failed: $!";
					_closeClient($id, $h);
					next;
				}
			}
			# The way this works, if there is no '\n' before EOF,
			# the last line won't be processed.
			# Also, the whole output for all the input will be buffered
			# before it can be sent.
			while($inbufs{$id} =~ s/^(.*)\n//) {
				my $line = $1;
				chomp $line;
				{
					local $/ = "\r"; # take care of a possible CR-LF in this block
					chomp $line;
				}
				my @data = split(/,/, $line);
				my $lname = shift @data;
				my $label = $labels->{$lname};
				if (defined $label) {
					if (ref($label) eq 'CODE') {
						&$label($line);
					} else {
						my $unit = $label->getUnit();
						confess "label '$lname' received from client $id has been cleared"
							unless defined $unit;
						eval {
							$unit->makeArrayCall($label, @data);
							$unit->drainFrame();
						};
						warn "input data error: $@\nfrom data: $line\n" if $@;
					}
				} else {
					warn "unknown label '$lname' received from client $id: $line "
				}
			}
		}
	}
}

# The server start function that creates the server socket,
# remembers its port number, then forks and
# starts the main loop in the child process. The parent
# process then returns the pair (port number, child PID).
#
# @param port - the port number to use; 0 will cause a unique free
#        port number to be auto-assigned
# @param labels - reference to the label hash, to be passed to mainLoop()
# @return - pair (port number, child PID) that can then be used to connect
#        to and control the server in the child process
sub startServer # ($port, $%labels)
{
	my $port = shift;
	my $labels = shift;

	my $srvsock = IO::Socket::INET->new(
		Proto => "tcp",
		LocalPort => $port,
		Listen => 10,
	) or confess "socket failed: $!";
	# Read back the port, since the port 0 will cause a free port
	# to be auto-assigned.
	$port = $srvsock->sockport() or confess "sockport failed: $!";
	my $pid = fork();
	confess "fork failed: $!" unless defined $pid;
	if ($pid) {
		# parent
		$srvsock->close();
	} else {
		# child
		&mainLoop($srvsock, $labels);
		exit(0);
	}
	return ($port, $pid);
}

# A dispatch function, sending anything to which will exit the server.
# The server will not flush the outputs before exit.
#
# Use like:
#   $dispatch{"exit"} = \&Triceps::X::SimpleServer::exitFunc;
#
# In this way the input line doesn't have to contain the opcode.
# The alternative way is through makeExitLabel().
sub exitFunc # ($line)
{
		$srv_exit = 1;
}

# Create a label, sending anything to which will exit the server.
# The server will not flush the outputs before exit.
#
# Use like:
#   $dispatch{"exit"} = &Triceps::X::SimpleServer::makeExitLabel($uTrades, "exit");
#
# In this way the input line has to contain at least the opcode.
# The alternative way is through exitFunc().
#
# @param unit - the unit in which to create the label
# @param name - the label name
# @return - the newly created label object
sub makeExitLabel # ($unit, $name)
{
	my $unit = shift;
	my $name = shift;
	return $unit->makeLabel($unit->getEmptyRowType(), $name, undef, sub {
		$srv_exit = 1;
	});
}

# Create a label that will print the data in CSV format to the server output
# (to the current client).
#
# @param fromLabel - the new label will be chained to this one and get the
#        data from it
# @param printName - if present, overrides the label name printed
# @return - the newly created label object
sub makeServerOutLabel # ($fromLabel [, $printName])
{
	no warnings; # or in tests prints a lot of warnings about undefs
	my $fromLabel = shift;
	my $printName = shift;
	my $unit = $fromLabel->getUnit();
	my $fromName = $fromLabel->getName();
	if (!$printName) {
		$printName = $fromName;
	}
	my $lbOut = $unit->makeLabel($fromLabel->getType(), 
		$fromName . ".serverOut", undef, sub {
			&outCurBuf(join(",", $printName, 
				&Triceps::opcodeString($_[1]->getOpcode()),
				$_[1]->getRow()->toArray()) . "\n");
		});
	$fromLabel->chain($lbOut);
	return $lbOut;
}

1;

#############################################################################
#
# Win32::ProcFarm::Parent - stand-in for child process in ProcFarm RPC system
#
# Author: Toby Everett
# Revision: 2.15
# Last Change: Added support for exe-based child process
#############################################################################
# Copyright 1999, 2000, 2001 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
#############################################################################

=head1 NAME

Win32::ProcFarm::Parent - stand-in for child process in ProcFarm RPC system

=head1 SYNOPSIS

	use Win32::ProcFarm::Parent;
	use Win32::ProcFarm::Port;

	$port_obj = Win32::ProcFarm::Port->new(9000, 1);

	$iface = Win32::ProcFarm::Parent->new_async($port_obj, 'Child.pl', Win32::GetCwd);

	$iface->connect;

	$iface->execute('child_sub', @params);

	until($iface->get_state eq 'fin') {
		print "Waiting for ReturnValue.\n";
		sleep(1);
	}
	print "GotReturnValue.\n";
	print $iface->get_retval;

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker as part of Win32::ProcFarm.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the I haven't written a test suite yet.

=head2 State Diagram

C<Win32::ProcFarm::Parent> is designed to provide support for asynchronous subroutine calls
against the child process.  To support this, the C<Win32::ProcFarm::Parent> object can be in one
of four states.

=over 4

= item C<init>

In the C<init> state, the C<Win32::ProcFarm::Parent> object has been asynchronously spun off, but
has yet to establish a communications channel via the C<Win32::ProcFarm::Port> object.  A call to
the C<connect> method will rectify this situation and move the object into the C<idle> state.

=item C<idle>

In the C<idle> state, the child process has yet to be assigned a task and is waiting for one to be
assigned.  A call to the C<execute> method will assign the child process a task and move the
C<Win32::ProcFarm::Parent> object into the C<wait> state.

=item C<wait>

In the C<wait> state, the child process has been assigned a task and is busy executing it.  Calls
to the C<get_state> method will check to see if the task has finished executing.  If it has, the
C<Win32::ProcFarm::Parent> object will retrieve the return values, store them internally, and move
the object into the C<fin> state.

=item C<fin>

In the C<fin> state, the C<Win32::ProcFarm::Parent> object is waiting for the return values to be
retrieved by the C<get_retval> method.  A call to that method will return the values and move the
object back into the C<idle> state.

=back

=head1 METHODS

=cut

use Data::Dumper;
use Win32::Process;
use Win32::ProcFarm::Port;
use Win32::ProcFarm::TickCount;

package Win32::ProcFarm::Parent;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.15';

$Win32::ProcFarm::Parent::unique = 0;
$Win32::ProcFarm::Parent::processes = {};

=head2 new_async

The C<new_async> method creates a new C<Win32::ProcFarm::Parent> object and spins off the child
process, but does not initiate communication with it.  The C<Win32::ProcFarm::Parent> object is
left in the C<init> state.

The parameters are:

=over 4

=item $port_obj

A C<Win32::ProcFarm::Port> object that will be connected to by the child processes.

=item $script

The script name to execute for the child processes.

=item $curdir

The working directory to use when running the script.  If this is the same directory the script is
in, the script name can be specified without a path.

=item $timeout

An optional value indicating how long jobs should be allowed to execute before they are deemed to
have blocked.  Blocked jobs will be terminated and a new process created to take their place.

=back

=cut

sub new_async {
	my $class = shift;
	my($port_obj, $script, $curdir, $timeout) = @_;

	my $self = {
		'port_obj' => $port_obj,
		'rin' => undef,
		'socket' => undef,
		'state' => undef,
		'timeout' => $timeout,
		'start' => undef,
		'retval' => undef,
		'script' => $script,
		'curdir' => $curdir,
	};
	bless $self, $class;

	$self->_new_async;

	return $self;
}

sub _new_async {
	my $self = shift;

	my $process;
	my $unique = $Win32::ProcFarm::Parent::unique++;
	my $port_num = $self->{port_obj}->get_port_num;
	my $script = $self->{script};
	if ($script =~ /\.exe$/i) {
		Win32::Process::Create($process, $script, "$script $port_num $unique", 0, 0, $self->{curdir}) or
				die "Unable to start child process using '$script'.\n";
	} else {
		(my $perl_exe = $^X) =~ s/\\[^\\]+$/\\Perl.exe/;
		Win32::Process::Create($process, $perl_exe, "perl $script $port_num $unique", 0, 0, $self->{curdir}) or
				die "Unable to start child process using '$perl_exe'.\n";
	}
	$Win32::ProcFarm::Parent::processes->{$unique} = $process;
	$self->{state} = 'init';
	return $self;
}

=head2 connect

The C<connect> method initiates communication with B<a> child process.  Note that we cannot
presume that the order in which the child processes connect to the TCP port is the same order in
which they were started.  The first thing the child process does upon the TCP connection being
accepted is to send its unique identifier, which the C<Win32::ProcFarm::Parent> object uses to
retrieve the appropriate C<Win32::Process> from the class hash of those objects.

The C<connect> call moves the C<Win32::ProcFarm::Parent> object into the C<idle> state.

=cut

sub connect {
	my $self = shift;

	$self->{state} eq 'init' or die "Illegal call to connect on Win32::ProcFarm::Parent object in state $self->{state}.";
	$self->{socket} = $self->{port_obj}->get_next_connection;

	my $unique;
	read($self->{socket}, $unique, 4) == 4 or die "Unable to read unique identifier.\n";
	$unique = unpack("V", $unique);
	exists $Win32::ProcFarm::Parent::processes->{$unique} or die "Missing process object for $unique.";
	$self->{process_obj} = $Win32::ProcFarm::Parent::processes->{$unique};
	delete $Win32::ProcFarm::Parent::processes->{$unique};

	$self->{rin} = '';
	vec($self->{rin}, fileno($self->{socket}), 1) = 1;
	$self->{state} = 'idle';
}

=head2 execute

The C<execute> command instructs the child process to start executing a given subroutine with a
list of passed parameters.  The data is send over the socket connection and the
C<Win32::ProcFarm::Parent> object moved into the C<wait> state.

=cut

sub execute {
	my $self = shift;
	my($command, @params) = @_;

	$self->{state} eq 'idle' or die "Illegal call to execute on Win32::ProcFarm::Parent object in state $self->{state}.";
	my $cmdstr = Data::Dumper->Dump([$command, \@params], ["command", "ptr2params"]);
	my $temp = $self->{socket};
	print $temp (pack("V", length($cmdstr)).$cmdstr);
	$self->{start} = Win32::GetTickCount();
	$self->{state} = 'wait';
}

=head2 get_state

The C<get_state> method returns the current state.  If the current state is C<wait>, the method
first checks to see if the child process has finished executing the subrouting call.  If it has,
the method retrieves the return data and moves the C<Win32::ProcFarm::Parent> object into the
C<fin> state.

The C<get_state> method is also responsible for dealing with timeout scenarios where the child
process has exceeded the time allowed to execute the subroutine.  In that situation, the child
process is terminated and a new child process initiated, connected to, and the
C<Win32::ProcFarm::Parent> object placed in the C<fin> state.

=cut

sub get_state {
	my $self = shift;

	if ($self->{state} eq 'wait') {
		my $rout;
		select($rout=$self->{rin}, undef, undef, 0);
		if ($rout eq $self->{rin}) {
			$self->{retval} = $self->_get_retval;
			$self->{state} = 'fin';
		} else {
			if ($self->{timeout} and Win32::ProcFarm::TickCount::compare(1000*$self->{timeout}+$self->{start}, Win32::GetTickCount()) == -1) {
				$self->_reset();
			}
		}
	}
	return $self->{state};
}

=head2 get_retval

The C<get_retval> method returns the list of return values returned by the child process and moves
the C<Win32::ProcFarm::Parent> object into the C<idle> state.

=cut

sub get_retval {
	my $self = shift;

	$self->{state} eq 'fin' or die "Illegal call to get_retval on Win32::ProcFarm::Parent object in state $self->{state}.";
	my $temp = $self->{retval};
	$self->{retval} = undef;
	$self->{state} = 'idle';
	return(@{$temp});
}

sub _get_retval {
	my $self = shift;
	my($len, $retstr);

	unless (read($self->{socket}, $len, 4) == 4) {
		$self->_reset;
		return [];
	}
	$len = unpack("V", $len);
	unless (read($self->{socket}, $retstr, $len) == $len) {
		$self->_reset;
		return [];
	}

	my $ptr2retval;
	eval($retstr);
	return $ptr2retval;
}

sub _reset {
	my $self = shift;

	close($self->{socket});
	unless ($self->{process_obj}->Wait(1)) {
		$self->{process_obj}->Kill(0);
	}
	$self->_new_async;
	$self->connect;
	$self->{retval} = [];
	$self->{state} = 'fin';
}

sub DESTROY {
	my $self = shift;

	foreach my $i (values %{$Win32::ProcFarm::Parent::processes}) {
		unless ($i->Wait(1)) {
			$i->Kill(0);
		}
	}
	$Win32::ProcFarm::Parent::processes = {};

	$self->{socket} and close($self->{socket});
	if ($self->{process_obj}) {
		unless ($self->{process_obj}->Wait(1)) {
			$self->{process_obj}->Kill(0);
		}
	}
}

1;

#############################################################################
#
# Win32::ProcFarm::PerpetualPool - manages a pool of child processes for perpetual jobs
#
# Author: Toby Everett
# Revision: 2.15
# Last Change: Patched to fix problems when Win32::GetTickCount > 2**31
#############################################################################
# Copyright 1999, 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
#############################################################################


=head1 NAME

Win32::ProcFarm::PerpetualPool - manages a pool of child processes for perpetual jobs

=head1 SYNOPSIS

	use Win32::ProcFarm::PerpetualPool;

	$Pool = Win32::ProcFarm::PerpetualPool->new($poolsize, $portnum, $scriptname, Win32::GetCwd,
		command => 'whatever',
		list_check_intvl => 30,
		exit_check_intvl => 5,
		list_sub => sub { return ('Fred', 'Julie', 'Joe') },
		exit_sub => sub { return -e 'killme'; },
		result_sub => sub { print join(', ' @_)."\n"; },
	);

	$Pool->start_pool(0.1);

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker as part of Win32::ProcFarm.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the I haven't written a test suite yet.

=head2 More usage instructions

This is a version of Win32::ProcFarm::Pool designed for continuous operation.  You supply a single
command name and a subroutine that returns a list of keys.  The keys are passed as the sole
parameter to the command (it is presumed that the child process can do whatever needs to be done
based on that single key).  The subroutine that returns the list of keys will be periodically
executed (every 120 seconds by default, but adjustable via list_intvl) and the running list
updated as needed.  Whenever a job finishes, that key is added back onto the end of the waiting
pool.

=head1 METHODS

=cut

use Win32::ProcFarm::Pool;
use Win32::ProcFarm::TickCount;

package Win32::ProcFarm::PerpetualPool;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.15';

@ISA = qw(Win32::ProcFarm::Pool);

sub new {
	my $class = shift;

	my($num_threads, $port_num, $script, $curdir, %options) = @_;
	my $self = $class->SUPER::new($num_threads, $port_num, $script, $curdir, %options);

	foreach my $i (qw(command list_check_intvl list_sub exit_check_intvl exit_sub)) {
		exists $options{$i} and $self->{$i} = $options{$i};
	}

	$self->{current_hash} = {};
	$self->{death_hash} = {};
	$self->{next_list_check} = Win32::GetTickCount();
	$self->{next_exit_check} = Win32::GetTickCount();
	$self->{state} = 'running';
	defined $self->{list_check_intvl} or $self->{list_check_intvl} = 60;
	defined $self->{exit_check_intvl} or $self->{exit_check_intvl} = 2;

	bless $self, $class;
	return $self;
}

sub list_check {
	my $self = shift;

	$self->{state} eq 'running' or return;

	my %temp;
	@temp{$self->{list_sub}->($self)} = ();

	foreach my $i (keys %temp) {
		if (!exists $self->{current_hash}->{$i}) {
			$self->add_waiting_job($i, $self->{command}, $i);
			$self->{current_hash}->{$i} = undef;
		}
	}

	foreach my $i (keys %{$self->{current_hash}}) {
		if (!exists $temp{$i}) {
			$self->{death_hash}->{$i} = undef;
			delete $self->{current_hash}->{$i};
		}
	}
}

sub exit_check {
	my $self = shift;

	$self->{state} eq 'running' or return;

	ref($self->{exit_sub}) eq 'CODE' or return;
	if ($self->{exit_sub}->($self)) {
		$self->{waiting_pool} = [];
		$self->{death_hash} = {};
		$self->{state} = 'stopping';
	}
}

sub start_pool {
	my $self = shift;
	my($sleep) = @_;

	while (1) {
		$self->cleanse_and_dispatch();
		if ($self->{state} eq 'stopping' && ($self->count_waiting + $self->count_running) == 0 ) {
			$self->{state} = 'stopped';
			last;
		}
		$sleep and Win32::Sleep($sleep*1000);
	}
}

sub cleanse_and_dispatch {
	my $self = shift;

	if (Win32::ProcFarm::TickCount::compare($self->{next_list_check}, Win32::GetTickCount()) == -1) {
		$self->list_check();
		$self->{next_list_check} = Win32::GetTickCount() + $self->{list_check_intvl} * 1000;
	}

	if (Win32::ProcFarm::TickCount::compare($self->{next_exit_check}, Win32::GetTickCount()) == -1) {
		$self->exit_check();
		$self->{next_exit_check} = Win32::GetTickCount() + $self->{exit_check_intvl} * 1000;
	}

	return $self->SUPER::cleanse_and_dispatch;
}

sub cleanse_thread {
	my $self = shift;
	my($thread) = @_;

	$thread->{Parent}->get_state eq 'fin' or return 0;

	my @temp = $thread->{Parent}->get_retval;
	if (ref($self->{result_sub}) eq 'CODE') {
		$self->{result_sub}->($thread->{key}, @temp);
	}

	if ($self->{state} eq 'running') {
		$self->add_waiting_job($thread->{key}, $self->{command}, $thread->{key});
	}

	$thread->{key} = undef;
	return 1;
}

sub dispatch_job {
	my $self = shift;
	my($thread) = @_;

	$thread->{Parent}->get_state eq 'idle' or return 0;
	my $job = $self->get_next_job() or return 0;
	$thread->{Parent}->execute($job->{command}, @{$job->{params}});
	$thread->{key} = $job->{key};
	return 1;
}

sub get_next_job {
	my $self = shift;

	my $job;
	while ($job = shift(@{$self->{waiting_pool}})) {
		if (exists $self->{death_hash}->{$job->{key}}) {
			delete $self->{death_hash}->{$job->{key}};
			next;
		}
		return $job;
	}
	return undef;
}

1;

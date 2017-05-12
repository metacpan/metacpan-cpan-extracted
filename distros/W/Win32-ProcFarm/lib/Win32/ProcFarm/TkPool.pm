#############################################################################
#
# Win32::ProcFarm::TkPool - Tk based child process pool that allows for async
#                           callbacks under a Tk event loop
#
# Author: Toby Everett
# Revision: 2.15
# Last Change: Modified in response to rearchitecture of Win32::ProcFarm::Pool
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

use Win32::ProcFarm::Port;
use Win32::ProcFarm::Pool;
use Tk;

BEGIN {
	use Win32::ProcFarm::Parent;

	$Win32::ProcFarm::Parent::ref2oldconnect = \&Win32::ProcFarm::Parent::connect;
}

sub Win32::ProcFarm::Parent::connect {
	my $self = shift;
	$Win32::ProcFarm::Parent::ref2oldconnect->($self, @_);
	if (ref($Win32::ProcFarm::TkPool::connect_callbacks{$self->{port_obj}->get_port_num}) eq 'CODE') {
		$Win32::ProcFarm::TkPool::connect_callbacks{$self->{port_obj}->get_port_num}->();
	}
}


package Win32::ProcFarm::TkPool;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.15';

@ISA = qw(Win32::ProcFarm::Pool);

sub new {
	my $class = shift;
	my($num_threads, $port_num, $perlscript, $curdir, %options) = @_;

	if (exists($options{connect_callback})) {
		$Win32::ProcFarm::TkPool::connect_callbacks{$port_num} = $options{connect_callback};
	}

	my $self = $class->SUPER::new($num_threads, $port_num, $perlscript, $curdir, %options);

	foreach my $i (qw(cnd_callback)) {
		exists $options{$i} and $self->{$i} = $options{$i};
	}

	$options{mw}->repeat($options{sleep} || 100, sub {$self->cleanse_and_dispatch()});

	return $self;
}

sub add_waiting_job {
	my $self = shift;
	my(%params) = @_;

	push(@{$self->{waiting_pool}}, {%params});
}

sub cleanse_thread {
	my $self = shift;
	my($thread) = @_;

	$thread->{Parent}->get_state eq 'fin' or return 0;

	my @temp = $thread->{Parent}->get_retval;
	if (ref($thread->{return_callback}) eq 'CODE') {
		$thread->{return_callback}->(@temp);
	}
	$thread->{return_callback} = undef;
	return 1;
}

sub dispatch_job {
	my $self = shift;
	my($thread) = @_;

	$thread->{Parent}->get_state eq 'idle' or return 0;
	my $job = $self->get_next_job() or return 0;

	$thread->{Parent}->execute($job->{command}, @{$job->{params}});
	$thread->{return_callback} = $job->{return_callback};
	if (ref($job->{start_callback}) eq 'CODE') {
		$job->{start_callback}->();
	}
	return 1;
}

sub cleanse_and_dispatch {
	my $self = shift;

	$self->SUPER::cleanse_and_dispatch();

	if (ref($self->{cnd_callback}) eq 'CODE') {
		$self->{cnd_callback}->($self);
	}
}

1;

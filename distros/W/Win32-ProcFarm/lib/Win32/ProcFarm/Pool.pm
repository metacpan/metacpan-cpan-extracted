#############################################################################
#
# Win32::ProcFarm::Pool - manages a pool of child processes
#
# Author: Toby Everett
# Revision: 2.15
# Last Change: Update to support max_rate and result_sub
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

Win32::ProcFarm::Pool - manages a pool of child processes

=head1 SYNOPSIS

	use Win32::ProcFarm::Pool;

	$Pool = Win32::ProcFarm::Pool->new($poolsize, $portnum, $scriptname, Win32::GetCwd);

	foreach $i (@list) {
		$Pool->add_waiting_job($i, 'child_sub', $i);
	}

	$Pool->do_all_jobs(0.1);

	%ping_data = $Pool->get_return_data;
	$Pool->clear_return_data;

	foreach $i (@list) {
		print "$i:\t$ping_data{$i}->[0]\n";
	}

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker as part of Win32::ProcFarm.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the I haven't written a test suite yet.

=head2 More usage instructions

See C<Docs/tutorial.pod> for more information.

=head1 METHODS

=cut

use Win32::ProcFarm::Parent;
use Win32::ProcFarm::Port;

package Win32::ProcFarm::Pool;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.15';

=head2 new

The C<new> method creates a new C<Win32::ProcFarm::Pool> object (amazing, eh!).
It takes 5 parameters:

=over 4

=item $num_threads

This indicates the number of threads that should be created.

=item $port_num

This indicates the port number to use for the listener.

=item $script

The script name to execute for the child processes.

=item $curdir

The working directory to use when running the script.  If this is the same
directory the script is in, the script name can be specified without a path.

=item %options

A hash of options.  The current options are:

=over 4

=item timeout

Indicates how long jobs should be allowed to execute before they are deemed to
have blocked. Blocked jobs will be terminated and a new process created to take
their place.

=item listeners

Indicates how many listeners should be allocated on the port object.  During
thread instantiation, this controls how many unconnected threads can be spun
off.  For optimum thread creation speed, this should be set to one more than
the number of processors.  By default, this is set to three.  Setting this to
too high a value does not appear to have much effect on the overall thread
creation rate, but setting it to two low a value (such as one) could have a
dramatic effect on the thread creation rate for multiprocessor machines.

=item result_sub

If specified, the attached subroutine will be called as soon as each job
finishes executing.  The subroutine will be passed the key name and then return
values.  This allows for asynchronous reponses to job execution, rather than
having to wait for the entire pool to finish running before operating on the
results.

=back

=back

=cut

sub new {
	my $class = shift;

	my($num_threads, $port_num, $script, $curdir, %options) = @_;
	my $self = {
		'num_threads' => 0,
		'port_obj' => undef,
		'thread_pool' => [],
		'waiting_pool' => [],
		'ondeck_pool' => [],
		'return_data' => {},
		'script' => $script,
		'curdir' => $curdir,
	};

	foreach my $i (qw(timeout listeners result_sub)) {
		exists $options{$i} and $self->{$i} = $options{$i};
	}

	$self->{listeners} ||= 3;

	$self->{port_obj} = Win32::ProcFarm::Port->new($port_num, $self->{listeners});

	bless $self, $class;

	$self->add_threads($num_threads);
	return $self;
}

=head2 add_threads

The C<add_threads> method call adds additional threads to a pool.  The only
accepted parameter is the number of new threads to add.

=cut

sub add_threads {
	my $self = shift;

	my($add_threads) = @_;

	$add_threads >= 0 or die "Attempt to delete threads via Win32::ProcFarm::Pool::add_threads.\n";

	my(@temp);
	foreach my $i (0..$self->{listeners}-1) {
		$add_threads or last;

		my $temp = Win32::ProcFarm::Parent->new_async($self->{port_obj}, $self->{script}, $self->{curdir}, $self->{timeout});
		push(@{$self->{thread_pool}}, {
			'key' => undef,
			'Parent' => $temp
		});
		push(@temp, $temp);

		$add_threads--;
		$self->{num_threads}++;
	}

	while (my $temp = shift @temp) {
		$temp->connect;
		$add_threads or next;

		my $temp = Win32::ProcFarm::Parent->new_async($self->{port_obj}, $self->{script}, $self->{curdir}, $self->{timeout});
		push(@{$self->{thread_pool}}, {
			'key' => undef,
			'Parent' => $temp
		});
		push(@temp, $temp);

		$add_threads--;
		$self->{num_threads}++;
	}
}

=head2 min_threads

The C<min_threads> increases the number of threads in the pool to the specified
value.  If there are more threads in the pool that the specified value, the
number of threads in the pool is unchanged.

=cut

sub min_threads {
	my $self = shift;

	my($num_threads) = @_;

	if ($num_threads >= $self->{num_threads}) {
		$self->add_threads($num_threads - $self->{num_threads});
	}
}

=head2 add_waiting_job

The C<add_waiting_job> method adds a job to the waiting pool.  It takes three parameters:

=over 4

=item $key

This should be a unique identifier that will be used to retrieve the return values from the
return data hash.

=item $command

The name of the subroutine that the child process will execute.

=item @params

A list of parameters for that subroutine.

=back

=cut

sub add_waiting_job {
	my $self = shift;
	my($key, $command, @params) = @_;

	push(@{$self->{waiting_pool}}, {'key' => $key, 'command' => $command, 'params' => [@params]});
}

=head2 do_all_jobs

The C<do_all_jobs> command will execute all the jobs in the waiting pool.  The
first passed parameter specifies the number of seconds to wait between sweeps
through the thread pool to check for completed jobs.  The number of seconds can
be fractional (i.e. 0.1 for a tenth of a second).  The second passed parameter
specifies the minimum interval between jobs becoming eligible to run.

=cut

sub do_all_jobs {
	my $self = shift;
	my($sleep, $intvl) = @_;

	if ($intvl) {
		push(@{$self->{ondeck_pool}}, @{$self->{waiting_pool}});
		@{$self->{waiting_pool}} = ();
	}

	my $start_time = time();
	my $count = 0;

	while ($self->count_ondeck + $self->count_waiting + $self->count_running) {
		if ($intvl) {
			while ((time()-$start_time)/$intvl > $count) {
				push(@{$self->{waiting_pool}}, shift(@{$self->{ondeck_pool}}));
				$count++;
			}
		}
		$self->cleanse_and_dispatch;
		$sleep and Win32::Sleep($sleep*1000);
	}
}

=head2 get_return_data

Return the return_data hash, indexed on the unique key passed initially.

=cut

sub get_return_data {
	my $self = shift;

	return (%{$self->{return_data}});
}

=head2 clear_return_data

Clears out the return_data hash.

=cut

sub clear_return_data {
	my $self = shift;

	$self->{return_data} = {};
}

=head1 INTERNAL METHODS

These methods are considered internal methods.  Child classes of Win32::ProcFarm::Pool may modify
these methods in order to change the behavior of the resultant Pool object.

=cut

sub count_waiting {
	my $self = shift;

	return scalar(@{$self->{waiting_pool}});
}

sub count_ondeck {
	my $self = shift;

	return scalar(@{$self->{ondeck_pool}});
}

sub count_running {
	my $self = shift;

	return scalar(grep {$_->{Parent}->get_state ne 'idle'} @{$self->{thread_pool}});
}



sub cleanse_pool {
	my $self = shift;

	my $retval;

	foreach my $i (@{$self->{thread_pool}}) {
		$retval += $self->cleanse_thread($i);
	}
	return $retval;
}

sub dispatch_jobs {
	my $self = shift;

	my $retval;

	foreach my $i (@{$self->{thread_pool}}) {
		$retval += $self->dispatch_job($i);
	}

	return $retval;
}

sub cleanse_and_dispatch {
	my $self = shift;

	my($retval_c, $retval_d, $job);

	foreach my $i (@{$self->{thread_pool}}) {
		$retval_c += $self->cleanse_thread($i);
		$retval_d += $self->dispatch_job($i);
	}

	return ($retval_c, $retval_d);
}



sub cleanse_thread {
	my $self = shift;
	my($thread) = @_;

	$thread->{Parent}->get_state eq 'fin' or return 0;

	my $temp = $self->{return_data}->{$thread->{key}} = [$thread->{Parent}->get_retval];

	if (ref($self->{result_sub}) eq 'CODE') {
		$self->{result_sub}->($thread->{key}, @{$temp});
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

	return shift(@{$self->{waiting_pool}});
}

1;

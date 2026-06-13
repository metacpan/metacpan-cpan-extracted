package Zuzu::Value::Task;

use utf8;

our $VERSION = '0.004000';

use Moo;
use Scalar::Util qw( blessed refaddr );
use Storable qw( fd_retrieve nstore_fd );
use POSIX qw( WNOHANG );
use Time::HiRes qw( sleep time );

has 'name' => ( is => 'rw', default => sub { '<task>' } );
has 'thunk' => ( is => 'rw' );
has 'status' => ( is => 'rw', default => sub { 'pending' } );
has 'result' => ( is => 'rw' );
has 'error' => ( is => 'rw' );
has 'pid' => ( is => 'rw' );
has 'reader' => ( is => 'rw' );
has 'ready_at' => ( is => 'rw' );
has 'poll_cb' => ( is => 'rw' );
has 'on_cancel' => ( is => 'rw' );
has 'scheduler' => ( is => 'rw' );
has 'group' => ( is => 'rw' );
has 'id' => ( is => 'rw' );
has 'parent_id' => ( is => 'rw' );
has 'file' => ( is => 'rw' );
has 'line' => ( is => 'rw' );
has 'cancel_reason' => ( is => 'rw' );
has 'coro' => ( is => 'rw' );
has 'use_coro' => ( is => 'rw', default => sub { 0 } );
has 'runtime_stack' => ( is => 'rw' );
has 'cleanup_ran' => ( is => 'rw', default => sub { 0 } );

sub is_truthy { 1 }

sub to_String {
	my ( $self ) = @_;

	return '[Task ' . $self->status . ']';
}

sub is_done {
	my ( $self ) = @_;

	return 1
		if $self->status eq 'fulfilled'
		or $self->status eq 'rejected'
		or $self->status eq 'cancelled';
	return 0;
}

sub _cleanup_if_done {
	my ( $self ) = @_;

	$self->scheduler->cleanup_task($self)
		if $self->is_done
		and defined $self->scheduler
		and $self->scheduler->can('cleanup_task');

	return $self;
}

sub start {
	my ( $self ) = @_;

	return $self if $self->status ne 'pending';

	pipe( my $reader, my $writer )
		or die "Could not create task pipe: $!";
	my $pid = fork();
	die "Could not fork task: $!" if !defined $pid;

	if ( $pid == 0 ) {
		close $reader;
		eval { setpgrp( 0, 0 ); 1 };
		my $payload;
		my $ok = eval {
			my $thunk = $self->thunk;
			my $value = defined $thunk ? $thunk->() : undef;
			while (
				blessed($value)
				and $value->isa('Zuzu::Value::Task')
				and $value != $self
			) {
				$value = $value->await;
			}
			$payload = {
				ok => 1,
				value => $value,
			};
			1;
		};
		if ( !$ok ) {
			$payload = {
				ok => 0,
				error => $@,
			};
		}
		my $stored = eval {
			nstore_fd( $payload, $writer );
			1;
		};
		if ( !$stored ) {
			my $fallback = {
				ok => 0,
				error_string => "Task result could not be serialized: $@",
			};
			eval { nstore_fd( $fallback, $writer ); 1 };
		}
		close $writer;
		require POSIX;
		POSIX::_exit(0);
	}

	close $writer;
	$self->pid($pid);
	$self->reader($reader);
	$self->status('running');

	return $self;
}

sub _finish_running {
	my ( $self, $already_waited ) = @_;

	my $payload = eval { fd_retrieve( $self->reader ) };
	my $retrieve_error = $@;
	close $self->reader if $self->reader;
	waitpid( $self->pid, 0 ) if !$already_waited and defined $self->pid;

	if ( !$payload ) {
		$self->error(
			"Task failed before returning a result: $retrieve_error"
		);
		$self->status('rejected');
	}
	elsif ( $payload->{ok} ) {
		$self->result( $payload->{value} );
		$self->status('fulfilled');
	}
	else {
		$self->error(
			exists $payload->{error}
				? $payload->{error}
				: $payload->{error_string}
		);
		$self->status('rejected');
	}

	return $self;
}

sub poll {
	my ( $self ) = @_;

	return 1
		if $self->_cleanup_if_done->is_done;
	if (
		$self->status eq 'pending'
		and defined $self->scheduler
		and $self->use_coro
	) {
		$self->scheduler->start_coro_task($self);
		return $self->is_done ? 1 : 0;
	}
	if ( $self->status eq 'pending' and defined $self->scheduler ) {
		$self->scheduler->run_pending_task($self);
		return $self->is_done ? 1 : 0;
	}
	if ( $self->status eq 'sleeping' ) {
		return 0 if time < ( $self->ready_at // 0 );
		$self->result(undef);
		$self->status('fulfilled');
		$self->_cleanup_if_done;
		return 1;
	}
	if ( $self->status eq 'waiting' ) {
		my $poll = $self->poll_cb;
		return 0 if !defined $poll;
		my ( $done, $ok, $value ) = $poll->();
		return 0 if !$done;
		if ( $ok ) {
			$self->result($value);
			$self->status('fulfilled');
		}
		else {
			$self->error($value);
			$self->status('rejected');
		}
		$self->_cleanup_if_done;
		return 1;
	}
	return 0 if $self->status ne 'running';
	return 0 if !defined $self->pid;

	my $kid = waitpid( $self->pid, WNOHANG );
	return 0 if $kid == 0;
	$self->_finish_running(1);
	$self->_cleanup_if_done;

	return 1;
}

sub _run_pending {
	my ( $self ) = @_;

	return $self if $self->status ne 'pending';

	my $value;
	my $ok = eval {
		$self->status('running');
		my $thunk = $self->thunk;
		$value = defined $thunk ? $thunk->() : undef;
		while (
			blessed($value)
			and $value->isa('Zuzu::Value::Task')
			and $value != $self
		) {
			$value = $value->await;
		}
		1;
	};
	if ( $ok ) {
		$self->result($value);
		$self->status('fulfilled');
	}
	else {
		if ( $self->status ne 'cancelled' ) {
			$self->error($@);
			$self->status('rejected');
		}
	}
	$self->_cleanup_if_done;

	return $self;
}

sub _run_body {
	my ( $self ) = @_;

	my $value;
	my $ok = eval {
		my $thunk = $self->thunk;
		$value = defined $thunk ? $thunk->() : undef;
		while (
			blessed($value)
			and $value->isa('Zuzu::Value::Task')
			and $value != $self
		) {
			$value = $value->await;
		}
		1;
	};
	if ( $ok ) {
		$self->result($value);
		$self->status('fulfilled');
	}
	else {
		if ( $self->status ne 'cancelled' ) {
			$self->error($@);
			$self->status('rejected');
		}
	}
	$self->_cleanup_if_done;

	return $self;
}

sub _run_cancel_cleanup {
	my ( $self ) = @_;

	return if $self->cleanup_ran;
	$self->cleanup_ran(1);
	my %seen;
	for my $env ( reverse @{ $self->runtime_stack // [] } ) {
		next if !blessed($env) or !$env->can('slots');
		for my $ref ( values %{ $env->slots // {} } ) {
			next if ref($ref) ne 'SCALAR';
			my $value = $$ref;
			next
				if !blessed($value)
				or !$value->isa('Zuzu::Value::Object')
				or !$value->can('demolish_hook');
			my $addr = refaddr($value);
			next if !$addr;
			next if $seen{$addr}++;
			my $hook = $value->demolish_hook;
			next if ref($hook) ne 'CODE';
			$value->demolish_hook(undef);
			local $@;
			eval { $hook->($value); 1 };
		}
	}

	return;
}

sub cancel {
	my ( $self, $reason ) = @_;

	return $self
		if $self->is_done;

	my $needs_coro_unwind = (
		$self->status eq 'running'
		and defined $self->coro
	) ? 1 : 0;
	if ( $self->status eq 'running' ) {
		if ( defined $self->pid ) {
			kill 'TERM', -$self->pid;
			kill 'TERM', $self->pid;
		}
		waitpid( $self->pid, 0 ) if defined $self->pid;
		close $self->reader if $self->reader;
		if ( defined $self->coro and $self->coro->can('throw') ) {
			$self->coro->throw( defined $reason ? $reason : 'Task cancelled' );
		}
	}
	$self->cancel_reason($reason) if defined $reason;
	$self->error( defined $reason ? $reason : 'Task cancelled' );
	my $on_cancel = $self->on_cancel;
	$on_cancel->($self) if defined $on_cancel;
	$self->status('cancelled');
	$self->_run_cancel_cleanup if $needs_coro_unwind;
	$self->scheduler->trace_task( cancel => $self )
		if defined $self->scheduler
		and $self->scheduler->can('trace_task');
	$self->_cleanup_if_done if !$needs_coro_unwind;

	return $self;
}

sub await {
	my ( $self ) = @_;

	if (
		defined $self->scheduler
		and !$self->is_done
		and defined $self->scheduler->current_task
		and $self->status ne 'running'
	) {
		$self->scheduler->await_from_current_task($self);
	}
	elsif (
		defined $self->scheduler
		and !$self->is_done
		and defined $self->scheduler->current_task
		and $self->status eq 'running'
		and defined $self->pid
	) {
		while ( !$self->is_done ) {
			$self->poll;
			$self->scheduler->yield_current_task
				if !$self->is_done
				and $self->scheduler->can('yield_current_task');
		}
	}
	elsif (
		defined $self->scheduler
		and !$self->is_done
		and $self->status ne 'running'
	) {
		$self->scheduler->run_until($self);
	}
	elsif ( $self->status eq 'running' and defined $self->pid ) {
		$self->_finish_running(0);
	}
	elsif ( $self->status eq 'sleeping' ) {
		sleep(0.001) while !$self->poll;
	}
	elsif ( $self->status eq 'waiting' ) {
		sleep(0.001) while !$self->poll;
	}
	elsif ( $self->status eq 'pending' ) {
		$self->_run_pending;
	}

	die $self->error if $self->status eq 'rejected';
	die $self->error if $self->status eq 'cancelled';
	return $self->result;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Task >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

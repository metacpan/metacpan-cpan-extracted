package Zuzu::Runtime::Async::Scheduler;

use utf8;

our $VERSION = '0.002000';

use Moo;
use Coro qw( async cede );
use Scalar::Util qw( refaddr weaken );
use Time::HiRes qw( sleep );

use Zuzu::Runtime::Async::TaskGroup;

has 'runtime' => ( is => 'rw' );
has 'tasks' => ( is => 'rw', default => sub { {} } );
has 'root_group' => (
	is => 'rw',
	default => sub { Zuzu::Runtime::Async::TaskGroup->new },
);
has 'current_task' => ( is => 'rw' );
has 'current_group' => ( is => 'rw' );
has 'next_task_id' => ( is => 'rw', default => sub { 1 } );
has 'trace_events' => ( is => 'rw', default => sub { [] } );

sub BUILD {
	my ( $self ) = @_;

	weaken( $self->{runtime} ) if defined $self->{runtime};
	$self->current_group( $self->root_group );
}

sub new_group {
	my ( $self, $parent ) = @_;

	return Zuzu::Runtime::Async::TaskGroup->new(
		parent => $parent // $self->current_group // $self->root_group,
	);
}

sub debug_enabled {
	no warnings 'once';

	return $Zuzu::Runtime::DEBUG_LEVEL > 0 ? 1 : 0;
}

sub trace_task {
	my ( $self, $event, $task, $extra ) = @_;

	return if !$self->debug_enabled;
	my $record = {
		event => $event,
		task_id => defined $task && $task->can('id') ? $task->id : undef,
		parent_task_id => defined $task && $task->can('parent_id')
			? $task->parent_id
			: undef,
		name => defined $task && $task->can('name') ? $task->name : undef,
		status => defined $task && $task->can('status') ? $task->status : undef,
		file => defined $task && $task->can('file') ? $task->file : undef,
		line => defined $task && $task->can('line') ? $task->line : undef,
	};
	if ( defined $extra ) {
		$record->{$_} = $extra->{$_} for keys %$extra;
	}
	push @{ $self->trace_events }, $record;

	return $record;
}

sub clear_trace {
	my ( $self ) = @_;

	$self->trace_events( [] );

	return;
}

sub schedule {
	my ( $self, $task, $group ) = @_;

	return $task if !defined $task;
	$task->scheduler($self) if $task->can('scheduler');
	$task->use_coro(1) if $task->can('use_coro');
	if ( $task->can('id') and !defined $task->id ) {
		$task->id( $self->next_task_id );
		$self->next_task_id( $self->next_task_id + 1 );
	}
	if (
		$task->can('parent_id')
		and !defined $task->parent_id
		and defined $self->current_task
		and $self->current_task->can('id')
	) {
		$task->parent_id( $self->current_task->id );
	}
	$group //= $self->current_group // $self->root_group;
	$group->add($task) if $group;
	$self->tasks->{ refaddr($task) } = $task;
	$self->trace_task( schedule => $task );

	return $task;
}

sub ensure_scheduled {
	my ( $self, $task ) = @_;

	return $task if !defined $task;
	return $self->schedule($task)
		if !exists $self->tasks->{ refaddr($task) };
	$task->scheduler($self) if $task->can('scheduler') and !$task->scheduler;
	$task->use_coro(1) if $task->can('use_coro');

	return $task;
}

sub _task_done {
	my ( $task ) = @_;

	return 1
		if $task->status eq 'fulfilled'
		or $task->status eq 'rejected'
		or $task->status eq 'cancelled';
	return 0;
}

sub cleanup_task {
	my ( $self, $task ) = @_;

	return if !defined $task;
	return if !_task_done($task);
	delete $self->tasks->{ refaddr($task) };
	if ( $task->can('group') and defined $task->group ) {
		$task->group->remove($task);
	}
	$self->trace_task( cleanup => $task );

	return;
}

sub cleanup_done {
	my ( $self ) = @_;

	for my $task ( values %{ $self->tasks } ) {
		$self->cleanup_task($task);
	}

	return;
}

sub active_count {
	my ( $self ) = @_;

	$self->cleanup_done;
	return scalar keys %{ $self->tasks };
}

sub shutdown {
	my ( $self, $reason ) = @_;

	for my $task ( values %{ $self->tasks } ) {
		next if !defined $task;
		$task->cancel($reason)
			if $task->can('cancel') and !_task_done($task);
	}
	$self->cleanup_done;
	$self->current_task(undef);
	$self->current_group( $self->root_group );
	$self->trace_task( shutdown => undef );

	return;
}

sub run_until {
	my ( $self, $target ) = @_;

	$self->ensure_scheduled($target) if $target->can('scheduler');
	while ( !_task_done($target) ) {
		my $progress = $self->progress_once($target);
		cede;
		sleep(0.001) if !$progress and !_task_done($target);
	}
	$self->cleanup_task($target);

	return $target;
}

sub progress_once {
	my ( $self, $target ) = @_;

	my @tasks = values %{ $self->tasks };
	push @tasks, $target
		if defined $target
		and !exists $self->tasks->{ refaddr($target) };

	my $progress = 0;
	for my $task ( @tasks ) {
		next if !defined $task;
		my $before = $task->status;
		if ( $task->status eq 'pending' ) {
			if ( $task->can('use_coro') and $task->use_coro ) {
				$self->start_coro_task($task);
			}
			else {
				$self->run_pending_task($task);
			}
			$progress = 1;
		}
		else {
			$progress = 1 if $task->poll;
		}
		$progress = 1 if $task->status ne $before;
		$self->cleanup_task($task);
	}

	return $progress;
}

sub _save_task_runtime_stack {
	my ( $self, $task ) = @_;

	my $runtime = $self->runtime;
	return if !defined $runtime or !defined $task;
	$task->runtime_stack( [ @{ $runtime->{_stack} // [] } ] )
		if $task->can('runtime_stack');

	return;
}

sub _restore_task_runtime_stack {
	my ( $self, $task ) = @_;

	my $runtime = $self->runtime;
	return if !defined $runtime or !defined $task;
	return if !$task->can('runtime_stack') or !defined $task->runtime_stack;
	$runtime->{_stack} = [ @{ $task->runtime_stack } ];

	return;
}

sub _throw_if_task_cancelled {
	my ( $self, $task ) = @_;

	return if !defined $task;
	return if !$task->can('status') or $task->status ne 'cancelled';
	die $task->error;
}

sub run_pending_task {
	my ( $self, $task ) = @_;

	my $prior_task = $self->current_task;
	my $prior_group = $self->current_group;
	my $runtime = $self->runtime;
	my $prior_stack = defined $runtime
		? [ @{ $runtime->{_stack} // [] } ]
		: undef;
	$self->current_task($task);
	$self->current_group( $task->group // $prior_group // $self->root_group );
	$self->_restore_task_runtime_stack($task);
	$self->trace_task( start => $task );
	my $ok = eval {
		$task->_run_pending;
		1;
	};
	my $err = $@ if !$ok;
	$self->_save_task_runtime_stack($task);
	$runtime->{_stack} = $prior_stack if defined $runtime and defined $prior_stack;
	$self->current_task($prior_task);
	$self->current_group($prior_group);
	die $err if !$ok;
	$self->trace_task( $task->status eq 'fulfilled' ? 'fulfill' : 'reject', $task )
		if _task_done($task);
	$self->cleanup_task($task);

	return $task;
}

sub start_coro_task {
	my ( $self, $task ) = @_;

	return $task if !defined $task;
	return $task if $task->is_done;
	return $task if defined $task->coro;
	my $coro = async {
		my $prior_task = $self->current_task;
		my $prior_group = $self->current_group;
		my $runtime = $self->runtime;
		my $prior_stack = defined $runtime
			? [ @{ $runtime->{_stack} // [] } ]
			: undef;
		$self->current_task($task);
		$self->current_group(
			$task->group // $prior_group // $self->root_group
		);
		$self->_restore_task_runtime_stack($task);
		$task->status('running') if $task->status eq 'pending';
		$self->trace_task( start => $task );
		my $ok = eval {
			$task->_run_body;
			1;
		};
		my $err = $@ if !$ok;
		$self->_save_task_runtime_stack($task);
		$runtime->{_stack} = $prior_stack
			if defined $runtime and defined $prior_stack;
		$self->current_task($prior_task);
		$self->current_group($prior_group);
		if ( !$ok ) {
			$task->error($err);
			$task->status('rejected');
		}
		$self->trace_task(
			$task->status eq 'fulfilled' ? 'fulfill' : 'reject',
			$task,
		) if _task_done($task);
		$self->cleanup_task($task);
	};
	$task->coro($coro);

	return $task;
}

sub yield_current_task {
	my ( $self ) = @_;

	my $current = $self->current_task;
	my $group = $self->current_group;
	$self->_save_task_runtime_stack($current);
	cede;
	$self->current_task($current);
	$self->current_group($group);
	$self->_restore_task_runtime_stack($current);
	$self->_throw_if_task_cancelled($current);

	return;
}

sub await_from_current_task {
	my ( $self, $target ) = @_;

	$self->ensure_scheduled($target) if $target->can('scheduler');
	my $current = $self->current_task;
	while ( !_task_done($target) ) {
		if ( $target->status eq 'pending' ) {
			if ( $target->can('use_coro') and $target->use_coro ) {
				$self->start_coro_task($target);
			}
			else {
				$self->run_pending_task($target);
			}
		}
		else {
			$target->poll;
		}
		if ( !_task_done($target) ) {
			$self->yield_current_task;
		}
	}
	$self->cleanup_task($target);

	return $target;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Runtime::Async::Scheduler >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

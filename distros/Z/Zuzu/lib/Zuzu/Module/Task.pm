package Zuzu::Module::Task;

use utf8;

our $VERSION = '0.004000';

use Coro qw( cede );
use Time::HiRes qw( time );
use Scalar::Util qw( blessed );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
);
use Zuzu::Value::Array;
use Zuzu::Value::Boolean;
use Zuzu::Value::Task;

sub _yield_task {
	my ( $runtime ) = @_;

	if (
		defined $runtime->{_scheduler}
		and $runtime->{_scheduler}->can('yield_current_task')
	) {
		$runtime->{_scheduler}->yield_current_task;
	}
	else {
		cede;
	}

	return;
}

sub _task_items {
	my ( $value, $file, $line ) = @_;

	return @{ $value->items }
		if ref($value) and eval { $value->isa('Zuzu::Value::Array') };

	die Zuzu::Error->new_runtime(
		message => 'TypeException: task combinator expects Array',
		file => $file,
		line => $line,
	);
}

sub _runtime_error {
	my ( $message ) = @_;

	return Zuzu::Error->new_runtime(
		message => $message,
		file => '<std/task>',
		line => 0,
	);
}

sub _task_exception {
	my ( $runtime, $class_name, $message ) = @_;

	return $runtime->_task_exception(
		$class_name,
		$message,
		'<std/task>',
		0,
	);
}

sub _cancel_reason {
	my ( $runtime, $reason ) = @_;

	return $reason
		if blessed($reason) and eval { $reason->isa('Zuzu::Value::Object') };
	return _task_exception(
		$runtime,
		'CancelledException',
		defined $reason ? "$reason" : 'Task cancelled',
	);
}

sub _task_is_done {
	my ( $task ) = @_;

	return (
		$task->status eq 'fulfilled'
		or $task->status eq 'rejected'
		or $task->status eq 'cancelled'
	) ? 1 : 0;
}

sub _cancel_unfinished {
	my ( $tasks, $winner, $reason ) = @_;

	for my $task ( @$tasks ) {
		next if defined $winner and $task == $winner;
		$task->cancel($reason) if !_task_is_done($task);
	}
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $task_class = $runtime->{_builtin_classes}{Task}
		// native_class( name => 'Task' );
	my $channel_class = native_class( name => 'Channel' );
	my $token_class = native_class( name => 'CancellationToken' );
	my $source_class = native_class( name => 'CancellationSource' );

	$channel_class->native_constructor( sub {
		my ( $rt, $klass ) = @_;
		return native_object(
			class => $klass,
			slots => {
				queue => [],
				closed => 0,
			},
			const => {
				queue => 1,
				closed => 0,
			},
		);
	} );

	$source_class->native_constructor( sub {
		my ( $rt, $klass ) = @_;
		my $token = native_object(
			class => $token_class,
			slots => {
				cancelled => 0,
				reason => undef,
				tasks => [],
			},
			const => {
				cancelled => 0,
				reason => 0,
				tasks => 0,
			},
		);
		return native_object(
			class => $klass,
			slots => {
				token => $token,
			},
			const => {
				token => 1,
			},
		);
	} );

	$task_class->methods->{status} = native_function(
		name => 'status',
		native => sub {
			my ( $self ) = @_;
			return $self->status;
		},
	);

	$task_class->methods->{is_done} = native_function(
		name => 'is_done',
		native => sub {
			my ( $self ) = @_;
			return Zuzu::Value::Boolean->new(
				value => _task_is_done($self),
			);
		},
	);

	$task_class->methods->{done} = native_function(
		name => 'done',
		native => sub {
			my ( $self ) = @_;
			return Zuzu::Value::Boolean->new(
				value => _task_is_done($self),
			);
		},
	);

	$task_class->methods->{poll} = native_function(
		name => 'poll',
		native => sub {
			my ( $self ) = @_;
			return Zuzu::Value::Boolean->new(
				value => $self->poll ? 1 : 0,
			);
		},
	);

	$task_class->methods->{cancel} = native_function(
		name => 'cancel',
		native => sub {
			my ( $self, $reason ) = @_;
			$self->cancel( _cancel_reason( $runtime, $reason ) );
			return $self;
		},
	);

	$channel_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $value ) = @_;
			if ( $self->slots->{closed} ) {
				return $runtime->_new_task(
					name => 'channel.send',
					status => 'rejected',
					error => _task_exception(
						$runtime,
						'ChannelClosedException',
						'send on closed channel',
					),
				);
			}
			push @{ $self->slots->{queue} }, $value;
			return $runtime->_new_task(
				name => 'channel.send',
				status => 'fulfilled',
				result => $value,
			);
		},
	);

	$channel_class->methods->{recv} = native_function(
		name => 'recv',
		native => sub {
			my ( $self ) = @_;
			return $runtime->_new_task(
				name => 'channel.recv',
				status => 'waiting',
				poll_cb => sub {
					if ( @{ $self->slots->{queue} } ) {
						my $value = shift @{ $self->slots->{queue} };
						return ( 1, 1, $value );
					}
					return ( 1, 1, undef ) if $self->slots->{closed};
					return ( 0, 1, undef );
				},
			);
		},
	);

	$channel_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{closed} = 1;
			return undef;
		},
	);

	$token_class->methods->{cancelled} = native_function(
		name => 'cancelled',
		native => sub {
			my ( $self ) = @_;
			return Zuzu::Value::Boolean->new(
				value => $self->slots->{cancelled} ? 1 : 0,
			);
		},
	);

	$token_class->methods->{reason} = native_function(
		name => 'reason',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{reason};
		},
	);

	$token_class->methods->{throw_if_cancelled} = native_function(
		name => 'throw_if_cancelled',
		native => sub {
			my ( $self ) = @_;
			return undef if !$self->slots->{cancelled};
			die $self->slots->{reason}
				// _task_exception(
					$runtime,
					'CancelledException',
					'Task cancelled',
				);
		},
	);

	$token_class->methods->{watch} = native_function(
		name => 'watch',
		native => sub {
			my ( $self, $task ) = @_;
			die _runtime_error('CancellationToken.watch expects a Task')
				if !blessed($task)
				or !$task->isa('Zuzu::Value::Task');
			if ( $self->slots->{cancelled} ) {
				$task->cancel( $self->slots->{reason} );
			}
			else {
				push @{ $self->slots->{tasks} }, $task;
			}
			return $task;
		},
	);

	$source_class->methods->{token} = native_function(
		name => 'token',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{token};
		},
	);

	$source_class->methods->{cancel} = native_function(
		name => 'cancel',
		native => sub {
			my ( $self, $reason ) = @_;
			my $token = $self->slots->{token};
			return $self if $token->slots->{cancelled};
			my $cancel_reason = _cancel_reason( $runtime, $reason );
			$token->slots->{cancelled} = 1;
			$token->slots->{reason} = $cancel_reason;
			for my $task ( @{ $token->slots->{tasks} } ) {
				$task->cancel($cancel_reason)
					if blessed($task)
					and $task->isa('Zuzu::Value::Task')
					and !_task_is_done($task);
			}
			$token->slots->{tasks} = [];
			return $self;
		},
	);

	$source_class->methods->{cancelled} = native_function(
		name => 'cancelled',
		native => sub {
			my ( $self ) = @_;
			return $token_class->methods->{cancelled}{_native}->(
				$self->slots->{token},
			);
		},
	);

	$source_class->methods->{reason} = native_function(
		name => 'reason',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{token}->slots->{reason};
		},
	);

	return {
		Task => $task_class,
		Channel => $channel_class,
		CancellationToken => $token_class,
		CancellationSource => $source_class,
		resolved => native_function(
			name => 'resolved',
			native => sub {
				my ( $value ) = @_;
				return $runtime->_new_task(
					name => 'resolved',
					status => 'fulfilled',
					result => $value,
				);
			},
		),
		failed => native_function(
			name => 'failed',
			native => sub {
				my ( $message ) = @_;
				return $runtime->_new_task(
					name => 'failed',
					status => 'rejected',
					error => _task_exception(
						$runtime,
						'Exception',
						defined $message ? "$message" : 'Task failed',
					),
				);
			},
		),
		sleep => native_function(
			name => 'sleep',
			native => sub {
				my ( $seconds ) = @_;
				$seconds = 0 + ( defined $seconds ? $seconds : 0 );
				return $runtime->_new_task(
					name => 'sleep',
					status => 'sleeping',
					ready_at => time + ( $seconds > 0 ? $seconds : 0 ),
				);
			},
		),
		yield => native_function(
			name => 'yield',
			native => sub {
				return $runtime->_new_task(
					name => 'yield',
					schedule => 1,
					thunk => sub {
						_yield_task($runtime);
						return undef;
					},
				);
			},
		),
		all => native_function(
			name => 'all',
			native => sub {
				my ( $tasks ) = @_;
				my @tasks = _task_items( $tasks, '<std/task>', 0 );
				for my $task ( @tasks ) {
					die _runtime_error('all expects only Task values')
						if !blessed($task)
						or !$task->isa('Zuzu::Value::Task');
				}
				my @values;
				return $runtime->_new_task(
					name => 'all',
					schedule => 1,
					on_cancel => sub {
						my ( $task ) = @_;
						_cancel_unfinished( \@tasks, undef, $task->error );
					},
					thunk => sub {
						while (1) {
							for my $i ( 0 .. $#tasks ) {
								next if exists $values[$i];
								my $task = $tasks[$i];
								next if !$task->poll;
								my $value;
								my $ok = eval {
									$value = $task->await;
									1;
								};
								if ( !$ok ) {
									_cancel_unfinished( \@tasks, $task );
									die $@;
								}
								$values[$i] = $value;
							}
							last
								if !grep { !exists $values[$_] } 0 .. $#tasks;
							_yield_task($runtime);
						}
						return Zuzu::Value::Array->new( items => \@values );
					},
				);
			},
		),
		race => native_function(
			name => 'race',
			native => sub {
				my ( $tasks ) = @_;
				my @tasks = _task_items( $tasks, '<std/task>', 0 );
				die _runtime_error('race expects at least one task')
					if !@tasks;
				for my $task ( @tasks ) {
					die _runtime_error('race expects only Task values')
						if !blessed($task)
						or !$task->isa('Zuzu::Value::Task');
				}
				return $runtime->_new_task(
					name => 'race',
					schedule => 1,
					on_cancel => sub {
						my ( $task ) = @_;
						_cancel_unfinished( \@tasks, undef, $task->error );
					},
					thunk => sub {
						while (1) {
							for my $task ( @tasks ) {
								next if !$task->poll;
								_cancel_unfinished(
									\@tasks,
									$task,
									_task_exception(
										$runtime,
										'CancelledException',
										'race loser cancelled',
									),
								);
								return $task->await;
							}
							_yield_task($runtime);
						}
					},
				);
			},
		),
		timeout => native_function(
			name => 'timeout',
			native => sub {
				my ( $seconds, $task ) = @_;
				$seconds = 0 + ( defined $seconds ? $seconds : 0 );
				die _runtime_error('timeout expects a Task')
					if !blessed($task)
					or !$task->isa('Zuzu::Value::Task');
				my $deadline = time + ( $seconds > 0 ? $seconds : 0 );
				return $runtime->_new_task(
					name => 'timeout',
					status => 'waiting',
					poll_cb => sub {
						if ( $task->poll ) {
							my $value;
							my $ok = eval {
								$value = $task->await;
								1;
							};
							return ( 1, 1, $value ) if $ok;
							return ( 1, 0, $@ );
						}
						if ( time >= $deadline ) {
							my $timeout = _task_exception(
								$runtime,
								'TimeoutException',
								"timeout after ${seconds}s",
							);
							$task->cancel($timeout);
							return (
								1,
								0,
								$timeout,
							);
						}
						return ( 0, 1, undef );
					},
				);
			},
		),
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Task >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

package Zuzu::Module::Worker;

use utf8;

our $VERSION = '0.001002';

use POSIX ();
use IO::Select;
use Scalar::Util qw( blessed );
use Storable qw( fd_retrieve freeze nstore_fd thaw );

use Zuzu::Error;
use Zuzu::Module::Marshal;
use Zuzu::Runtime;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
);
use Zuzu::Value::Array;
use Zuzu::Value::Boolean;
use Zuzu::Value::Function;
use Zuzu::Value::Task;

my @DENIAL_CAPABILITIES = qw(
	fs
	net
	perl
	js
	proc
	db
	clib
	gui
	worker
);
my %DENIAL_CAPABILITY = map { $_ => 1 } @DENIAL_CAPABILITIES;

sub _runtime_error {
	my ( $message ) = @_;

	return Zuzu::Error->new_runtime(
		message => $message,
		file => '<std/worker>',
		line => 0,
	);
}

sub _throw_exception {
	my ( $runtime, $message ) = @_;

	die $runtime->_task_exception(
		'Exception',
		$message,
		'<std/worker>',
		0,
	);
}

sub _task_exception {
	my ( $runtime, $class_name, $message ) = @_;

	return $runtime->_task_exception(
		$class_name,
		$message,
		'<std/worker>',
		0,
	);
}

sub _fulfilled_task {
	my ( $runtime, $name, $value ) = @_;

	return $runtime->_new_task(
		name => $name,
		status => 'fulfilled',
		result => $value,
	);
}

sub _rejected_task {
	my ( $runtime, $name, $class_name, $message ) = @_;

	return $runtime->_new_task(
		name => $name,
		status => 'rejected',
		error => _task_exception( $runtime, $class_name, $message ),
	);
}

sub _throw_marshalling_exception {
	my ( $runtime, $message ) = @_;

	my $class;
	eval {
		my $env = $runtime->_load_module( 'std/marshal', '<std/worker>', 0 );
		my $ref = $env->find_ref('MarshallingException');
		$class = $$ref if $ref;
		1;
	};
	$class //= $runtime->{_builtin_classes}{Exception};

	die {
		_zuzu_throw => 1,
		value => $runtime->_instantiate_builtin_object(
			$class,
			{
				message => $message,
				file => '<std/worker>',
				line => 0,
			},
		),
	};
}

sub _normalise_native_args {
	my ( @args ) = @_;

	my $named = {};
	my $named_pairs = [];
	if (
		@args >= 2
		and ref( $args[-2] ) eq 'HASH'
		and ref( $args[-1] ) eq 'ARRAY'
	) {
		$named_pairs = pop @args;
		$named = pop @args;
	}
	shift @args
		if @args
		and blessed( $args[0] )
		and $args[0]->isa('Zuzu::Value::Class')
		and ( $args[0]->name // '' ) eq 'Worker';

	return ( \@args, $named, $named_pairs );
}

sub _parse_worker_options {
	my ( $runtime, $named ) = @_;

	my @extra_denials;
	for my $key ( sort CORE::keys %{ $named // {} } ) {
		my ($capability) = $key =~ /\Adeny_(.+)\z/;
		if ( !defined $capability or !$DENIAL_CAPABILITY{$capability} ) {
			die _runtime_error("Unknown named argument '$key' for Worker.spawn");
		}

		my $value = $named->{$key};
		if (
			!blessed($value)
			or !$value->isa('Zuzu::Value::Boolean')
		) {
			my $type = $runtime->_type_name($value);
			die _runtime_error(
				"TypeException: Worker.spawn named argument '$key' "
					. "expects Boolean, got $type",
			);
		}

		push @extra_denials, $capability if $value->value;
	}

	return @extra_denials;
}

sub _effective_denials {
	my ( $runtime, @extra_denials ) = @_;

	my %deny = map { $_ => 1 } grep {
		$runtime->is_denied($_)
	} @DENIAL_CAPABILITIES;
	$deny{$_} = 1 for @extra_denials;

	return sort CORE::keys %deny;
}

sub _worker_runtime {
	my ( $parent, $denials ) = @_;

	return Zuzu::Runtime->new(
		lib => [ @{ $parent->lib // [] } ],
		builtin => { %{ $parent->builtin // {} } },
		deny => [ @{ $denials // [] } ],
		deny_modules => [ @{ $parent->deny_modules // [] } ],
		forbid => [ @{ $parent->forbid // [] } ],
	);
}

sub _error_text {
	my ( $runtime, $error ) = @_;

	if ( ref($error) eq 'HASH' and $error->{_zuzu_throw} ) {
		my $value = $error->{value};
		my $text = eval { $runtime->_to_String($value) };
		return $text if defined $text and $text ne '';
	}
	if ( blessed($error) and $error->isa('Zuzu::Error') ) {
		return $error->message // "$error";
	}

	return defined $error ? "$error" : 'worker failed';
}

sub _call_worker_callable {
	my ( $runtime, $callable, $arguments ) = @_;

	if ( $callable->{_bound_self} ) {
		return $runtime->_call_method(
			$callable,
			$callable->{_bound_self},
			$arguments,
			{},
			[],
			'<std/worker>',
			0,
		);
	}

	return $runtime->_call_function(
		$callable,
		$arguments,
		{},
		[],
		'<std/worker>',
		0,
	);
}

sub _worker_child_reply {
	my ( $parent_runtime, $request_bytes, $denials ) = @_;

	my $child_runtime = _worker_runtime( $parent_runtime, $denials );
	my $reply;
	my $ok = eval {
		my $request = Zuzu::Module::Marshal::load_value(
			$child_runtime,
			$request_bytes,
		);
		if (
			!blessed($request)
			or !$request->isa('Zuzu::Value::Array')
		) {
			die "Worker.spawn payload did not decode as Array";
		}
		my @request = $request->resolved_items;
		if ( @request != 2 ) {
			die "Worker.spawn payload has invalid arity";
		}

		my ( $callable, $arguments ) = @request;
		if (
			!blessed($callable)
			or !$callable->isa('Zuzu::Value::Function')
		) {
			die "Worker.spawn payload callable did not decode as Function";
		}
		if (
			!blessed($arguments)
			or !$arguments->isa('Zuzu::Value::Array')
		) {
			die "Worker.spawn payload arguments did not decode as Array";
		}

		my @arguments = $arguments->resolved_items;
		my $result = _call_worker_callable(
			$child_runtime,
			$callable,
			\@arguments,
		);
		$result = $result->await
			if blessed($result) and $result->isa('Zuzu::Value::Task');
		$reply = {
			ok => 1,
			bytes => Zuzu::Module::Marshal::dump_value(
				$child_runtime,
				$result,
			),
		};
		1;
	};
	if ( !$ok ) {
		$reply = {
			ok => 0,
			error_string => _error_text( $child_runtime, $@ ),
		};
	}

	return $reply;
}

sub _write_reply {
	my ( $writer, $reply ) = @_;

	my $stored = eval {
		$writer->autoflush(1) if $writer and $writer->can('autoflush');
		nstore_fd( { ok => 1, value => $reply }, $writer );
		1;
	};
	if ( !$stored ) {
		my $fallback = {
			ok => 0,
			error_string => "Worker result could not be serialized: $@",
		};
		eval { nstore_fd( $fallback, $writer ); 1 };
	}

	return;
}

sub _start_worker_process {
	my ( $runtime, $request_bytes, $denials ) = @_;

	$runtime->assert_capability(
		'worker',
		'Worker.spawn is denied by runtime policy',
		'<std/worker>',
		0,
	);

	pipe( my $request_reader, my $request_writer )
		or die _runtime_error("Could not create worker request pipe: $!");
	pipe( my $result_reader, my $result_writer )
		or die _runtime_error("Could not create worker result pipe: $!");

	my $pid = fork();
	die _runtime_error("Could not fork worker: $!") if !defined $pid;

	if ( $pid == 0 ) {
		close $request_writer;
		close $result_reader;
		eval { setpgrp( 0, 0 ); 1 };
		my $request = eval { fd_retrieve($request_reader) };
		my $reply;
		if ( !$request ) {
			$reply = {
				ok => 0,
				error_string => "Worker request could not be read: $@",
			};
		}
		else {
			$reply = _worker_child_reply(
				$runtime,
				$request->{request_bytes},
				$denials,
			);
		}
		_write_reply( $result_writer, $reply );
		close $request_reader;
		close $result_writer;
		POSIX::_exit(0);
	}

	close $request_reader;
	close $result_writer;
	my $sent = eval {
		nstore_fd( { request_bytes => $request_bytes }, $request_writer );
		1;
	};
	close $request_writer;
	if ( !$sent ) {
		kill 'TERM', -$pid;
		kill 'TERM', $pid;
		waitpid( $pid, 0 );
		close $result_reader;
		die _runtime_error("Could not send worker request: $@");
	}

	return $runtime->_new_task(
		name => 'Worker.spawn.process',
		status => 'running',
		pid => $pid,
		reader => $result_reader,
		schedule => 1,
	);
}

sub _write_frame {
	my ( $writer, $frame ) = @_;

	return eval {
		$writer->autoflush(1) if $writer and $writer->can('autoflush');
		my $payload = freeze($frame);
		my $record = pack( 'N', length($payload) ) . $payload;
		my $offset = 0;
		while ( $offset < length($record) ) {
			my $written = syswrite(
				$writer,
				$record,
				length($record) - $offset,
				$offset,
			);
			die "short write to worker channel" if !defined $written;
			$offset += $written;
		}
		return 1;
	};
}

sub _read_exact {
	my ( $reader, $length ) = @_;

	my $buffer = '';
	while ( length($buffer) < $length ) {
		my $chunk = '';
		my $read = sysread(
			$reader,
			$chunk,
			$length - length($buffer),
		);
		die "worker channel closed" if !defined $read or $read == 0;
		$buffer .= $chunk;
	}

	return $buffer;
}

sub _read_frame {
	my ( $reader ) = @_;

	my $frame = eval {
		my $header = _read_exact( $reader, 4 );
		my $length = unpack( 'N', $header );
		thaw( _read_exact( $reader, $length ) );
	};
	return ( 0, "Worker channel could not be read: $@" )
		if $@ or !$frame;
	return ( 1, $frame );
}

sub _frame_ready {
	my ( $reader ) = @_;

	return 0 if !$reader;
	my $select = IO::Select->new($reader);
	return $select->can_read(0) ? 1 : 0;
}

sub _build_worker_inbox_class {
	my ( $runtime ) = @_;

	my $inbox_class = native_class( name => 'WorkerInbox' );

	$inbox_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $value ) = @_;
			return _rejected_task(
				$runtime,
				'WorkerInbox.send',
				'ChannelClosedException',
				'send on closed worker inbox',
			) if $self->slots->{closed_out};

			my $bytes;
			my $ok = eval {
				$bytes = Zuzu::Module::Marshal::dump_value(
					$runtime,
					$value,
				);
				1;
			};
			return _rejected_task(
				$runtime,
				'WorkerInbox.send',
				'MarshallingException',
				"WorkerInbox.send failed to marshal value: $@",
			) if !$ok;

			if (
				!_write_frame(
					$self->slots->{writer},
					{ type => 'message', bytes => $bytes },
				)
			) {
				$self->slots->{closed_out} = 1;
				return _rejected_task(
					$runtime,
					'WorkerInbox.send',
					'ChannelClosedException',
					'worker inbox output is closed',
				);
			}

			return _fulfilled_task( $runtime, 'WorkerInbox.send', $value );
		},
	);

	$inbox_class->methods->{recv} = native_function(
		name => 'recv',
		native => sub {
			my ( $self ) = @_;
			return $runtime->_new_task(
				name => 'WorkerInbox.recv',
				status => 'waiting',
				poll_cb => sub {
					return (
						1,
						0,
						_task_exception(
							$runtime,
							'ChannelClosedException',
							'worker inbox closed',
						),
					) if $self->slots->{closed_in};
					return ( 0, 1, undef )
						if !_frame_ready( $self->slots->{reader} );

					my ( $ok, $frame ) = _read_frame( $self->slots->{reader} );
					if ( !$ok ) {
						$self->slots->{closed_in} = 1;
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'ChannelClosedException',
								$frame,
							),
						);
					}
					if ( $frame->{type} eq 'close' ) {
						$self->slots->{closed_in} = 1;
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'ChannelClosedException',
								'worker inbox closed',
							),
						);
					}
					if ( $frame->{type} eq 'cancel' ) {
						$self->slots->{closed_in} = 1;
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'CancelledException',
								$frame->{reason} // 'worker cancelled',
							),
						);
					}
					if ( $frame->{type} ne 'message' ) {
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'Exception',
								'WorkerInbox received invalid frame',
							),
						);
					}
					my $value = eval {
						Zuzu::Module::Marshal::load_value(
							$runtime,
							$frame->{bytes},
						);
					};
					return (
						1,
						0,
						_task_exception(
							$runtime,
							'Exception',
							"WorkerInbox failed to unmarshal value: $@",
						),
					) if $@;

					return ( 1, 1, $value );
				},
			);
		},
	);

	$inbox_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self ) = @_;
			return _fulfilled_task( $runtime, 'WorkerInbox.close', undef )
				if $self->slots->{closed_out};
			$self->slots->{closed_out} = 1;
			_write_frame( $self->slots->{writer}, { type => 'close' } );
			return _fulfilled_task( $runtime, 'WorkerInbox.close', undef );
		},
	);

	return $inbox_class;
}

sub _worker_child_handle_reply {
	my ( $parent_runtime, $request_bytes, $denials, $in_reader, $out_writer ) = @_;

	my $child_runtime = _worker_runtime( $parent_runtime, $denials );
	my $reply;
	my $ok = eval {
		my $request = Zuzu::Module::Marshal::load_value(
			$child_runtime,
			$request_bytes,
		);
		die "Worker.spawn_handle payload did not decode as Array"
			if !blessed($request) or !$request->isa('Zuzu::Value::Array');
		my @request = $request->resolved_items;
		die "Worker.spawn_handle payload has invalid arity" if @request != 2;

		my ( $callable, $arguments ) = @request;
		die "Worker.spawn_handle payload callable did not decode as Function"
			if !blessed($callable) or !$callable->isa('Zuzu::Value::Function');
		die "Worker.spawn_handle payload arguments did not decode as Array"
			if !blessed($arguments) or !$arguments->isa('Zuzu::Value::Array');

		my $inbox_class = _build_worker_inbox_class($child_runtime);
		my $inbox = native_object(
			class => $inbox_class,
			slots => {
				reader => $in_reader,
				writer => $out_writer,
				closed_in => 0,
				closed_out => 0,
			},
			const => {
				reader => 1,
				writer => 1,
				closed_in => 0,
				closed_out => 0,
			},
		);
		my @arguments = ( $inbox, $arguments->resolved_items );
		my $result = _call_worker_callable(
			$child_runtime,
			$callable,
			\@arguments,
		);
		$result = $result->await
			if blessed($result) and $result->isa('Zuzu::Value::Task');
		$reply = {
			ok => 1,
			bytes => Zuzu::Module::Marshal::dump_value(
				$child_runtime,
				$result,
			),
		};
		1;
	};
	if ( !$ok ) {
		$reply = {
			ok => 0,
			error_string => _error_text( $child_runtime, $@ ),
		};
	}
	_write_frame( $out_writer, { type => 'close' } );

	return $reply;
}

sub _start_worker_handle_process {
	my ( $runtime, $request_bytes, $denials ) = @_;

	$runtime->assert_capability(
		'worker',
		'Worker.spawn_handle is denied by runtime policy',
		'<std/worker>',
		0,
	);

	pipe( my $parent_reader, my $child_writer )
		or die _runtime_error("Could not create worker output pipe: $!");
	pipe( my $child_reader, my $parent_writer )
		or die _runtime_error("Could not create worker input pipe: $!");
	pipe( my $result_reader, my $result_writer )
		or die _runtime_error("Could not create worker result pipe: $!");

	my $pid = fork();
	die _runtime_error("Could not fork worker: $!") if !defined $pid;

	if ( $pid == 0 ) {
		close $parent_reader;
		close $parent_writer;
		close $result_reader;
		eval { setpgrp( 0, 0 ); 1 };
		my $reply = _worker_child_handle_reply(
			$runtime,
			$request_bytes,
			$denials,
			$child_reader,
			$child_writer,
		);
		_write_reply( $result_writer, $reply );
		close $child_reader;
		close $child_writer;
		close $result_writer;
		POSIX::_exit(0);
	}

	close $child_reader;
	close $child_writer;
	close $result_writer;

	return ( $pid, $parent_reader, $parent_writer, $result_reader );
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	$runtime->assert_capability(
		'worker',
		'std/worker is denied by runtime policy',
		'<std/worker>',
		0,
	);

	my $worker_class = native_class( name => 'Worker' );
	my $handle_class = native_class( name => 'WorkerHandle' );

	$handle_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $value ) = @_;
			return _rejected_task(
				$runtime,
				'WorkerHandle.send',
				'ChannelClosedException',
				'send on closed worker handle',
			) if $self->slots->{local_closed}
				or $self->slots->{remote_closed}
				or $self->slots->{cancelled}
				or $self->slots->{result_task}->is_done;

			my $bytes;
			my $ok = eval {
				$bytes = Zuzu::Module::Marshal::dump_value(
					$runtime,
					$value,
				);
				1;
			};
			return _rejected_task(
				$runtime,
				'WorkerHandle.send',
				'Exception',
				"WorkerHandle.send failed to marshal value: $@",
			) if !$ok;

			if (
				!_write_frame(
					$self->slots->{writer},
					{ type => 'message', bytes => $bytes },
				)
			) {
				$self->slots->{local_closed} = 1;
				return _rejected_task(
					$runtime,
					'WorkerHandle.send',
					'ChannelClosedException',
					'worker handle input is closed',
				);
			}

			return _fulfilled_task( $runtime, 'WorkerHandle.send', $value );
		},
	);

	$handle_class->methods->{recv} = native_function(
		name => 'recv',
		native => sub {
			my ( $self ) = @_;
			return $runtime->_new_task(
				name => 'WorkerHandle.recv',
				status => 'waiting',
				poll_cb => sub {
					if ( @{ $self->slots->{queue} } ) {
						return ( 1, 1, shift @{ $self->slots->{queue} } );
					}
					if ( $self->slots->{cancelled} ) {
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'CancelledException',
								'worker cancelled',
							),
						);
					}
					if ( $self->slots->{remote_closed} ) {
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'ChannelClosedException',
								'worker handle closed',
							),
						);
					}
					return ( 0, 1, undef )
						if !_frame_ready( $self->slots->{reader} );

					my ( $ok, $frame ) = _read_frame( $self->slots->{reader} );
					if ( !$ok ) {
						$self->slots->{remote_closed} = 1;
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'ChannelClosedException',
								$frame,
							),
						);
					}
					if ( $frame->{type} eq 'close' ) {
						$self->slots->{remote_closed} = 1;
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'ChannelClosedException',
								'worker handle closed',
							),
						);
					}
					if ( $frame->{type} ne 'message' ) {
						return (
							1,
							0,
							_task_exception(
								$runtime,
								'Exception',
								'WorkerHandle received invalid frame',
							),
						);
					}
					my $value = eval {
						Zuzu::Module::Marshal::load_value(
							$runtime,
							$frame->{bytes},
						);
					};
					return (
						1,
						0,
						_task_exception(
							$runtime,
							'Exception',
							"WorkerHandle failed to unmarshal value: $@",
						),
					) if $@;

					return ( 1, 1, $value );
				},
			);
		},
	);

	$handle_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self ) = @_;
			return _fulfilled_task( $runtime, 'WorkerHandle.close', undef )
				if $self->slots->{local_closed};
			$self->slots->{local_closed} = 1;
			_write_frame( $self->slots->{writer}, { type => 'close' } );
			close $self->slots->{writer} if $self->slots->{writer};
			return _fulfilled_task( $runtime, 'WorkerHandle.close', undef );
		},
	);

	$handle_class->methods->{cancel} = native_function(
		name => 'cancel',
		native => sub {
			my ( $self, $reason ) = @_;
			return $self if $self->slots->{cancelled};
			$self->slots->{cancelled} = 1;
			$self->slots->{local_closed} = 1;
			$self->slots->{remote_closed} = 1;
			_write_frame(
				$self->slots->{writer},
				{
					type => 'cancel',
					reason => defined $reason ? "$reason" : 'worker cancelled',
				},
			);
			my $pid = $self->slots->{pid};
			if ( defined $pid ) {
				kill 'TERM', -$pid;
				kill 'TERM', $pid;
			}
			my $task = $self->slots->{result_task};
			$task->cancel(
				_task_exception(
					$runtime,
					'CancelledException',
					defined $reason ? "$reason" : 'worker cancelled',
				),
			) if blessed($task) and $task->isa('Zuzu::Value::Task')
				and !$task->is_done;
			return $self;
		},
	);

	$handle_class->methods->{result} = native_function(
		name => 'result',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{result_task};
		},
	);

	$handle_class->methods->{status} = native_function(
		name => 'status',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{result_task}->status;
		},
	);

	$handle_class->methods->{done} = native_function(
		name => 'done',
		native => sub {
			my ( $self ) = @_;
			return Zuzu::Value::Boolean->new(
				value => $self->slots->{result_task}->is_done ? 1 : 0,
			);
		},
	);

	$worker_class->static_methods->{spawn} = native_function(
		name => 'spawn',
		accepts_named => 1,
		native => sub {
			my ( $args, $named ) = _normalise_native_args(@_);
			if ( @$args < 1 or @$args > 2 ) {
				die _runtime_error(
					'Worker.spawn expects Callable and optional Array arguments',
				);
			}

			my $callable = $args->[0];
			if (
				!blessed($callable)
				or !$callable->isa('Zuzu::Value::Function')
			) {
				my $type = $runtime->_type_name($callable);
				die _runtime_error(
					"TypeException: Worker.spawn expects Function, got $type",
				);
			}

			my $worker_args = $args->[1] // Zuzu::Value::Array->new;
			if (
				!blessed($worker_args)
				or !$worker_args->isa('Zuzu::Value::Array')
			) {
				my $type = $runtime->_type_name($worker_args);
				die _runtime_error(
					"TypeException: Worker.spawn expects Array arguments, got $type",
				);
			}

			my @extra_denials = _parse_worker_options( $runtime, $named );
			my @denials = _effective_denials( $runtime, @extra_denials );
			my $request = Zuzu::Value::Array->new(
				items => [ $callable, $worker_args ],
			);
			my $request_bytes;
			eval {
				$request_bytes = Zuzu::Module::Marshal::dump_value(
					$runtime,
					$request,
				);
				1;
			} or do {
				my $error = $@;
				_throw_marshalling_exception(
					$runtime,
					"Worker.spawn failed to marshal request: $error",
				);
			};
			my $process = _start_worker_process(
				$runtime,
				$request_bytes,
				\@denials,
			);

			return $runtime->_new_task(
				name => 'Worker.spawn',
				schedule => 1,
				on_cancel => sub {
					my ( $task ) = @_;
					$process->cancel( $task->error )
						if !$process->is_done;
				},
				thunk => sub {
					my $reply;
					my $ok = eval {
						$reply = $process->await;
						1;
					};
					if ( !$ok ) {
						my $message = 'Worker process failed: '
							. _error_text( $runtime, $@ );
						_throw_exception(
							$runtime,
							$message,
						);
					}
					if ( ref($reply) ne 'HASH' ) {
						_throw_exception(
							$runtime,
							'Worker process returned invalid reply',
						);
					}
					if ( !$reply->{ok} ) {
						_throw_exception(
							$runtime,
							$reply->{error_string} // 'worker failed',
						);
					}

					return Zuzu::Module::Marshal::load_value(
						$runtime,
						$reply->{bytes},
					);
				},
			);
		},
	);

	$worker_class->static_methods->{spawn_handle} = native_function(
		name => 'spawn_handle',
		accepts_named => 1,
		native => sub {
			my ( $args, $named ) = _normalise_native_args(@_);
			if ( @$args < 1 or @$args > 2 ) {
				die _runtime_error(
					'Worker.spawn_handle expects Callable and optional Array arguments',
				);
			}

			my $callable = $args->[0];
			if (
				!blessed($callable)
				or !$callable->isa('Zuzu::Value::Function')
			) {
				my $type = $runtime->_type_name($callable);
				die _runtime_error(
					"TypeException: Worker.spawn_handle expects Function, got $type",
				);
			}

			my $worker_args = $args->[1] // Zuzu::Value::Array->new;
			if (
				!blessed($worker_args)
				or !$worker_args->isa('Zuzu::Value::Array')
			) {
				my $type = $runtime->_type_name($worker_args);
				die _runtime_error(
					"TypeException: Worker.spawn_handle expects Array arguments, got $type",
				);
			}

			my @extra_denials = _parse_worker_options( $runtime, $named );
			my @denials = _effective_denials( $runtime, @extra_denials );
			my $request = Zuzu::Value::Array->new(
				items => [ $callable, $worker_args ],
			);
			my $request_bytes;
			eval {
				$request_bytes = Zuzu::Module::Marshal::dump_value(
					$runtime,
					$request,
				);
				1;
			} or do {
				my $error = $@;
				_throw_marshalling_exception(
					$runtime,
					"Worker.spawn_handle failed to marshal request: $error",
				);
			};

			my ( $pid, $reader, $writer, $result_reader )
				= _start_worker_handle_process(
					$runtime,
					$request_bytes,
					\@denials,
				);
			my $process = $runtime->_new_task(
				name => 'WorkerHandle.process',
				status => 'running',
				pid => $pid,
				reader => $result_reader,
				schedule => 1,
			);
			my $result_task = $runtime->_new_task(
				name => 'WorkerHandle.result',
				process => 1,
				on_cancel => sub {
					my ( $task ) = @_;
					$process->cancel( $task->error )
						if !$process->is_done;
				},
				thunk => sub {
					my $reply = $process->await;
					if ( ref($reply) ne 'HASH' ) {
						_throw_exception(
							$runtime,
							'Worker process returned invalid reply',
						);
					}
					if ( !$reply->{ok} ) {
						_throw_exception(
							$runtime,
							$reply->{error_string} // 'worker failed',
						);
					}

					return Zuzu::Module::Marshal::load_value(
						$runtime,
						$reply->{bytes},
					);
				},
			);

			return native_object(
				class => $handle_class,
				slots => {
					pid => $pid,
					reader => $reader,
					writer => $writer,
					queue => [],
					local_closed => 0,
					remote_closed => 0,
					cancelled => 0,
					result_task => $result_task,
				},
				const => {
					pid => 1,
					reader => 1,
					writer => 1,
					queue => 1,
					local_closed => 0,
					remote_closed => 0,
					cancelled => 0,
					result_task => 1,
				},
			);
		},
	);

	return {
		Worker => $worker_class,
		WorkerHandle => $handle_class,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Worker >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

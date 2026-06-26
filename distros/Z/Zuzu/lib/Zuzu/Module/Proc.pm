package Zuzu::Module::Proc;

use utf8;

our $VERSION = '0.007000';

use File::Temp qw( tempfile );
use IPC::Run qw( harness run timeout );
use Time::HiRes qw( sleep time );
use Cwd qw( getcwd );

use Scalar::Util qw( blessed );

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);

my %SIGNAL_PREV;
my %SIGNAL_CALLBACKS;
my %SIGNAL_CALLBACK_INSTALLED;

my $TEE_CODE = <<'PERL';
my $file = shift;
open my $fh, '>', $file or die "Could not open tee output: $!";
binmode STDIN;
binmode STDOUT;
binmode $fh;
while (1) {
	my $read = sysread STDIN, my $buffer, 8192;
	die "Could not read pipeline input: $!" if !defined $read;
	last if !$read;
	print {$fh} $buffer;
	print STDOUT $buffer;
}
PERL

sub _normalize_signal_name {
	my ( $name ) = @_;

	my $signal = defined $name ? "$name" : '';
	$signal =~ s/\A\s+//;
	$signal =~ s/\s+\z//;
	$signal =~ s/\ASIG//i;
	$signal = uc $signal;

	return $signal;
}

sub _as_command_array {
	my ( $command, $argv ) = @_;

	my @cmd;
	if ( ref($command) eq 'ARRAY' ) {
		@cmd = map { defined $_ ? "$_" : '' } @{ $command };
	}
	else {
		push @cmd, defined $command ? "$command" : '';
		if ( ref($argv) eq 'ARRAY' ) {
			push @cmd, map { defined $_ ? "$_" : '' } @{ $argv };
		}
	}

	return \@cmd;
}

sub _install_onsignal_handler {
	my ( $runtime, $signal ) = @_;

	return if $SIGNAL_CALLBACK_INSTALLED{$signal};

	$SIGNAL_PREV{$signal} = $SIG{$signal};
	$SIG{$signal} = sub {
		my $callbacks = $SIGNAL_CALLBACKS{$signal} // [];
		for my $callback ( @{ $callbacks } ) {
			next if not blessed($callback)
				or not $callback->isa( 'Zuzu::Value::Function' );
			eval {
				$runtime->_call_function( $callback, [], '<std/proc>', 0 );
				1;
			} or do {
				return;
			};
		}
		return;
	};
	$SIGNAL_CALLBACK_INSTALLED{$signal} = 1;

	return;
}

sub _result_ok {
	my ( $result ) = @_;

	return 0 if ref($result) ne 'HASH';
	return 0 if defined $result->{error} and $result->{error} ne '';
	return 0 if ( $result->{signal} // 0 ) != 0;
	return 0 if ( $result->{exit_code} // 0 ) != 0;

	return 1;
}

sub _platform_supports_true_pipeline_async {
	return 0 if $^O =~ /^(?:MSWin32|dos|os2|VMS)\z/;
	return 1;
}

sub _result_from_wait_status {
	my ( $cmd, $opts, $status, $stdout, $stderr, $error, $timed_out ) = @_;

	my $capture_stdout = zuzu_bool( $opts->{capture_stdout}, 1 );
	my $capture_stderr = zuzu_bool( $opts->{capture_stderr}, 1 );
	my $merge_stderr = zuzu_bool( $opts->{merge_stderr}, 0 );
	my $exit_code = $status >> 8;
	my $signal = $status & 127;
	my $core_dump = ( $status & 128 ) ? 1 : 0;
	if ( $timed_out ) {
		$signal = 14 if $signal == 0;
		$error = 'timeout after ' . ( 0 + ( $opts->{timeout} // 0 ) ) . 's';
	}

	my $result = {
		command => $cmd,
		exit_code => $exit_code,
		signal => $signal,
		core_dump => $core_dump,
		ok => 0,
		stdout => $capture_stdout || $merge_stderr ? $stdout : undef,
		stderr => $capture_stderr ? ( $merge_stderr ? '' : $stderr ) : undef,
		error => $error,
		timed_out => $timed_out ? 1 : 0,
	};
	$result->{ok} = _result_ok($result);

	return $result;
}

sub _timeout_result {
	my ( $cmd, $opts ) = @_;

	return _result_from_wait_status(
		$cmd,
		$opts,
		14,
		'',
		'',
		'timeout after ' . ( 0 + ( $opts->{timeout} // 0 ) ) . 's',
		1,
	);
}

sub _pipeline_result {
	my ( $steps ) = @_;

	my $failed_steps = scalar grep { !$_->{ok} } @{$steps};
	my $ok = @{$steps}
		? ( $failed_steps ? 0 : 1 )
		: 1;
	my $last = @{$steps} ? $steps->[-1] : {
		command => [],
		exit_code => 0,
		signal => 0,
		core_dump => 0,
		ok => 1,
		stdout => '',
		stderr => '',
		error => undef,
		timed_out => 0,
	};

	return {
		ok => $ok,
		stdout => $last->{stdout},
		stderr => $last->{stderr},
		error => $last->{error},
		exit_code => $last->{exit_code},
		signal => $last->{signal},
		core_dump => $last->{core_dump},
		timed_out => $last->{timed_out},
		steps => $steps,
	};
}

sub _run_command {
	my ( $cmd, $opts ) = @_;

	my $stdin = exists $opts->{stdin}
		? ( defined $opts->{stdin} ? "$opts->{stdin}" : '' )
		: '';
	my $capture_stdout = zuzu_bool( $opts->{capture_stdout}, 1 );
	my $capture_stderr = zuzu_bool( $opts->{capture_stderr}, 1 );
	my $merge_stderr = zuzu_bool( $opts->{merge_stderr}, 0 );
	my $timeout = defined $opts->{timeout} ? 0 + $opts->{timeout} : 0;

	my $stdout = '';
	my $stderr = '';
	my $out_ref = $capture_stdout ? \$stdout : undef;
	my $err_ref;
	if ( $merge_stderr ) {
		$err_ref = $out_ref;
	}
	else {
		$err_ref = $capture_stderr ? \$stderr : undef;
	}

	my $error;
	my $timed_out = 0;
	my $ran_process = 0;
	my %old_env;
	my @unset_keys;
	my $had_env = 0;
	my $old_cwd;
	my $had_cwd = 0;

	my $env = exists $opts->{env} ? $opts->{env} : undef;
	if ( ref($env) eq 'HASH' ) {
		$had_env = 1;
		for my $key ( sort CORE::keys %{ $env } ) {
			if ( exists $ENV{$key} ) {
				$old_env{$key} = $ENV{$key};
			}
			else {
				push @unset_keys, $key;
			}
			if ( defined $env->{$key} ) {
				$ENV{$key} = "$env->{$key}";
			}
			else {
				delete $ENV{$key};
			}
		}
	}

	if ( exists $opts->{cwd} and defined $opts->{cwd} ) {
		$had_cwd = 1;
		$old_cwd = getcwd();
		my $cwd = "$opts->{cwd}";
		if ( !chdir $cwd ) {
			$error = "could not change cwd to $cwd: $!";
		}
	}

	eval {
			if ( !defined $error ) {
				local $SIG{ALRM} = sub {
					$timed_out = 1;
					die "run timeout\n";
				};
				alarm $timeout if $timeout > 0;
				$ran_process = 1;
				my @run_spec = ( $cmd, '<', \$stdin );
				push @run_spec, '>', $out_ref if $capture_stdout;
				if ( $merge_stderr ) {
					push @run_spec, '2>&1';
				}
				elsif ( $capture_stderr ) {
					push @run_spec, '2>', $err_ref;
				}
				run(@run_spec);
				alarm 0 if $timeout > 0;
			}
		1;
	} or do {
		$error = "$@";
		alarm 0 if $timeout > 0;
	};

	if ( $had_cwd ) {
		chdir $old_cwd
			or do {
				my $restore_error =
					"could not restore cwd to $old_cwd: $!";
				$error = defined $error && $error ne ''
					? "$error; $restore_error"
					: $restore_error;
			};
	}

	if ( $had_env ) {
		for my $key ( sort CORE::keys %old_env ) {
			$ENV{$key} = $old_env{$key};
		}
		for my $key ( @unset_keys ) {
			delete $ENV{$key};
		}
	}

	my $status = $?;
	$status = 255 << 8
		if !$ran_process and defined $error and $error ne '';
	my $exit_code = $status >> 8;
	my $signal = $status & 127;
	my $core_dump = ( $status & 128 ) ? 1 : 0;
	if ( $timed_out ) {
		$signal = 14 if $signal == 0;
		$error = "timeout after ${timeout}s";
	}

	my $result = {
		command => $cmd,
		exit_code => $exit_code,
		signal => $signal,
		core_dump => $core_dump,
		ok => 0,
		stdout => $capture_stdout ? $stdout : undef,
		stderr => $capture_stderr ? $stderr : undef,
		error => $error,
		timed_out => $timed_out ? 1 : 0,
	};
	$result->{ok} = _result_ok($result);

	return $result;
}

sub _run_pipeline_legacy {
	my ( $items, $opts ) = @_;

	my @steps;
	my $stdin = exists $opts->{stdin} ? $opts->{stdin} : '';
	for my $command ( @{ $items } ) {
		my $cmd = _as_command_array( zuzu_to_perl($command), [] );
		my %step_opts = %{ $opts };
		$step_opts{stdin} = $stdin;
		$step_opts{capture_stdout} = 1;
		my $result = _run_command( $cmd, \%step_opts );
		push @steps, $result;
		$stdin = defined $result->{stdout} ? $result->{stdout} : '';
		last if not $result->{ok};
	}

	return _pipeline_result( \@steps );
}

sub _run_pipeline_true_async {
	my ( $items, $opts ) = @_;

	my @cmds = map { _as_command_array( zuzu_to_perl($_), [] ) } @{ $items };
	return _pipeline_result( [] ) if !@cmds;

	my $capture_stderr = zuzu_bool( $opts->{capture_stderr}, 1 );
	my $merge_stderr = zuzu_bool( $opts->{merge_stderr}, 0 );
	my $stdin = exists $opts->{stdin}
		? ( defined $opts->{stdin} ? "$opts->{stdin}" : '' )
		: '';
	my $timeout_seconds = defined $opts->{timeout} ? 0 + $opts->{timeout} : 0;
	my @stderr = map { '' } @cmds;
	my $final_stdout = '';
	my @tee_files;
	my @original_process_ix;
	my @spec;
	my $process_ix = 0;

	for my $ix ( 0 .. $#cmds ) {
		push @spec, $cmds[$ix];
		push @original_process_ix, $process_ix++;
		if ( $ix == 0 and length $stdin ) {
			push @spec, '<', \$stdin;
		}
		if ( $merge_stderr ) {
			push @spec, '2>&1';
		}
		elsif ( $capture_stderr ) {
			push @spec, '2>', \$stderr[$ix];
		}
		if ( $ix < $#cmds ) {
			my ( $fh, $path ) = tempfile(
				'zuzu-proc-pipeline-XXXXXX',
				TMPDIR => 1,
				UNLINK => 0,
			);
			close $fh;
			push @tee_files, $path;
			push @spec, '|', [ $^X, '-e', $TEE_CODE, $path ], '2>', \my $tee_err;
			$process_ix++;
			push @spec, '|';
		}
	}
	push @spec, '>', \$final_stdout;
	push @spec, timeout( $timeout_seconds, exception => 'pipeline timeout' )
		if $timeout_seconds > 0;

	my $h = harness(@spec);
	my %old_env;
	my @unset_keys;
	my $had_env = 0;
	my $old_cwd;
	my $had_cwd = 0;
	my $error;
	my $env = exists $opts->{env} ? $opts->{env} : undef;
	if ( ref($env) eq 'HASH' ) {
		$had_env = 1;
		for my $key ( sort CORE::keys %{ $env } ) {
			if ( exists $ENV{$key} ) {
				$old_env{$key} = $ENV{$key};
			}
			else {
				push @unset_keys, $key;
			}
			if ( defined $env->{$key} ) {
				$ENV{$key} = "$env->{$key}";
			}
			else {
				delete $ENV{$key};
			}
		}
	}

	if ( exists $opts->{cwd} and defined $opts->{cwd} ) {
		$had_cwd = 1;
		$old_cwd = getcwd();
		my $cwd = "$opts->{cwd}";
		if ( !chdir $cwd ) {
			$error = "could not change cwd to $cwd: $!";
		}
	}

	my $timed_out = 0;
	my $ok = eval {
		$h->run if !defined $error;
		1;
	};
	if ( $had_cwd ) {
		chdir $old_cwd
			or do {
				my $restore_error =
					"could not restore cwd to $old_cwd: $!";
				$error = defined $error && $error ne ''
					? "$error; $restore_error"
					: $restore_error;
				$ok = 0;
			};
	}
	if ( $had_env ) {
		for my $key ( sort CORE::keys %old_env ) {
			$ENV{$key} = $old_env{$key};
		}
		for my $key ( @unset_keys ) {
			delete $ENV{$key};
		}
	}
	if ( !$ok ) {
		my $eval_error = "$@";
		$error = $eval_error if $eval_error ne '';
		$timed_out = $error =~ /pipeline timeout|timed out/i ? 1 : 0;
		eval { $h->kill_kill; 1 };
	}

	my @stdout = map { '' } @cmds;
	for my $ix ( 0 .. $#tee_files ) {
		if ( open my $fh, '<', $tee_files[$ix] ) {
			local $/;
			$stdout[$ix] = <$fh>;
			close $fh;
		}
		unlink $tee_files[$ix];
	}
	$stdout[-1] = $final_stdout;

	my @steps;
	for my $ix ( 0 .. $#cmds ) {
		if ( $timed_out ) {
			push @steps, _timeout_result( $cmds[$ix], $opts );
			next;
		}
		my $status = eval {
			$h->full_result( $original_process_ix[$ix] );
		};
		$status = 1 << 8 if !defined $status;
		push @steps, _result_from_wait_status(
			$cmds[$ix],
			{
				%{ $opts },
				capture_stdout => 1,
			},
			$status,
			$stdout[$ix],
			$stderr[$ix],
			$error,
			0,
		);
	}

	return _pipeline_result( \@steps );
}

sub _async_task {
	my ( $runtime, $name, $work, $wrap ) = @_;

	my $worker = $runtime->_new_task(
		name => "$name.worker",
		start => 1,
		schedule => 1,
		thunk => $work,
	);
	return $runtime->_new_task(
		name => $name,
		schedule => 1,
		thunk => sub {
			my $value = $worker->await;
			return defined $wrap ? $wrap->($value) : $value;
		},
	);
}

sub _warn_blocking_operation {
	my ( $runtime, $operation ) = @_;

	$runtime->_warn_blocking_operation($operation)
		if $runtime->can('_warn_blocking_operation');

	return;
}

sub _pipeline_async_legacy_native {
	my ( $runtime ) = @_;

	return native_function(
		name => 'pipeline_async',
		native => sub {
			my ( $self, $commands, $options ) = @_;
			my $items = zuzu_to_perl( $commands );
			$items = [] if ref($items) ne 'ARRAY';
			my $opts = zuzu_to_perl( $options );
			$opts = {} if ref($opts) ne 'HASH';

			return _async_task(
				$runtime,
				'proc.pipeline_async',
				sub {
					return _run_pipeline_legacy( $items, $opts );
				},
				sub {
					my ( $result ) = @_;
					return perl_to_zuzu($result);
				},
			);
		},
	);
}

sub _pipeline_async_true_native {
	my ( $runtime ) = @_;

	return native_function(
		name => 'pipeline_async',
		native => sub {
			my ( $self, $commands, $options ) = @_;
			my $items = zuzu_to_perl( $commands );
			$items = [] if ref($items) ne 'ARRAY';
			my $opts = zuzu_to_perl( $options );
			$opts = {} if ref($opts) ne 'HASH';

			return _async_task(
				$runtime,
				'proc.pipeline_async',
				sub {
					return _run_pipeline_true_async( $items, $opts );
				},
				sub {
					my ( $result ) = @_;
					return perl_to_zuzu($result);
				},
			);
		},
	);
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $proc_class = native_class(
		name => 'Proc',
	);

	my $env_class = native_class(
		name => 'Env',
	);

	$proc_class->static_methods->{pid} = native_function(
		name => 'pid',
		native => sub {
			return 0 + $$;
		},
	);


	$env_class->static_methods->{get} = native_function(
		name => 'get',
		native => sub {
			my ( $self, $name, $default ) = @_;
			my $key = defined $name ? "$name" : '';
			return $ENV{$key} if exists $ENV{$key};
			return $default;
		},
	);

	$env_class->static_methods->{set} = native_function(
		name => 'set',
		native => sub {
			my ( $self, $name, $value ) = @_;
			my $key = defined $name ? "$name" : '';
			$ENV{$key} = defined $value ? "$value" : '';
			return $ENV{$key};
		},
	);

	$env_class->static_methods->{remove} = native_function(
		name => 'remove',
		native => sub {
			my ( $self, $name ) = @_;
			my $key = defined $name ? "$name" : '';
			delete $ENV{$key};
			return undef;
		},
	);

	$proc_class->static_methods->{run} = native_function(
		name => 'run',
			native => sub {
			my ( $self, $command, $argv, $options ) = @_;
			_warn_blocking_operation( $runtime, 'std/proc Proc.run' );

			my $args = zuzu_to_perl( $argv );
			$args = [] if ref($args) ne 'ARRAY';

			my $opts = zuzu_to_perl( $options );
			$opts = {} if ref($opts) ne 'HASH';

			my $cmd = _as_command_array( zuzu_to_perl($command), $args );
			my $result = _run_command( $cmd, $opts );
			return perl_to_zuzu($result);
		},
	);

	$proc_class->static_methods->{run_async} = native_function(
		name => 'run_async',
		native => sub {
			my ( $self, $command, $argv, $options ) = @_;

			my $args = zuzu_to_perl( $argv );
			$args = [] if ref($args) ne 'ARRAY';

			my $opts = zuzu_to_perl( $options );
			$opts = {} if ref($opts) ne 'HASH';

			my $cmd = _as_command_array( zuzu_to_perl($command), $args );
			return _async_task(
				$runtime,
				'proc.run_async',
				sub {
					return _run_command( $cmd, $opts );
				},
				sub {
					my ( $result ) = @_;
					return perl_to_zuzu($result);
				},
			);
		},
	);

	$proc_class->static_methods->{pipeline} = native_function(
		name => 'pipeline',
		native => sub {
			my ( $self, $commands, $options ) = @_;
			_warn_blocking_operation( $runtime, 'std/proc Proc.pipeline' );
			my $items = zuzu_to_perl( $commands );
			$items = [] if ref($items) ne 'ARRAY';
			my $opts = zuzu_to_perl( $options );
			$opts = {} if ref($opts) ne 'HASH';

			return perl_to_zuzu( _run_pipeline_legacy( $items, $opts ) );
		},
	);

	$proc_class->static_methods->{pipeline_async} =
		_platform_supports_true_pipeline_async()
			? _pipeline_async_true_native($runtime)
			: _pipeline_async_legacy_native($runtime);

	$proc_class->static_methods->{is_success} = native_function(
		name => 'is_success',
		native => sub {
			my ( $self, $result ) = @_;
			my $perl = zuzu_to_perl($result);
			return _result_ok($perl) ? 1 : 0;
		},
	);

	$proc_class->static_methods->{status_text} = native_function(
		name => 'status_text',
		native => sub {
			my ( $self, $result ) = @_;
			my $perl = zuzu_to_perl($result);
			return 'invalid result' if ref($perl) ne 'HASH';
			if ( defined $perl->{error} and $perl->{error} ne '' ) {
				return "error: $perl->{error}";
			}
			if ( ( $perl->{signal} // 0 ) != 0 ) {
				return "signal $perl->{signal}";
			}
			return "exit $perl->{exit_code}";
		},
	);

	$proc_class->static_methods->{kill} = native_function(
		name => 'kill',
		native => sub {
			my ( $self, $signal_name, $pid ) = @_;
			my $signal = _normalize_signal_name( $signal_name );
			my $target = defined $pid ? 0 + $pid : 0 + $$;
			my $count = CORE::kill( $signal, $target );
			return $count;
		},
	);

	$proc_class->static_methods->{onsignal} = native_function(
		name => 'onsignal',
		native => sub {
			my ( $self, $signal_name, $callback ) = @_;
			my $signal = _normalize_signal_name( $signal_name );
			$SIGNAL_CALLBACKS{$signal} = []
				if not exists $SIGNAL_CALLBACKS{$signal};
			push @{ $SIGNAL_CALLBACKS{$signal} }, $callback;
			_install_onsignal_handler( $runtime, $signal );
			return scalar @{ $SIGNAL_CALLBACKS{$signal} };
		},
	);

	$proc_class->static_methods->{exit} = native_function(
		name => 'exit',
		native => sub {
			my ( $self, $code ) = @_;
			my $exit_code = defined $code ? 0 + $code : 0;
			CORE::exit( $exit_code );
		},
	);

	my $sleep_fn = native_function(
		name => 'sleep',
		native => sub {
			my ( $seconds ) = @_;
			_warn_blocking_operation( $runtime, 'std/proc sleep' );
			my $duration = defined $seconds ? 0 + $seconds : 0;
			$duration = 0 if $duration < 0;
			sleep($duration);
			return undef;
		},
	);

	my $sleep_async_fn = native_function(
		name => 'sleep_async',
		native => sub {
			my ( $seconds ) = @_;
			my $duration = defined $seconds ? 0 + $seconds : 0;
			$duration = 0 if $duration < 0;
			return $runtime->_new_task(
				name => 'proc.sleep_async',
				status => 'sleeping',
				ready_at => time + $duration,
			);
		},
	);

	return {
		Proc => $proc_class,
		Env => $env_class,
		sleep => $sleep_fn,
		sleep_async => $sleep_async_fn,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Proc - std/proc bindings for ZuzuScript.

=head1 DESCRIPTION

Implements C<std/proc>, exporting C<Proc>, C<Env>, and C<sleep>.

=head1 CLASSES

=head2 Env

Static helpers for reading and mutating process environment
variables.

=over

=item * C<get(name, default?)>

Reads an environment variable. Returns C<default> (or null) when
not set.

=item * C<set(name, value)>

Sets an environment variable and returns the new value.

=item * C<remove(name)>

Unsets an environment variable.

=back

=head2 Proc

Static helpers for interacting with operating-system processes.

=over

=item * C<pid>

Returns the current process ID.


=item * C<run(command, argv?, options?)>

Runs an external process with C<IPC::Run>. Returns a Dict with
C<command>, C<exit_code>, C<signal>, C<core_dump>, C<ok>,
C<stdout>, C<stderr>, and C<error>.

C<command> may be a string or an array-style command. C<argv>
provides additional arguments when C<command> is a string.

Options currently supported:

=over

=item * C<stdin>

=item * C<capture_stdout> (default true)

=item * C<capture_stderr> (default true)

=item * C<merge_stderr> (default false)

=item * C<cwd>

=back

=item * C<kill(signal, pid?)>

Sends a signal. PID defaults to the current process.

=item * C<onsignal(signal, callback)>

Registers a callback function to run when that signal is received.

=item * C<exit(code)>

Immediately exits the current process with the provided status code.

=back

=head2 sleep

Function:

=over

=item * C<sleep(seconds)>

Blocks the current process for the requested number of seconds. Fractional
seconds are supported.

=back

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Proc >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

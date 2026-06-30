package Zuzu::Module::IO;

use utf8;

our $VERSION = '0.007001';

use Encode qw( decode_utf8 );
use Errno qw( EEXIST );
use File::Glob qw( bsd_glob GLOB_NOCHECK GLOB_QUOTE GLOB_BRACE GLOB_TILDE GLOB_NOCASE );
use File::Spec;
use Path::Tiny qw(
	cwd
	path
	rootdir
	tempdir
	tempfile
);
use Scalar::Util qw( blessed );

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_functions
	native_object
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);
use Zuzu::Value::BinaryString;
use Zuzu::Value::Function;
use Zuzu::Error;

sub _bool {
	my ( $value ) = @_;

	return $value ? 1 : 0;
}

sub _raw_mode {
	my ( $value ) = @_;

	return zuzu_bool( $value, 0 ) ? 1 : 0;
}

sub _to_path_tiny {
	my ( $obj ) = @_;

	if (
		blessed($obj)
		and $obj->isa('Zuzu::Value::Object')
		and exists $obj->slots->{_path_tiny}
	) {
		return $obj->slots->{_path_tiny};
	}

	return path( defined $obj ? "$obj" : '' );
}

sub _has_named_temp_option {
	my ( $args, $name ) = @_;

	for ( my $i = 0; $i < @{$args} - 1; $i += 2 ) {
		next if ref $args->[$i];
		return 1 if uc( $args->[$i] ) eq $name;
	}

	return 0;
}

sub _new_path_object {
	my ( $class_obj, $path_obj, $demolish_hook ) = @_;

	my $object = native_object(
		class => $class_obj,
		slots => {
			_path_tiny => $path_obj,
			_line_cursor => undef,
			_line_done => 0,
			_line_mode => undef,
		},
		const => {
			_path_tiny => 1,
			_line_cursor => 0,
			_line_done => 0,
			_line_mode => 0,
		},
	);
	$object->demolish_hook($demolish_hook)
		if ref($demolish_hook) eq 'CODE';

	return $object;
}

sub _temp_path_cleanup {
	my ( $path_obj, $recursive ) = @_;

	return sub {
		local $@;
		eval {
			if ($recursive) {
				$path_obj->remove_tree({ safe => 0 });
			}
			else {
				$path_obj->remove;
			}
			1;
		};
		return;
	};
}

sub _new_path_array {
	my ( $class_obj, $paths ) = @_;

	my @wrapped = map {
		_new_path_object( $class_obj, $_ )
	} @{ $paths };

	return perl_to_zuzu( \@wrapped );
}

sub _stat_to_dict {
	my ( $st ) = @_;

	return undef if not defined $st;

	my %fields = (
		dev => $st->dev,
		ino => $st->ino,
		mode => $st->mode,
		nlink => $st->nlink,
		uid => $st->uid,
		gid => $st->gid,
		rdev => $st->rdev,
		size => $st->size,
		atime => $st->atime,
		mtime => $st->mtime,
		ctime => $st->ctime,
		blksize => $st->blksize,
		blocks => $st->blocks,
	);

	return perl_to_zuzu( \%fields );
}

sub _call_callback {
	my ( $runtime, $callback, $args ) = @_;

	return if not blessed($callback)
		or not $callback->isa('Zuzu::Value::Function');

	$runtime->_call_function( $callback, $args, '<std/io>', 0 );

	return;
}

sub _decode_if_utf8 {
	my ( $line, $raw ) = @_;

	return $line if $raw;
	return decode_utf8( $line, 1 );
}

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if not defined $value;
	return 'BinaryString'
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');
	return 'String';
}

sub _assert_binary_string {
	my ( $value, $label ) = @_;

	return if blessed($value) and $value->isa('Zuzu::Value::BinaryString');

	my $type = _type_name( $value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects BinaryString, got $type",
		file => '<std/io>',
		line => 0,
	);
}

sub _assert_text_string {
	my ( $value, $label ) = @_;

	return if not blessed($value);
	return if not $value->isa('Zuzu::Value::BinaryString');

	my $type = _type_name( $value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects String, got $type",
		file => '<std/io>',
		line => 0,
	);
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

sub _glob_flags_from_options {
	my ( $options ) = @_;

	return GLOB_NOCHECK | GLOB_QUOTE if ref($options) ne 'HASH';

	my $flags = GLOB_QUOTE;
	if ( zuzu_bool( $options->{nocheck}, 1 ) ) {
		$flags |= GLOB_NOCHECK;
	}
	if ( zuzu_bool( $options->{brace}, 1 ) ) {
		$flags |= GLOB_BRACE;
	}
	if ( zuzu_bool( $options->{tilde}, 1 ) ) {
		$flags |= GLOB_TILDE;
	}
	if ( zuzu_bool( $options->{nocase}, 0 ) ) {
		$flags |= GLOB_NOCASE;
	}

	return $flags;
}

sub _normalize_join_parts {
	my ( $parts ) = @_;

	my @out;
	if ( ref($parts) eq 'ARRAY' ) {
		@out = map { defined $_ ? "$_" : '' } @{ $parts };
	}
	else {
		@out = ( defined $parts ? "$parts" : '' );
	}

	return @out;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $path_class = native_class(
		name => 'Path',
	);
	my $path_iterator_class = native_class(
		name => 'PathIterator',
	);
	my $stdin_class = native_class(
		name => 'STDINHandle',
	);
	my $stdout_class = native_class(
		name => 'STDOUTHandle',
	);
	my $stderr_class = native_class(
		name => 'STDERRHandle',
	);

	$path_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my $raw = @{ $positional // [] }
			? $positional->[0]
			: exists $named->{path} ? $named->{path} : '';
		my $p = path( defined $raw ? "$raw" : '' );

		return _new_path_object( $klass, $p );
	} );

	my $simple_path_methods = native_functions(
		names => [
			qw(
				basename
				canonpath
				is_absolute
				is_relative
				is_rootdir
				realpath
				subsumes
				volume
				exists
				is_file
				is_dir
				size
				size_human
				touch
				touchpath
			)
		],
		builder => sub {
			my ( $name ) = @_;
			return sub {
				my ( $self, @args ) = @_;
				my $p = _to_path_tiny( $self );
				if ( $name eq 'subsumes' ) {
					my $other = @args ? _to_path_tiny( $args[0] ) : path('');
					return _bool( $p->subsumes( $other ) );
				}
				if ( $name eq 'touch' or $name eq 'touchpath' ) {
					my $out = $p->$name();
					return _new_path_object( $path_class, $out );
				}
				my $value = $p->$name();
				if ( $name =~ /\A(?:is_absolute|is_relative|is_rootdir|exists|is_file|is_dir)\z/ ) {
					return _bool( $value );
				}
				if ( $name eq 'realpath' ) {
					return defined $value
						? _new_path_object( $path_class, $value )
						: undef;
				}

				return $value;
			};
		},
	);

	$path_class->methods->{$_} = $simple_path_methods->{$_}
		for CORE::keys %{ $simple_path_methods };

	for my $name ( qw( absolute child parent sibling ) ) {
		$path_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, @args ) = @_;
				my $p = _to_path_tiny( $self );
				my @mapped = map {
					if ( blessed($_) and $_->isa('Zuzu::Value::Object') and exists $_->slots->{_path_tiny} ) {
						$_->slots->{_path_tiny};
					}
					else {
						defined $_ ? "$_" : '';
					}
				} @args;
				my $new = $p->$name( @mapped );
				return _new_path_object( $path_class, $new );
			},
		);
	}

	$path_class->methods->{to_String} = native_function(
		name => 'to_String',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return $p->stringify;
		},
	);

	$path_class->methods->{copy} = native_function(
		name => 'copy',
		native => sub {
			my ( $self, $to, @rest ) = @_;
			my $p = _to_path_tiny( $self );
			my $target = _to_path_tiny( $to );
			my $out = $p->copy( $target, @rest );
			return _new_path_object( $path_class, $out );
		},
	);

	for my $name ( qw( move remove mkdir remove_tree ) ) {
		$path_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, @args ) = @_;
				my $p = _to_path_tiny( $self );
				my @mapped = map {
					if ( blessed($_) and $_->isa('Zuzu::Value::Object') and exists $_->slots->{_path_tiny} ) {
						$_->slots->{_path_tiny};
					}
					else {
						$_;
					}
				} @args;
				return $p->$name( @mapped );
			},
		);
	}

	$path_class->methods->{mkdir_exclusive} = native_function(
		name => 'mkdir_exclusive',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			if ( mkdir $p->stringify ) {
				return 1;
			}
			return 0 if $! == EEXIST;
			die "IOError: mkdir_exclusive failed for $p: $!";
		},
	);

	$path_class->methods->{chmod} = native_function(
		name => 'chmod',
		native => sub {
			my ( $self, $mode ) = @_;
			my $p = _to_path_tiny( $self );
			return $p->chmod( $mode );
		},
	);

	for my $name ( qw( spew append ) ) {
		$path_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, @args ) = @_;
				_warn_blocking_operation( $runtime, "std/io Path.$name" );
				my $p = _to_path_tiny( $self );
				my $label = "Path.$name";
				_assert_binary_string( $args[0], $label );
				my $bytes = $args[0]->bytes;
				return $p->$name( $bytes );
			},
		);
	}

	for my $name ( qw( spew_utf8 append_utf8 ) ) {
		$path_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, @args ) = @_;
				_warn_blocking_operation( $runtime, "std/io Path.$name" );
				my $p = _to_path_tiny( $self );
				my $label = "Path.$name";
				_assert_text_string( $args[0], $label );
				return $p->$name( @args );
			},
		);
	}

	$path_class->methods->{slurp} = native_function(
		name => 'slurp',
		native => sub {
			my ( $self ) = @_;
			_warn_blocking_operation( $runtime, 'std/io Path.slurp' );
			my $p = _to_path_tiny( $self );
			my $bytes = $p->slurp();
			return Zuzu::Value::BinaryString->new( bytes => $bytes );
		},
	);

	$path_class->methods->{slurp_utf8} = native_function(
		name => 'slurp_utf8',
		native => sub {
			my ( $self ) = @_;
			_warn_blocking_operation( $runtime, 'std/io Path.slurp_utf8' );
			my $p = _to_path_tiny( $self );
			# Lax decode (like readline_utf8): valid UTF-8 sequences for
			# noncharacters such as U+10FFFE must round-trip, matching
			# zuzu-rust and zuzu-js; strict :encoding(UTF-8) refuses them.
			return decode_utf8( $p->slurp_raw(), 1 );
		},
	);

	$path_class->methods->{slurp_async} = native_function(
		name => 'slurp_async',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return _async_task(
				$runtime,
				'path.slurp_async',
				sub {
					return $p->slurp();
				},
				sub {
					my ( $bytes ) = @_;
					return Zuzu::Value::BinaryString->new( bytes => $bytes );
				},
			);
		},
	);

	$path_class->methods->{slurp_utf8_async} = native_function(
		name => 'slurp_utf8_async',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return _async_task(
				$runtime,
				'path.slurp_utf8_async',
				sub {
					return decode_utf8( $p->slurp_raw(), 1 );
				},
			);
		},
	);

	$path_class->methods->{lines} = native_function(
		name => 'lines',
		native => sub {
			my ( $self ) = @_;
			_warn_blocking_operation( $runtime, 'std/io Path.lines' );
			my $p = _to_path_tiny( $self );
			my @lines = $p->lines();
			my @wrapped = map {
				Zuzu::Value::BinaryString->new( bytes => $_ );
			} @lines;
			return perl_to_zuzu( \@wrapped );
		},
	);

	$path_class->methods->{lines_utf8} = native_function(
		name => 'lines_utf8',
		native => sub {
			my ( $self ) = @_;
			_warn_blocking_operation( $runtime, 'std/io Path.lines_utf8' );
			my $p = _to_path_tiny( $self );
			my @lines = map { decode_utf8( $_, 1 ) } $p->lines( { binmode => ':raw' } );
			return perl_to_zuzu( \@lines );
		},
	);

	$path_class->methods->{lines_async} = native_function(
		name => 'lines_async',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return _async_task(
				$runtime,
				'path.lines_async',
				sub {
					return [ $p->lines() ];
				},
				sub {
					my ( $lines ) = @_;
					my @wrapped = map {
						Zuzu::Value::BinaryString->new( bytes => $_ );
					} @{ $lines // [] };
					return perl_to_zuzu( \@wrapped );
				},
			);
		},
	);

	$path_class->methods->{lines_utf8_async} = native_function(
		name => 'lines_utf8_async',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return _async_task(
				$runtime,
				'path.lines_utf8_async',
				sub {
					return [ $p->lines_utf8() ];
				},
				sub {
					my ( $lines ) = @_;
					return perl_to_zuzu( $lines // [] );
				},
			);
		},
	);

	for my $name ( qw( spew append ) ) {
		$path_class->methods->{ $name . '_async' } = native_function(
			name => $name . '_async',
			native => sub {
				my ( $self, @args ) = @_;
				my $p = _to_path_tiny( $self );
				my $label = 'Path.' . $name . '_async';
				_assert_binary_string( $args[0], $label );
				my $bytes = $args[0]->bytes;
				return _async_task(
					$runtime,
					'path.' . $name . '_async',
					sub {
						$p->$name($bytes);
						return $p->stringify;
					},
					sub {
						my ( $out ) = @_;
						return _new_path_object( $path_class, path($out) );
					},
				);
			},
		);
	}

	for my $name ( qw( spew_utf8 append_utf8 ) ) {
		$path_class->methods->{ $name . '_async' } = native_function(
			name => $name . '_async',
			native => sub {
				my ( $self, @args ) = @_;
				my $p = _to_path_tiny( $self );
				my $label = 'Path.' . $name . '_async';
				_assert_text_string( $args[0], $label );
				my @text_args = @args;
				return _async_task(
					$runtime,
					'path.' . $name . '_async',
					sub {
						$p->$name(@text_args);
						return $p->stringify;
					},
					sub {
						my ( $out ) = @_;
						return _new_path_object( $path_class, path($out) );
					},
				);
			},
		);
	}

	$path_class->methods->{stat} = native_function(
		name => 'stat',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return _stat_to_dict( $p->stat );
		},
	);

	$path_class->methods->{lstat} = native_function(
		name => 'lstat',
		native => sub {
			my ( $self ) = @_;
			my $p = _to_path_tiny( $self );
			return _stat_to_dict( $p->lstat );
		},
	);

	for my $name ( qw( edit_lines edit_lines_utf8 ) ) {
		$path_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, $callback ) = @_;
				_warn_blocking_operation( $runtime, "std/io Path.$name" );
				my $p = _to_path_tiny( $self );
				$p->$name( sub {
					my ( $line ) = @_;
					my $out = $runtime->_call_function( $callback, [ $line ], '<std/io>', 0 );
					return defined $out ? "$out" : '';
				} );
				return $self;
			},
		);
	}

	$path_class->methods->{each_line} = native_function(
		name => 'each_line',
		native => sub {
			my ( $self, $callback, $raw_opt ) = @_;
			_warn_blocking_operation( $runtime, 'std/io Path.each_line' );
			my $raw = _raw_mode( $raw_opt );
			my $p = _to_path_tiny( $self );
			my $fh = $raw ? $p->openr_raw : $p->openr_utf8;
			while ( my $line = <$fh> ) {
				my $value = $raw
					? Zuzu::Value::BinaryString->new( bytes => $line )
					: $line;
				_call_callback( $runtime, $callback, [ $value ] );
			}
			close $fh;
			return $self;
		},
	);

	$path_class->methods->{next_line} = native_function(
		name => 'next_line',
		native => sub {
			my ( $self, $raw_opt ) = @_;
			_warn_blocking_operation( $runtime, 'std/io Path.next_line' );
			my $raw = _raw_mode( $raw_opt );
			my $cursor = $self->slots->{_line_cursor};
			my $mode = $self->slots->{_line_mode};
			if ( defined $cursor and defined $mode and $mode != $raw ) {
				close $cursor;
				$self->slots->{_line_cursor} = undef;
				$self->slots->{_line_done} = 0;
				$cursor = undef;
			}
			return undef if not defined $cursor and $self->slots->{_line_done};
			if ( not defined $cursor ) {
				my $p = _to_path_tiny( $self );
				$cursor = $raw ? $p->openr_raw : $p->openr_utf8;
				$self->slots->{_line_cursor} = $cursor;
				$self->slots->{_line_done} = 0;
				$self->slots->{_line_mode} = $raw;
			}
			my $line = <$cursor>;
			if ( defined $line ) {
				return $raw
					? Zuzu::Value::BinaryString->new( bytes => $line )
					: $line;
			}
			close $cursor;
			$self->slots->{_line_cursor} = undef;
			$self->slots->{_line_done} = 1;
			return undef;
		},
	);

	$path_class->methods->{children} = native_function(
		name => 'children',
		native => sub {
			my ( $self, @args ) = @_;
			my $p = _to_path_tiny( $self );
			my @kids = $p->children( @args );
			return _new_path_array( $path_class, \@kids );
		},
	);

	$path_iterator_class->methods->{next} = native_function(
		name => 'next',
		native => sub {
			my ( $self ) = @_;
			my $iter = $self->slots->{_iter};
			return undef if not defined $iter;
			my $next = $iter->();
			return undef if not defined $next;
			return _new_path_object( $path_class, $next );
		},
	);

	$path_class->methods->{iterator} = native_function(
		name => 'iterator',
		native => sub {
			my ( $self, @args ) = @_;
			my $p = _to_path_tiny( $self );
			my $iter = $p->iterator( @args );
			return native_object(
				class => $path_iterator_class,
				slots => {
					_iter => $iter,
				},
				const => {
					_iter => 1,
				},
			);
		},
	);

	$path_class->methods->{visit} = native_function(
		name => 'visit',
		native => sub {
			my ( $self, $callback, @args ) = @_;
			my $p = _to_path_tiny( $self );
			$p->visit( sub {
				my ( $entry ) = @_;
				my $wrapped = _new_path_object( $path_class, $entry );
				_call_callback( $runtime, $callback, [ $wrapped ] );
			}, @args );
			return $self;
		},
	);

	$path_class->static_methods->{cwd} = native_function(
		name => 'cwd',
		native => sub {
			return _new_path_object( $path_class, cwd() );
		},
	);
	$path_class->static_methods->{rootdir} = native_function(
		name => 'rootdir',
		native => sub {
			return _new_path_object( $path_class, rootdir() );
		},
	);
	$path_class->static_methods->{tempfile} = native_function(
		name => 'tempfile',
		native => sub {
			my ( $self, @args ) = @_;
			push @args, UNLINK => 0
				if not _has_named_temp_option( \@args, 'UNLINK' );
			my $path = tempfile( @args );
			return _new_path_object(
				$path_class,
				$path,
				_temp_path_cleanup( $path, 0 ),
			);
		},
	);
	$path_class->static_methods->{tempdir} = native_function(
		name => 'tempdir',
		native => sub {
			my ( $self, @args ) = @_;
			push @args, CLEANUP => 0
				if not _has_named_temp_option( \@args, 'CLEANUP' );
			my $path = tempdir( @args );
			return _new_path_object(
				$path_class,
				$path,
				_temp_path_cleanup( $path, 1 ),
			);
		},
	);
	$path_class->static_methods->{glob} = native_function(
		name => 'glob',
		native => sub {
			my ( $self, $pattern, $options ) = @_;
			my $pattern_perl = zuzu_to_perl($pattern);
			my $p = defined $pattern_perl ? "$pattern_perl" : '';
			my $flags = _glob_flags_from_options( zuzu_to_perl($options) );
			my @hits = bsd_glob( $p, $flags );
			my @paths = map { path($_) } @hits;
			return _new_path_array( $path_class, \@paths );
		},
	);
	$path_class->static_methods->{join} = native_function(
		name => 'join',
		native => sub {
			my ( $self, $parts ) = @_;
			my @parts = _normalize_join_parts( zuzu_to_perl($parts) );
			my $joined = path( @parts );
			return _new_path_object( $path_class, $joined );
		},
	);
	$path_class->static_methods->{split} = native_function(
		name => 'split',
		native => sub {
			my ( $self, $raw_path ) = @_;
			my $path_perl = zuzu_to_perl($raw_path);
			my $input = defined $path_perl ? "$path_perl" : '';
			my ( $vol, $dir, $base ) = File::Spec->splitpath($input);
			my @parts = File::Spec->splitdir($dir);
			push @parts, $base if $base ne '';
			@parts = grep { defined $_ and $_ ne '' } @parts;
			unshift @parts, $vol if defined $vol and $vol ne '';
			return perl_to_zuzu( \@parts );
		},
	);
	$path_class->static_methods->{normalize} = native_function(
		name => 'normalize',
		native => sub {
			my ( $self, $raw_path ) = @_;
			my $path_perl = zuzu_to_perl($raw_path);
			my $p = path( defined $path_perl ? "$path_perl" : '' );
			my $canon = $p->canonpath;
			return _new_path_object( $path_class, path($canon) );
		},
	);

	$stdin_class->methods->{next_line} = native_function(
		name => 'next_line',
		native => sub {
			my ( $self, $raw_opt ) = @_;
			my $raw = _raw_mode( $raw_opt );
			my $line = <STDIN>;
			return undef if not defined $line;
			return $raw
				? Zuzu::Value::BinaryString->new( bytes => $line )
				: _decode_if_utf8( $line, $raw );
		},
	);

	$stdin_class->methods->{each_line} = native_function(
		name => 'each_line',
		native => sub {
			my ( $self, $callback, $raw_opt ) = @_;
			my $raw = _raw_mode( $raw_opt );
			while ( my $line = <STDIN> ) {
				my $value = $raw
					? Zuzu::Value::BinaryString->new( bytes => $line )
					: _decode_if_utf8( $line, $raw );
				_call_callback( $runtime, $callback, [ $value ] );
			}
			return undef;
		},
	);

	$stdout_class->methods->{print} = native_function(
		name => 'print',
		native => sub {
			my ( $self, @args ) = @_;
			print STDOUT join '', map { defined $_ ? "$_" : '' } @args;
			return undef;
		},
	);
	$stdout_class->methods->{say} = native_function(
		name => 'say',
		native => sub {
			my ( $self, @args ) = @_;
			print STDOUT join( '', map { defined $_ ? "$_" : '' } @args ), "\n";
			return undef;
		},
	);

	$stderr_class->methods->{print} = native_function(
		name => 'print',
		native => sub {
			my ( $self, @args ) = @_;
			print STDERR join '', map { defined $_ ? "$_" : '' } @args;
			return undef;
		},
	);
	$stderr_class->methods->{say} = native_function(
		name => 'say',
		native => sub {
			my ( $self, @args ) = @_;
			print STDERR join( '', map { defined $_ ? "$_" : '' } @args ), "\n";
			return undef;
		},
	);

	my $stdin_obj = native_object(
		class => $stdin_class,
		slots => {},
		const => {},
	);
	my $stdout_obj = native_object(
		class => $stdout_class,
		slots => {},
		const => {},
	);
	my $stderr_obj = native_object(
		class => $stderr_class,
		slots => {},
		const => {},
	);

	return {
		Path => $path_class,
		PathIterator => $path_iterator_class,
		STDIN => $stdin_obj,
		STDOUT => $stdout_obj,
		STDERR => $stderr_obj,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::IO - std/io bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/io> module, exporting path and stream helpers.

=head1 EXPORTS

=head2 Path

Filesystem path object backed by C<Path::Tiny>. Supports path
manipulation, metadata checks, file I/O, and traversal helpers.

Notable methods include:

=over

=item * path transforms: C<absolute>, C<child>, C<parent>, C<sibling>

=item * queries: C<exists>, C<is_file>, C<is_dir>, C<subsumes>

=item * binary I/O: C<slurp>, C<spew>, C<append>, C<lines>

=item * UTF-8 I/O: C<slurp_utf8>, C<spew_utf8>, C<append_utf8>, C<lines_utf8>

=item * streaming: C<each_line>, C<next_line>

=item * traversal: C<children>, C<iterator>, C<visit>

=item * metadata: C<size>, C<size_human>, C<stat>, C<lstat>

=item * directories: C<mkdir>, C<mkdir_exclusive>, C<remove_tree>

=back

Static helpers include C<cwd>, C<rootdir>, C<tempfile>, and C<tempdir>.

=head2 PathIterator

Iterator object returned by C<Path-E<gt>iterator>.

Methods:

=over

=item * C<next()>

=back

=head2 STDIN

Methods:

=over

=item * C<next_line(raw?)>

=item * C<each_line(callback, raw?)>

=back

=head2 STDOUT and STDERR

Methods:

=over

=item * C<print(...)>

=item * C<say(...)>

=back

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::IO >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

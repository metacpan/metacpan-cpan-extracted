package Zuzu::Module::CLib;

use utf8;

our $VERSION = '0.001005';

use FFI::Platypus 2.00;
use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );
use Scalar::Util qw( blessed );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	zuzu_to_perl
);
use Zuzu::Value::BinaryString;
use Zuzu::Value::Boolean;

sub _runtime_error {
	my ( $message ) = @_;

	die Zuzu::Error->new_runtime(
		message => $message,
		file => '<std/clib>',
		line => 0,
	);
}

sub _bool_value {
	my ( $value ) = @_;

	return Zuzu::Value::Boolean->new( value => $value ? 1 : 0 );
}

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if !defined $value;
	return 'BinaryString'
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');
	return 'Boolean'
		if blessed($value) and $value->isa('Zuzu::Value::Boolean');
	return 'Object' if blessed($value);
	if ( !ref($value) and "$value" =~ /\A-?(?:\d+(?:\.\d*)?|\.\d+)\z/ ) {
		return 'Number';
	}
	return 'String' if !ref($value);
	return 'Object';
}

sub _normalize_descriptor {
	my ( $raw, $context ) = @_;

	$raw = zuzu_to_perl($raw);
	my $desc;
	if ( !ref($raw) ) {
		$desc = { type => ( defined $raw ? "$raw" : 'null' ) };
	}
	elsif ( ref($raw) eq 'HASH' ) {
		$desc = { %{ $raw } };
	}
	else {
		_runtime_error("$context descriptor must be String or Dict");
	}

	my $type = defined $desc->{type} ? "$desc->{type}" : '';
	$type = lc $type;
	$desc->{type} = $type;

	if ( $type eq 'null' ) {
		$desc->{ffi_type} = 'void';
	}
	elsif ( $type eq 'bool' ) {
		$desc->{ffi_type} = 'bool';
	}
	elsif ( $type eq 'int' ) {
		my $bits = exists $desc->{bits} ? int( $desc->{bits} ) : 64;
		_runtime_error("$context int descriptor only supports bits=64")
			if $bits != 64;
		my $signed = exists $desc->{signed} ? $desc->{signed} ? 1 : 0 : 1;
		$desc->{bits} = 64;
		$desc->{signed} = $signed;
		$desc->{ffi_type} = $signed ? 'sint64' : 'uint64';
	}
	elsif ( $type eq 'float' ) {
		my $bits = exists $desc->{bits} ? int( $desc->{bits} ) : 64;
		_runtime_error("$context float descriptor only supports bits=64")
			if $bits != 64;
		$desc->{bits} = 64;
		$desc->{ffi_type} = 'double';
	}
	elsif ( $type eq 'binary' ) {
		$desc->{ffi_type} = 'opaque';
		$desc->{nullable} = $desc->{nullable} ? 1 : 0;
	}
	else {
		_runtime_error("$context descriptor has unsupported type '$type'");
	}

	return $desc;
}

sub _normalize_params {
	my ( $params ) = @_;

	my $raw = zuzu_to_perl($params);
	$raw = [] if !defined $raw;
	_runtime_error('params descriptor must be Array') if ref($raw) ne 'ARRAY';

	my @out;
	for ( my $i = 0; $i < @{ $raw }; $i++ ) {
		push @out, _normalize_descriptor( $raw->[$i], "parameter $i" );
	}

	return \@out;
}

sub _assert_open_library {
	my ( $state ) = @_;

	_runtime_error('CLibrary is closed') if $state->{closed};
}

sub _assert_callable_function {
	my ( $state ) = @_;

	_runtime_error('CFunction belongs to a closed CLibrary')
		if $state->{lib_state}{closed};
	_runtime_error('CFunction is closed') if $state->{closed};
}

sub _prepare_arg {
	my ( $desc, $value, $index, $temps ) = @_;
	my $type = $desc->{type};

	if ( $type eq 'null' ) {
		_runtime_error("argument $index must be Null, got " . _type_name($value))
			if defined $value;
		return undef;
	}

	if ( $type eq 'bool' ) {
		_runtime_error("argument $index must be Boolean, got " . _type_name($value))
			if !blessed($value) or !$value->isa('Zuzu::Value::Boolean');
		return $value->value ? 1 : 0;
	}

	if ( $type eq 'int' ) {
		_runtime_error("argument $index must be Number, got " . _type_name($value))
			if ref($value);
		return 0 + int($value);
	}

	if ( $type eq 'float' ) {
		_runtime_error("argument $index must be Number, got " . _type_name($value))
			if ref($value);
		return 0 + $value;
	}

	if ( $type eq 'binary' ) {
		if ( !defined $value ) {
			_runtime_error("argument $index must be BinaryString, got Null")
				if !$desc->{nullable};
			return undef;
		}
		_runtime_error(
			"argument $index must be BinaryString, got " . _type_name($value)
		)
			if !blessed($value) or !$value->isa('Zuzu::Value::BinaryString');

		my $bytes = $value->bytes // '';
		$bytes .= "\0" if defined $desc->{terminated_by}
			and $desc->{terminated_by} eq 'nul';
		my ( $ptr ) = scalar_to_buffer($bytes);
		push @{ $temps }, $bytes;
		return $ptr;
	}

	_runtime_error("argument $index has unsupported type '$type'");
}

sub _return_length {
	my ( $desc, $args ) = @_;

	if ( exists $desc->{length} ) {
		my $length = int( $desc->{length} );
		_runtime_error('binary return length must be non-negative')
			if $length < 0;
		return $length;
	}

	if ( exists $desc->{length_arg} ) {
		my $index = int( $desc->{length_arg} );
		_runtime_error("binary return length_arg index $index is out of range")
			if $index < 0 or $index >= @{ $args };
		my $length = int( 0 + $args->[$index] );
		_runtime_error('binary return length_arg value must be non-negative')
			if $length < 0;
		return $length;
	}

	return undef;
}

sub _finish_binary_return {
	my ( $ffi, $desc, $ptr, $args ) = @_;

	return undef if !defined $ptr or !$ptr;

	my $bytes;
	my $length = _return_length( $desc, $args );
	if ( defined $length ) {
		$bytes = buffer_to_scalar( $ptr, $length );
	}
	elsif ( defined $desc->{terminated_by} and $desc->{terminated_by} eq 'nul' ) {
		$bytes = $ffi->cast( 'opaque' => 'string', $ptr );
	}
	else {
		_runtime_error('binary return requires length, length_arg, or terminated_by');
	}

	if ( defined $desc->{free_function} ) {
		$desc->{free_function}->call($ptr);
	}

	return Zuzu::Value::BinaryString->new( bytes => $bytes // '' );
}

sub _finish_return {
	my ( $ffi, $desc, $raw, $args ) = @_;
	my $type = $desc->{type};

	return undef if $type eq 'null';
	return _bool_value($raw) if $type eq 'bool';
	return 0 + $raw if $type eq 'int' or $type eq 'float';
	return _finish_binary_return( $ffi, $desc, $raw, $args )
		if $type eq 'binary';

	_runtime_error("return descriptor has unsupported type '$type'");
}

sub _library_state_from_object {
	my ( $obj ) = @_;

	return $obj->slots->{_state}
		if blessed($obj)
		and $obj->isa('Zuzu::Value::Object')
		and exists $obj->slots->{_state};

	_runtime_error('Expected CLibrary object');
}

sub _function_state_from_object {
	my ( $obj ) = @_;

	return $obj->slots->{_state}
		if blessed($obj)
		and $obj->isa('Zuzu::Value::Object')
		and exists $obj->slots->{_state};

	_runtime_error('Expected CFunction object');
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $clib_class = native_class(
		name => 'CLib',
	);
	my $library_class = native_class(
		name => 'CLibrary',
	);
	my $function_class = native_class(
		name => 'CFunction',
	);

	$clib_class->static_methods->{open} = native_function(
		name => 'open',
		native => sub {
			my ( $self, $path ) = @_;
			$runtime->assert_capability(
				'clib',
				'CLib.open is denied by runtime policy',
				'<std/clib>',
				0,
			);

			my $library_path = defined $path ? "$path" : '';
			my $ffi = FFI::Platypus->new( api => 2 );
			eval {
				$ffi->lib($library_path);
				1;
			} or do {
				my $error = $@ || 'unknown error';
				_runtime_error("Could not load C library '$library_path': $error");
			};

			return native_object(
				class => $library_class,
				slots => {
					_state => {
						ffi => $ffi,
						path => $library_path,
						closed => 0,
					},
				},
				const => {
					_state => 1,
				},
			);
		},
	);

	$library_class->methods->{has_symbol} = native_function(
		name => 'has_symbol',
		native => sub {
			my ( $self, $name ) = @_;
			my $state = _library_state_from_object($self);
			_assert_open_library($state);
			my $symbol = defined $name ? "$name" : '';
			my $ptr = eval { $state->{ffi}->find_symbol($symbol) };
			return _bool_value( defined $ptr && $ptr ? 1 : 0 );
		},
	);

	$library_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self ) = @_;
			my $state = _library_state_from_object($self);
			$state->{closed} = 1;
			return undef;
		},
	);

	$library_class->methods->{func} = native_function(
		name => 'func',
		native => sub {
			my ( $self, $name, $params, $return_type, $options ) = @_;
			my $state = _library_state_from_object($self);
			_assert_open_library($state);
			my $symbol = defined $name ? "$name" : '';
			_runtime_error('C function name must not be empty') if $symbol eq '';

			my $param_descs = _normalize_params($params);
			my $return_desc = _normalize_descriptor( $return_type, 'return' );
			my @ffi_params = map { $_->{ffi_type} } @{ $param_descs };
			my $ffi_return = $return_desc->{ffi_type};
			my $callable = eval {
				$state->{ffi}->function( $symbol => \@ffi_params => $ffi_return );
			};
			if ( !$callable ) {
				my $error = $@ || 'symbol not found';
				_runtime_error(
					"Could not bind C function '$symbol' in '$state->{path}': $error"
				);
			}

			if ( $return_desc->{type} eq 'binary' and defined $return_desc->{free} ) {
				my $free_symbol = "$return_desc->{free}";
				my $free_function = eval {
					$state->{ffi}->function( $free_symbol => ['opaque'] => 'void' );
				};
				if ( !$free_function ) {
					my $error = $@ || 'symbol not found';
					_runtime_error(
						"Could not bind free function '$free_symbol' in "
						. "'$state->{path}': $error"
					);
				}
				$return_desc->{free_function} = $free_function;
			}

			return native_object(
				class => $function_class,
				slots => {
					_state => {
						lib_state => $state,
						name => $symbol,
						param_descs => $param_descs,
						return_desc => $return_desc,
						callable => $callable,
						closed => 0,
					},
				},
				const => {
					_state => 1,
				},
			);
		},
	);

	$function_class->methods->{call} = native_function(
		name => 'call',
		native => sub {
			my ( $self, @args ) = @_;
			my $state = _function_state_from_object($self);
			_assert_callable_function($state);

			my $param_descs = $state->{param_descs};
			_runtime_error(
				"Function '$state->{name}' expects "
				. scalar( @{ $param_descs } )
				. ' arguments, got '
				. scalar(@args)
			) if scalar(@args) != scalar( @{ $param_descs } );

			my @temps;
			my @ffi_args;
			for ( my $i = 0; $i < @{ $param_descs }; $i++ ) {
				push @ffi_args, _prepare_arg(
					$param_descs->[$i],
					$args[$i],
					$i,
					\@temps,
				);
			}

			my $raw = eval { $state->{callable}->call(@ffi_args) };
			if ($@) {
				_runtime_error("C function '$state->{name}' failed: $@");
			}

			return _finish_return(
				$state->{lib_state}{ffi},
				$state->{return_desc},
				$raw,
				\@args,
			);
		},
	);

	return {
		CLib => $clib_class,
		CLibrary => $library_class,
		CFunction => $function_class,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::CLib >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

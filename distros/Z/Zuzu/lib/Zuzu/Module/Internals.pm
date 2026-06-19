package Zuzu::Module::Internals;

use utf8;

our $VERSION = '0.006000';

use Scalar::Util qw( blessed refaddr );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_function
	perl_to_zuzu
);
use Zuzu::Weak qw( slot_value );

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $class_name = native_function(
		name => 'class_name',
		native => sub {
			my ( $value ) = @_;
			return undef if not blessed($value);
			return undef if not $value->isa('Zuzu::Value::Object');
			return undef if not blessed( $value->class );
			return $value->class->name;
		},
	);

	my $classof = native_function(
		name => 'classof',
		native => sub {
			my ( $value ) = @_;
			return undef if !defined $value;

			if ( blessed($value) and $value->isa('Zuzu::Value::Object') ) {
				return $value->class if blessed( $value->class );
				return undef;
			}

			my $type = $runtime->_type_name($value);
			return undef if $type =~ /\A(?:Null|Boolean|Number|String|Method)\z/;

			return $runtime->{_builtin_classes}{$type};
		},
	);

	my $object_slots = native_function(
		name => 'object_slots',
		native => sub {
			my ( $value ) = @_;
			return undef if not blessed($value);
			return undef if not $value->isa('Zuzu::Value::Object');

			my %out;
			for my $key ( sort CORE::keys %{ $value->slots // {} } ) {
				next if $key =~ /^_/;
				$out{$key} = slot_value( \$value->slots->{$key} );
			}
			return perl_to_zuzu(\%out);
		},
	);


	my $ansi_esc = native_function(
		name => 'ansi_esc',
		native => sub {
			return chr 27;
		},
	);

	my $ref_id = native_function(
		name => 'ref_id',
		native => sub {
			my ( $value ) = @_;
			return undef if not defined $value;
			return undef if not ref $value;
			return refaddr($value);
		},
	);

	my $to_String = native_function(
		name => 'to_String',
		native => sub {
			my ( $value ) = @_;
			my $file = $runtime->{_native_call_file} // '<std/internals>';
			my $line = $runtime->{_native_call_line} // 0;

			return $runtime->_to_OperatorString( $value, $file, $line );
		},
	);

	my $to_Number = native_function(
		name => 'to_Number',
		native => sub {
			my ( $value ) = @_;
			my $file = $runtime->{_native_call_file} // '<std/internals>';
			my $line = $runtime->{_native_call_line} // 0;

			return $runtime->_to_Number( $value, $file, $line );
		},
	);

	my $to_Boolean = native_function(
		name => 'to_Boolean',
		native => sub {
			my ( $value ) = @_;

			return $runtime->_to_Boolean($value) ? 1 : 0;
		},
	);

	my $to_Regexp = native_function(
		name => 'to_Regexp',
		native => sub {
			my ( $value ) = @_;
			my $file = $runtime->{_native_call_file} // '<std/internals>';
			my $line = $runtime->{_native_call_line} // 0;

			return $runtime->_to_RegexpValue( $value, $file, $line );
		},
	);

	my $to_Regexp_with_flags = native_function(
		name => 'to_Regexp_with_flags',
		native => sub {
			my ( $value, $flags ) = @_;
			my $file = $runtime->{_native_call_file} // '<std/internals>';
			my $line = $runtime->{_native_call_line} // 0;

			return $runtime->_to_RegexpValue_with_flags( $value, $flags, $file, $line );
		},
	);

	my $make_instance = native_function(
		name => 'make_instance',
		native => sub {
			my ( $klass, $slot_values ) = @_;
			die "make_instance expects a Class"
				if !blessed($klass) or !$klass->isa('Zuzu::Value::Class');

			my $slots = {};
			if ( defined $slot_values ) {
				my $dict = $runtime->_unwrap_builtin_collection(
					$slot_values,
					'Dict',
				);
				die "make_instance slot values must be Dict" if !$dict;
				$slots = { %{ $dict->map } };
			}

			return $runtime->_make_instance_without_build(
				$klass,
				$slots,
				'<std/internals>',
				0,
			);
		},
	);

	my $load_module = native_function(
		name => 'load_module',
		native => sub {
			my $file = $runtime->{_native_call_file} // '<std/internals>';
			my $line = $runtime->{_native_call_line} // 0;
			my $throw = sub {
				my ( $message ) = @_;
				die Zuzu::Error->new_runtime(
					message => $message,
					file => $file,
					line => $line,
				);
			};

			$throw->( "load_module expects 1 to 2 arguments" )
				if @_ < 1 or @_ > 2;

			my ( $module, $symbol ) = @_;
			$throw->( "load_module module must be String" )
				if ref($module);
			$throw->( "load_module symbol must be String" )
				if defined $symbol and ref($symbol);

			my $env = $runtime->_load_module( $module, $file, $line );
			my $exports = $runtime->{_module_exports}{$module} // {};

			if ( defined $symbol ) {
				$throw->( "Module '$module' has no export '$symbol'" )
					if !$exports->{$symbol};
				my $ref = $env->find_ref($symbol);
				$throw->( "Module '$module' has no export '$symbol'" )
					if !$ref;
				return slot_value($ref);
			}

			my %out;
			for my $name ( sort CORE::keys %{ $exports } ) {
				my $ref = $env->find_ref($name);
				next if !$ref;
				$out{$name} = slot_value($ref);
			}

			return perl_to_zuzu(\%out);
		},
	);

	my $setprop = native_function(
		name => 'setprop',
		native => sub {
			my ( $key, $value ) = @_;
			return $runtime->env_set_special_prop( $key, $value );
		},
	);

	my $getprop = native_function(
		name => 'getprop',
		native => sub {
			my ( $key ) = @_;
			return $runtime->env_get_special_prop( $key );
		},
	);

	my $setupperprop = native_function(
		name => 'setupperprop',
		native => sub {
			my ( $level, $key, $value ) = @_;
			return $runtime->env_set_upper_special_prop( $level, $key, $value );
		},
	);

	my $getupperprop = native_function(
		name => 'getupperprop',
		native => sub {
			my ( $level, $key ) = @_;
			return $runtime->env_get_upper_special_prop( $level, $key );
		},
	);

	return {
		class_name => $class_name,
		classof => $classof,
		object_slots => $object_slots,
		ansi_esc => $ansi_esc,
		ref_id => $ref_id,
		to_String => $to_String,
		to_Number => $to_Number,
		to_Boolean => $to_Boolean,
		to_Regexp => $to_Regexp,
		to_Regexp_with_flags => $to_Regexp_with_flags,
		make_instance => $make_instance,
		load_module => $load_module,
		setprop => $setprop,
		getprop => $getprop,
		setupperprop => $setupperprop,
		getupperprop => $getupperprop,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Internals >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

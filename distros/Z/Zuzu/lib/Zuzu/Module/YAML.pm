package Zuzu::Module::YAML;

use utf8;

our $VERSION = '0.001002';

use JSON::PP ();
use Scalar::Util qw( blessed );
use YAML::PP ();
use Zuzu::Error;
use Zuzu::Value::BinaryString;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);

sub _assert_binary_string {
	my ( $value, $label ) = @_;

	return $value
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');

	my $type = !defined($value) ? 'Null' : ref($value) ? ref($value) : 'String';
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects BinaryString, got $type",
		file => '<std/data/yaml>',
		line => 0,
	);
}

sub _decode_yaml_to_zuzu {
	my ( $self, $yaml ) = @_;

	my $perl = $self->slots->{_yaml}->load_string($yaml);
	return perl_to_zuzu(
		$perl,
		is_boolean => sub {
			return JSON::PP::is_bool( $_[0] ) ? 1 : 0;
		},
	);
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $yaml_class = native_class(
		name => 'YAML',
	);

	$yaml_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my %config = %{ $named // {} };
		if ( @{ $positional // [] } ) {
			my $first = $positional->[0];
			if ( ref($first) ) {
				my $first_hash = zuzu_to_perl( $first );
				if ( ref($first_hash) eq 'HASH' ) {
					for my $key ( CORE::keys %{ $first_hash } ) {
						$config{$key} = $first_hash->{$key};
					}
				}
			}
		}

		my $yp = YAML::PP->new(
			boolean => 'JSON::PP',
			schema => [qw/ JSON Merge /],
		);

		return native_object(
			class => $klass,
			slots => {
				_yaml => $yp,
				_pretty => zuzu_bool( $config{pretty}, 0 ) ? 1 : 0,
				_canonical => zuzu_bool( $config{canonical}, 0 ) ? 1 : 0,
			},
			const => {
				_yaml => 1,
				_pretty => 1,
				_canonical => 1,
			},
		);
	} );

	$yaml_class->methods->{encode} = native_function(
		name => 'encode',
		native => sub {
			my ( $self, @args ) = @_;
			my $value = @args ? $args[0] : undef;
			my $perl = zuzu_to_perl(
				$value,
				boolean_mapper => sub {
					return $_[0] ? JSON::PP::true() : JSON::PP::false();
				},
			);
			my $yaml = $self->slots->{_yaml}->dump_string( $perl );
			$yaml = '' if not defined $yaml;
			if ( not $self->slots->{_pretty} ) {
				$yaml =~ s/\n\z//;
			}
			return $yaml;
		},
	);

	$yaml_class->methods->{encode_binarystring} = native_function(
		name => 'encode_binarystring',
		native => sub {
			my ( $self, @args ) = @_;
			return Zuzu::Value::BinaryString->from_utf8_string(
				$yaml_class->methods->{encode}->{_native}->( $self, @args )
			);
		},
	);

	$yaml_class->methods->{decode} = native_function(
		name => 'decode',
		native => sub {
			my ( $self, @args ) = @_;
			my $yaml = @args ? $args[0] : '';
			$yaml = defined($yaml) ? "$yaml" : '';
			return _decode_yaml_to_zuzu( $self, $yaml );
		},
	);

	$yaml_class->methods->{decode_binarystring} = native_function(
		name => 'decode_binarystring',
		native => sub {
			my ( $self, @args ) = @_;
			my $raw = _assert_binary_string(
				@args ? $args[0] : undef,
				'YAML.decode_binarystring',
			);
			return _decode_yaml_to_zuzu( $self, $raw->to_utf8_string );
		},
	);

	$yaml_class->methods->{load} = native_function(
		name => 'load',
		native => sub {
			my ( $self, $path_obj ) = @_;
			$runtime->assert_capability( 'fs', "YAML.load is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'YAML.load' );
			my $raw = Zuzu::Value::BinaryString->new(
				bytes => $path_tiny->slurp_raw,
			);
			return $yaml_class->methods->{decode_binarystring}->{_native}->(
				$self,
				$raw,
			);
		},
	);

	$yaml_class->methods->{dump} = native_function(
		name => 'dump',
		native => sub {
			my ( $self, $path_obj, @args ) = @_;
			$runtime->assert_capability( 'fs', "YAML.dump is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'YAML.dump' );
			my $value = @args ? $args[0] : undef;
			my $perl = zuzu_to_perl(
				$value,
				boolean_mapper => sub {
					return $_[0] ? JSON::PP::true() : JSON::PP::false();
				},
			);
			my $yaml = $self->slots->{_yaml}->dump_string( $perl );
			$yaml = '' if not defined $yaml;
			if ( not $self->slots->{_pretty} ) {
				$yaml =~ s/\n\z//;
			}
			$path_tiny->spew_raw(
				Zuzu::Value::BinaryString->from_utf8_string($yaml)->bytes
			);
			return $path_obj;
		},
	);

	return {
		YAML => $yaml_class,
	};
}

sub _path_tiny_from_object {
	my ( $path_obj, $method_name ) = @_;

	if (
		blessed($path_obj)
		and $path_obj->isa('Zuzu::Value::Object')
		and exists $path_obj->slots->{_path_tiny}
	) {
		return $path_obj->slots->{_path_tiny};
	}
	if ( ref($path_obj) eq 'HASH' and exists $path_obj->{_path_tiny} ) {
		return $path_obj->{_path_tiny};
	}

	die Zuzu::Error->new_runtime(
		message => "TypeException: $method_name expects Path as first argument",
		file => '<std/data/yaml>',
		line => 0,
	);
}

1;

=pod

=head1 NAME

Zuzu::Module::YAML - std/data/yaml bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/data/yaml> module. The importer provides a single class
named C<YAML>.

=head1 CLASSES

=head2 YAML

Constructor options:

=over

=item * C<pretty> (default false)

Preserves the trailing newline generated by the YAML emitter.

=item * C<canonical> (default false)

Accepted for API compatibility with C<std/data/json> and C<std/data/toml>.

=back

Instance methods:

=over

=item * C<encode(value)>

Encodes a ZuzuScript value as YAML text.

=item * C<decode(yaml)>

Decodes YAML text and returns the corresponding ZuzuScript value.

=item * C<load(path)>

Reads YAML text from a C<std/io> C<Path> and decodes it.
Throws if given anything other than C<Path>.

=item * C<dump(path, value)>

Encodes C<value> and writes YAML text to a C<std/io> C<Path>.
Throws if given anything other than C<Path>.

=back

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::YAML >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

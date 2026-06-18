package Zuzu::Module::DigestSHA;

use utf8;

our $VERSION = '0.005000';

use Digest::SHA qw(
	hmac_sha1
	hmac_sha1_base64
	hmac_sha1_hex
	hmac_sha224
	hmac_sha224_base64
	hmac_sha224_hex
	hmac_sha256
	hmac_sha256_base64
	hmac_sha256_hex
	hmac_sha384
	hmac_sha384_base64
	hmac_sha384_hex
	hmac_sha512
	hmac_sha512_base64
	hmac_sha512_hex
	sha1
	sha1_base64
	sha1_hex
	sha224
	sha224_base64
	sha224_hex
	sha256
	sha256_base64
	sha256_hex
	sha384
	sha384_base64
	sha384_hex
	sha512
	sha512_base64
	sha512_hex
);
use Scalar::Util qw( blessed );

use Zuzu::Util::NativeHelpers qw(
	native_function
);
use Zuzu::Error;
use Zuzu::Value::BinaryString;

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if not defined $value;
	return 'BinaryString'
		if blessed( $value )
			and $value->isa( 'Zuzu::Value::BinaryString' );
	return 'String';
}

sub _assert_binary {
	my ( $value, $label, $arg_name ) = @_;

	$arg_name //= 'BinaryString';

	return if blessed( $value )
		and $value->isa( 'Zuzu::Value::BinaryString' );

	my $type = _type_name( $value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects $arg_name, got $type",
		file => '<std/digest/sha>',
		line => 0,
	);
}

sub _bin_digest {
	my ( $label, $func, $value ) = @_;

	_assert_binary( $value, $label );

	my $digest = $func->( $value->bytes );
	return Zuzu::Value::BinaryString->new( bytes => $digest );
}

sub _str_digest {
	my ( $label, $func, $value ) = @_;

	_assert_binary( $value, $label );

	return $func->( $value->bytes );
}

sub _export_triplet {
	my ( $name, $bin_func, $hex_func, $b64_func ) = @_;

	return (
		$name => native_function(
			name => $name,
			native => sub {
				my ( $value ) = @_;
				return _bin_digest( $name, $bin_func, $value );
			},
		),
		"${name}_hex" => native_function(
			name => "${name}_hex",
			native => sub {
				my ( $value ) = @_;
				return _str_digest( "${name}_hex", $hex_func, $value );
			},
		),
		"${name}_b64" => native_function(
			name => "${name}_b64",
			native => sub {
				my ( $value ) = @_;
				return _str_digest( "${name}_b64", $b64_func, $value );
			},
		),
	);
}

sub _bin_hmac {
	my ( $label, $func, $value, $key ) = @_;

	_assert_binary( $value, $label );
	_assert_binary( $key, $label, 'BinaryString key' );

	my $digest = $func->( $value->bytes, $key->bytes );
	return Zuzu::Value::BinaryString->new( bytes => $digest );
}

sub _str_hmac {
	my ( $label, $func, $value, $key ) = @_;

	_assert_binary( $value, $label );
	_assert_binary( $key, $label, 'BinaryString key' );

	return $func->( $value->bytes, $key->bytes );
}

sub _export_hmac_triplet {
	my ( $name, $bin_func, $hex_func, $b64_func ) = @_;

	return (
		$name => native_function(
			name => $name,
			native => sub {
				my ( $value, $key ) = @_;
				return _bin_hmac( $name, $bin_func, $value, $key );
			},
		),
		"${name}_hex" => native_function(
			name => "${name}_hex",
			native => sub {
				my ( $value, $key ) = @_;
				return _str_hmac(
					"${name}_hex",
					$hex_func,
					$value,
					$key,
				);
			},
		),
		"${name}_b64" => native_function(
			name => "${name}_b64",
			native => sub {
				my ( $value, $key ) = @_;
				return _str_hmac(
					"${name}_b64",
					$b64_func,
					$value,
					$key,
				);
			},
		),
	);
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	return {
		_export_triplet( 'sha1',   \&sha1,   \&sha1_hex,   \&sha1_base64 ),
		_export_triplet( 'sha224', \&sha224, \&sha224_hex, \&sha224_base64 ),
		_export_triplet( 'sha256', \&sha256, \&sha256_hex, \&sha256_base64 ),
		_export_triplet( 'sha384', \&sha384, \&sha384_hex, \&sha384_base64 ),
		_export_triplet( 'sha512', \&sha512, \&sha512_hex, \&sha512_base64 ),
		_export_hmac_triplet(
			'hmac_sha1',
			\&hmac_sha1,
			\&hmac_sha1_hex,
			\&hmac_sha1_base64,
		),
		_export_hmac_triplet(
			'hmac_sha224',
			\&hmac_sha224,
			\&hmac_sha224_hex,
			\&hmac_sha224_base64,
		),
		_export_hmac_triplet(
			'hmac_sha256',
			\&hmac_sha256,
			\&hmac_sha256_hex,
			\&hmac_sha256_base64,
		),
		_export_hmac_triplet(
			'hmac_sha384',
			\&hmac_sha384,
			\&hmac_sha384_hex,
			\&hmac_sha384_base64,
		),
		_export_hmac_triplet(
			'hmac_sha512',
			\&hmac_sha512,
			\&hmac_sha512_hex,
			\&hmac_sha512_base64,
		),
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::DigestSHA - std/digest/sha bindings.

=head1 DESCRIPTION

Implements C<std/digest/sha> and exports C<sha1>,
C<sha1_hex>, C<sha1_b64>, C<sha224>, C<sha224_hex>,
C<sha224_b64>, C<sha256>, C<sha256_hex>, C<sha256_b64>,
C<sha384>, C<sha384_hex>, C<sha384_b64>, C<sha512>,
C<sha512_hex>, C<sha512_b64>, C<hmac_sha1>,
C<hmac_sha1_hex>, C<hmac_sha1_b64>, C<hmac_sha224>,
C<hmac_sha224_hex>, C<hmac_sha224_b64>, C<hmac_sha256>,
C<hmac_sha256_hex>, C<hmac_sha256_b64>, C<hmac_sha384>,
C<hmac_sha384_hex>, C<hmac_sha384_b64>, C<hmac_sha512>,
C<hmac_sha512_hex>, and C<hmac_sha512_b64>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::DigestSHA >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

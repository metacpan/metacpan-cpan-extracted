package Zuzu::Module::DigestMD5;

use utf8;

our $VERSION = '0.001000';

use Digest::MD5 qw(
	md5
	md5_base64
	md5_hex
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
	my ( $value, $label ) = @_;

	return if blessed( $value )
		and $value->isa( 'Zuzu::Value::BinaryString' );

	my $type = _type_name( $value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects BinaryString, got $type",
		file => '<std/digest/md5>',
		line => 0,
	);
}

sub _md5 {
	my ( $value ) = @_;

	_assert_binary( $value, 'md5' );

	my $digest = md5( $value->bytes );
	return Zuzu::Value::BinaryString->new( bytes => $digest );
}

sub _md5_hex {
	my ( $value ) = @_;

	_assert_binary( $value, 'md5_hex' );

	return md5_hex( $value->bytes );
}

sub _md5_b64 {
	my ( $value ) = @_;

	_assert_binary( $value, 'md5_b64' );

	return md5_base64( $value->bytes );
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $md5_fn = native_function(
		name => 'md5',
		native => sub {
			my ( $value ) = @_;
			return _md5( $value );
		},
	);

	my $md5_hex_fn = native_function(
		name => 'md5_hex',
		native => sub {
			my ( $value ) = @_;
			return _md5_hex( $value );
		},
	);

	my $md5_b64_fn = native_function(
		name => 'md5_b64',
		native => sub {
			my ( $value ) = @_;
			return _md5_b64( $value );
		},
	);

	return {
		md5 => $md5_fn,
		md5_hex => $md5_hex_fn,
		md5_b64 => $md5_b64_fn,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::DigestMD5 - std/digest/md5 bindings.

=head1 DESCRIPTION

Implements C<std/digest/md5> and exports C<md5>,
C<md5_hex>, and C<md5_b64>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::DigestMD5 >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

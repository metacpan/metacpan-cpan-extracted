package Zuzu::Module::Base64;

use utf8;

our $VERSION = '0.007001';

use MIME::Base64 qw( decode_base64 encode_base64 );
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
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');
	return 'String';
}

sub _assert_binary {
	my ( $value, $label ) = @_;

	return if blessed($value) and $value->isa('Zuzu::Value::BinaryString');

	my $type = _type_name( $value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects BinaryString, got $type",
		file => '<std/string/base64>',
		line => 0,
	);
}

sub _assert_string {
	my ( $value, $label ) = @_;

	return if not blessed($value);
	return if not $value->isa('Zuzu::Value::BinaryString');

	my $type = _type_name( $value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects String, got $type",
		file => '<std/string/base64>',
		line => 0,
	);
}

sub _encode {
	my ( $value ) = @_;

	_assert_binary( $value, 'encode' );

	return encode_base64( $value->bytes, '' );
}

sub _decode {
	my ( $value ) = @_;

	_assert_string( $value, 'decode' );

	my $decoded = decode_base64( defined $value ? "$value" : '' );
	return Zuzu::Value::BinaryString->new( bytes => $decoded );
}

sub _encode_urlsafe {
	my ( $value ) = @_;

	my $encoded = _encode( $value );
	$encoded =~ tr/\+\//\-_/;
	$encoded =~ s/=+\z//;
	return $encoded;
}

sub _decode_urlsafe {
	my ( $value ) = @_;

	_assert_string( $value, 'decode_urlsafe' );

	my $text = defined $value ? "$value" : '';
	$text =~ tr/\-_/\+\//;
	my $mod = length($text) % 4;
	if ( $mod != 0 ) {
		$text .= '=' x ( 4 - $mod );
	}
	return _decode($text);
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $encode_fn = native_function(
		name => 'encode',
		native => sub {
			my ( $value ) = @_;
			return _encode($value);
		},
	);

	my $decode_fn = native_function(
		name => 'decode',
		native => sub {
			my ( $value ) = @_;
			return _decode($value);
		},
	);

	my $encode_urlsafe_fn = native_function(
		name => 'encode_urlsafe',
		native => sub {
			my ( $value ) = @_;
			return _encode_urlsafe($value);
		},
	);

	my $decode_urlsafe_fn = native_function(
		name => 'decode_urlsafe',
		native => sub {
			my ( $value ) = @_;
			return _decode_urlsafe($value);
		},
	);

	return {
		encode => $encode_fn,
		decode => $decode_fn,
		encode_urlsafe => $encode_urlsafe_fn,
		decode_urlsafe => $decode_urlsafe_fn,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Base64 - std/string/base64 bindings.

=head1 DESCRIPTION

Implements C<std/string/base64> and exports C<encode>,
C<decode>, C<encode_urlsafe>, and C<decode_urlsafe>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Base64 >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

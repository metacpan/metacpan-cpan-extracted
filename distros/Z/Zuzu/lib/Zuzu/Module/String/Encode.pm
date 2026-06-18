package Zuzu::Module::String::Encode;

use utf8;

our $VERSION = '0.005000';

use Encode ();
use Scalar::Util qw( blessed );

use Zuzu::Util::NativeHelpers qw(
	native_function
);
use Zuzu::Error;
use Zuzu::Value::BinaryString;

# std/string/encode: character-encoding conversions between String and
# BinaryString. UTF-16 and UTF-32 encode to big-endian without a BOM (the
# deterministic canonical form shared by all runtimes); decode honours a
# leading BOM and otherwise assumes big-endian.

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if not defined $value;
	return 'BinaryString'
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');
	return 'String';
}

sub _die {
	my ( $message ) = @_;

	die Zuzu::Error->new_runtime(
		message => $message,
		file => '<std/string/encode>',
		line => 0,
	);
}

sub _canonical_encoding {
	my ( $name ) = @_;

	my $upper = uc( defined $name ? "$name" : 'UTF-8' );
	$upper =~ s/\s+//g;
	return 'utf8'      if $upper eq 'UTF-8' or $upper eq 'UTF8';
	return 'utf16'     if $upper eq 'UTF-16' or $upper eq 'UTF16' or $upper eq 'UTF-16BE';
	return 'utf32'     if $upper eq 'UTF-32' or $upper eq 'UTF32' or $upper eq 'UTF-32BE';
	return 'latin1'    if $upper eq 'ISO-8859-1' or $upper eq 'ISO8859-1'
		or $upper eq 'LATIN-1' or $upper eq 'LATIN1' or $upper eq 'LATIN';
	return undef;
}

sub _encode {
	my ( $text, $encoding ) = @_;

	_die( 'TypeException: encode expects String, got ' . _type_name( $text ) )
		if blessed($text) or ref($text) or not defined $text;

	my $canonical = _canonical_encoding( $encoding );
	my $bytes;
	if ( defined $canonical and $canonical eq 'utf8' ) {
		$bytes = Encode::encode( 'UTF-8', "$text", Encode::FB_CROAK );
	}
	elsif ( defined $canonical and $canonical eq 'utf16' ) {
		$bytes = Encode::encode( 'UTF-16BE', "$text", Encode::FB_CROAK );
	}
	elsif ( defined $canonical and $canonical eq 'utf32' ) {
		$bytes = Encode::encode( 'UTF-32BE', "$text", Encode::FB_CROAK );
	}
	elsif ( defined $canonical and $canonical eq 'latin1' ) {
		for my $ch ( split //, "$text" ) {
			_die( sprintf(
				'Character U+%04X cannot be encoded as ISO-8859-1',
				ord($ch),
			) ) if ord($ch) > 0xFF;
		}
		$bytes = Encode::encode( 'ISO-8859-1', "$text", Encode::FB_CROAK );
	}
	else {
		# Practical extras: anything Encode knows about.
		my $codec = Encode::find_encoding( defined $encoding ? "$encoding" : '' );
		_die( 'Unsupported encoding: ' . ( defined $encoding ? $encoding : '' ) )
			if not $codec;
		$bytes = eval { $codec->encode( "$text", Encode::FB_CROAK ) };
		_die( 'Cannot encode text as ' . $encoding . ': ' . ( $@ // 'unknown error' ) )
			if not defined $bytes;
	}

	return Zuzu::Value::BinaryString->new( bytes => $bytes );
}

sub _decode {
	my ( $binary, $encoding ) = @_;

	_die( 'TypeException: decode expects BinaryString, got ' . _type_name( $binary ) )
		if not( blessed($binary) and $binary->isa('Zuzu::Value::BinaryString') );

	my $bytes = $binary->bytes // '';
	my $canonical = _canonical_encoding( $encoding );
	my $text;
	if ( defined $canonical and $canonical eq 'utf8' ) {
		$text = eval { Encode::decode( 'UTF-8', $bytes, Encode::FB_CROAK ) };
		_die( 'Invalid UTF-8 in BinaryString' ) if not defined $text;
	}
	elsif ( defined $canonical and $canonical eq 'utf16' ) {
		my $codec_name = 'UTF-16BE';
		if ( $bytes =~ s/\A\xFE\xFF// ) {
			$codec_name = 'UTF-16BE';
		}
		elsif ( $bytes =~ s/\A\xFF\xFE// ) {
			$codec_name = 'UTF-16LE';
		}
		_die( 'UTF-16 input length must be a multiple of 2 bytes' )
			if length($bytes) % 2;
		$text = eval { Encode::decode( $codec_name, $bytes, Encode::FB_CROAK ) };
		_die( 'Invalid UTF-16 in BinaryString' ) if not defined $text;
	}
	elsif ( defined $canonical and $canonical eq 'utf32' ) {
		my $codec_name = 'UTF-32BE';
		if ( $bytes =~ s/\A\x00\x00\xFE\xFF// ) {
			$codec_name = 'UTF-32BE';
		}
		elsif ( $bytes =~ s/\A\xFF\xFE\x00\x00// ) {
			$codec_name = 'UTF-32LE';
		}
		_die( 'UTF-32 input length must be a multiple of 4 bytes' )
			if length($bytes) % 4;
		$text = eval { Encode::decode( $codec_name, $bytes, Encode::FB_CROAK ) };
		_die( 'Invalid UTF-32 in BinaryString' ) if not defined $text;
	}
	elsif ( defined $canonical and $canonical eq 'latin1' ) {
		$text = Encode::decode( 'ISO-8859-1', $bytes, Encode::FB_CROAK );
	}
	else {
		my $codec = Encode::find_encoding( defined $encoding ? "$encoding" : '' );
		_die( 'Unsupported encoding: ' . ( defined $encoding ? $encoding : '' ) )
			if not $codec;
		$text = eval { $codec->decode( $bytes, Encode::FB_CROAK ) };
		_die( 'Cannot decode bytes as ' . $encoding . ': ' . ( $@ // 'unknown error' ) )
			if not defined $text;
	}

	return $text;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $encode_fn = native_function(
		name => 'encode',
		native => sub {
			my ( $text, $encoding ) = @_;
			return _encode( $text, defined $encoding ? $encoding : 'UTF-8' );
		},
	);

	my $decode_fn = native_function(
		name => 'decode',
		native => sub {
			my ( $binary, $encoding ) = @_;
			return _decode( $binary, defined $encoding ? $encoding : 'UTF-8' );
		},
	);

	return {
		encode => $encode_fn,
		decode => $decode_fn,
		ENCODING_UTF8  => 'UTF-8',
		ENCODING_UTF16 => 'UTF-16',
		ENCODING_UTF32 => 'UTF-32',
		ENCODING_LATIN => 'ISO-8859-1',
	};
}

1;

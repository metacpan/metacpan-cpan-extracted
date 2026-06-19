package Zuzu::Module::Secure;

use utf8;

our $VERSION = '0.006000';

use Crypt::AuthEnc::GCM qw(
	gcm_decrypt_verify
	gcm_encrypt_authenticate
);
use Crypt::AuthEnc::ChaCha20Poly1305 qw(
	chacha20poly1305_decrypt_verify
	chacha20poly1305_encrypt_authenticate
);
use Crypt::KeyDerivation qw(
	argon2_pbkdf
	pbkdf2
	scrypt_pbkdf
);
use Crypt::PK::Ed25519;
use Crypt::PK::ECC;
use Crypt::PK::X25519;
use Crypt::OpenSSL::PKCS12;
use Crypt::OpenSSL::X509;
use Crypt::URandom qw( urandom );
use Digest::SHA qw( hmac_sha256 sha256 sha384 sha512 );
use Encode qw( encode_utf8 );
use MIME::Base64 qw( decode_base64 encode_base64 );
use Net::SSLeay ();
use DateTime::Lite ();

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
);
use Zuzu::Value::Array;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Boolean;
use Zuzu::Value::Dict;
use Scalar::Util qw( blessed looks_like_number );

my @BASE64URL = split //,
	'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
my $HOST = 'perl';
my %RANDOM_CAPABILITIES = map { $_ => 1 } qw( bytes token int );
my %PASSWORD_HASH_CAPABILITIES = map { $_ => 1 } qw(
	argon2id
	crypt
	pbkdf2-sha256
	scrypt
);
my %KDF_CAPABILITIES = map { $_ => 1 } qw( hkdf-sha256 );
my %CIPHER_CAPABILITIES = map { $_ => 1 } qw(
	aes-128-gcm
	aes-192-gcm
	aes-256-gcm
	chacha20-poly1305
);
my %KEY_AGREEMENT_CAPABILITIES = map { $_ => 1 } qw( x25519 );
my %CERTIFICATE_CAPABILITIES = map { $_ => 1 } qw(
	parse-x509
	parse-x509-der
	fingerprint-sha256
	fingerprint-sha384
	fingerprint-sha512
	public-key
	verify-chain
);
my %CERTIFICATE_TIME_MONTH = (
	Jan => 1,
	Feb => 2,
	Mar => 3,
	Apr => 4,
	May => 5,
	Jun => 6,
	Jul => 7,
	Aug => 8,
	Sep => 9,
	Oct => 10,
	Nov => 11,
	Dec => 12,
);
my %TLS_IDENTITY_CAPABILITIES = map { $_ => 1 } qw( pem pkcs12 );
my %SIGNING_CAPABILITIES = map { $_ => 1 } qw(
	ed25519
	ecdsa-p256-sha256
	ecdsa-p384-sha384
	ecdsa-p521-sha512
);
my %SIGNING_ALGORITHMS = (
	'ed25519' => {
		type => 'ed25519',
		private_length => 32,
		public_length => 32,
	},
	'ecdsa-p256-sha256' => {
		type => 'ecdsa',
		curve => 'prime256v1',
		hash => 'SHA256',
		private_length => 32,
		public_length => 65,
	},
	'ecdsa-p384-sha384' => {
		type => 'ecdsa',
		curve => 'secp384r1',
		hash => 'SHA384',
		private_length => 48,
		public_length => 97,
	},
	'ecdsa-p521-sha512' => {
		type => 'ecdsa',
		curve => 'secp521r1',
		hash => 'SHA512',
		private_length => 66,
		public_length => 133,
	},
);
my $DEFAULT_PASSWORD_HASH_ALGORITHM = 'pbkdf2-sha256';
my $MAX_SAFE_INT = 9007199254740992;
my $RANDOM_INT_SPACE = 72057594037927936;
my $HKDF_SHA256_HASH_LENGTH = 32;
my $HKDF_SHA256_MAX_LENGTH = 255 * $HKDF_SHA256_HASH_LENGTH;
my %CIPHER_ALGORITHMS = (
	'aes-128-gcm' => {
		key_length => 16,
		nonce_length => 12,
		tag_length => 16,
		gcm_cipher => 'AES',
	},
	'aes-192-gcm' => {
		key_length => 24,
		nonce_length => 12,
		tag_length => 16,
		gcm_cipher => 'AES',
	},
	'aes-256-gcm' => {
		key_length => 32,
		nonce_length => 12,
		tag_length => 16,
		gcm_cipher => 'AES',
	},
	'chacha20-poly1305' => {
		key_length => 32,
		nonce_length => 12,
		tag_length => 16,
	},
);
my $PASSWORD_HASH_SALT_LENGTH = 16;
my $PASSWORD_HASH_LENGTH = 32;
my $PBKDF2_SHA256_ITERATIONS = 600_000;
my $ARGON2ID_MEMORY = 19_456;
my $ARGON2ID_ITERATIONS = 2;
my $ARGON2ID_PARALLELISM = 1;
my $SCRYPT_LOG_N = 17;
my $SCRYPT_R = 8;
my $SCRYPT_P = 1;

sub _true {
	return Zuzu::Value::Boolean->new( value => 1 );
}

sub _false {
	return Zuzu::Value::Boolean->new( value => 0 );
}

sub _empty_array {
	return Zuzu::Value::Array->new( items => [] );
}

sub _array {
	return Zuzu::Value::Array->new( items => [ @_ ] );
}

sub _error {
	my ( $message ) = @_;

	die Zuzu::Error->new_runtime(
		message => $message,
		file => '<std/secure>',
		line => 0,
	);
}

sub _capabilities {
	return Zuzu::Value::Dict->new(
		map => {
			host => $HOST,
			random => _true(),
			password_hash => _array(
				sort keys %PASSWORD_HASH_CAPABILITIES,
			),
			kdf => _array( sort keys %KDF_CAPABILITIES ),
			cipher => _array( sort keys %CIPHER_CAPABILITIES ),
			key_agreement => _array(
				sort keys %KEY_AGREEMENT_CAPABILITIES,
			),
			signing => _array( sort keys %SIGNING_CAPABILITIES ),
			certificate => _array( sort keys %CERTIFICATE_CAPABILITIES ),
			tls_identity => _array( sort keys %TLS_IDENTITY_CAPABILITIES ),
			async_required => Zuzu::Value::Dict->new(
				map => {
					cipher => _false(),
					kdf => _false(),
					password_hash => _false(),
					signing => _false(),
					key_agreement => _false(),
				},
			),
		},
	);
}

sub _capability_part {
	my ( $value ) = @_;

	return defined $value ? "$value" : '';
}

sub _has_capability {
	my ( $area, $name ) = @_;

	$area = _capability_part($area);
	$name = _capability_part($name);

	return 1 if $area eq 'random' and $RANDOM_CAPABILITIES{$name};
	return 1
		if $area eq 'password_hash'
			and $PASSWORD_HASH_CAPABILITIES{$name};
	return 1 if $area eq 'kdf' and $KDF_CAPABILITIES{$name};
	return 1 if $area eq 'cipher' and $CIPHER_CAPABILITIES{$name};
	return 1
		if $area eq 'key_agreement'
			and $KEY_AGREEMENT_CAPABILITIES{$name};
	return 1 if $area eq 'signing' and $SIGNING_CAPABILITIES{$name};
	return 1
		if $area eq 'certificate'
			and $CERTIFICATE_CAPABILITIES{$name};
	return 1
		if $area eq 'tls_identity'
			and $TLS_IDENTITY_CAPABILITIES{$name};
	return 0;
}

sub _require_capability {
	my ( $area, $name ) = @_;

	$area = _capability_part($area);
	$name = _capability_part($name);

	return _true() if _has_capability( $area, $name );

	_error(
		"Secure capability '$area/$name' is not available on host '$HOST'",
	);
}

sub _non_negative_integer {
	my ( $value, $label ) = @_;

	_error( "$label expects a non-negative integer" )
		if not defined $value or not looks_like_number($value);

	my $number = 0 + ( defined $value ? $value : 0 );
	_error( "$label expects a non-negative integer" )
		if $number < 0 or $number != int($number);

	return int($number);
}

sub _positive_integer {
	my ( $value, $label ) = @_;

	_error( "$label expects a positive integer" )
		if not defined $value or not looks_like_number($value);

	my $number = 0 + ( defined $value ? $value : 0 );
	_error( "$label expects a positive integer" )
		if $number <= 0 or $number != int($number);
	_error( "$label maximum is too large" )
		if $number > $MAX_SAFE_INT;

	return int($number);
}

sub _hkdf_length {
	my ( $value, $label ) = @_;

	_error( "$label expects length between 0 and $HKDF_SHA256_MAX_LENGTH" )
		if not defined $value or not looks_like_number($value);

	my $number = 0 + ( defined $value ? $value : 0 );
	_error( "$label expects length between 0 and $HKDF_SHA256_MAX_LENGTH" )
		if $number < 0 or $number != int($number);
	_error( "$label expects length between 0 and $HKDF_SHA256_MAX_LENGTH" )
		if $number > $HKDF_SHA256_MAX_LENGTH;

	return int($number);
}

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if not defined $value;
	return 'BinaryString'
		if blessed($value)
			and $value->isa( 'Zuzu::Value::BinaryString' );
	return 'Dict'
		if blessed($value)
			and $value->isa( 'Zuzu::Value::Dict' );
	return 'Array'
		if blessed($value)
			and $value->isa( 'Zuzu::Value::Array' );
	return 'String';
}

sub _binary_bytes {
	my ( $value, $label, $arg_name ) = @_;

	$arg_name //= 'BinaryString';

	return $value->bytes
		if blessed($value)
			and $value->isa( 'Zuzu::Value::BinaryString' );

	_error( 'TypeException: '
		. "$label expects $arg_name, got "
		. _type_name($value) );
}

sub _optional_binary_bytes {
	my ( $value, $label, $arg_name ) = @_;

	return '' if not defined $value;
	return _binary_bytes( $value, $label, $arg_name );
}

sub _dict_map {
	my ( $value, $label, $arg_name ) = @_;

	$arg_name //= 'Dict';

	return $value->map
		if blessed($value)
			and $value->isa( 'Zuzu::Value::Dict' );

	_error( 'TypeException: '
		. "$label expects $arg_name, got "
		. _type_name($value) );
}

sub _optional_dict_map {
	my ( $value, $label, $arg_name ) = @_;

	return {} if not defined $value;
	return _dict_map( $value, $label, $arg_name );
}

sub _optional_password_text {
	my ( $value, $label, $arg_name ) = @_;

	return '' if not defined $value;
	return _string_arg( $value, $label, $arg_name );
}

sub _cipher_algorithm {
	my ( $value, $label ) = @_;

	$value = 'aes-256-gcm' if not defined $value;
	_error( "$label cipher algorithm '$value' is not available" )
		if not $CIPHER_CAPABILITIES{"$value"};

	return "$value";
}

sub _cipher_options {
	my ( $value, $label ) = @_;

	my $options = _optional_dict_map( $value, $label, 'Dict options' );
	my $algorithm = _cipher_algorithm(
		$options->{algorithm},
		$label,
	) if defined $options->{algorithm};
	my $aad = _optional_binary_bytes(
		$options->{aad},
		$label,
		'BinaryString aad',
	);

	return ( $algorithm // 'aes-256-gcm', $aad, defined $options->{algorithm} );
}

sub _cipher_meta {
	my ( $algorithm, $label ) = @_;

	$algorithm = _cipher_algorithm( $algorithm, $label );
	return $CIPHER_ALGORITHMS{$algorithm};
}

sub _cipher_key {
	my ( $value, $label, $meta ) = @_;

	my $key = _binary_bytes( $value, $label, 'BinaryString key' );
	_error( "$label expects a $meta->{key_length}-byte key" )
		if length($key) != $meta->{key_length};

	return $key;
}

sub _envelope_bytes {
	my ( $map, $field, $label, $length ) = @_;

	my $bytes = _binary_bytes(
		$map->{$field},
		$label,
		"BinaryString envelope.$field",
	);
	_error( "$label expects envelope.$field to be $length bytes" )
		if defined $length and length($bytes) != $length;

	return $bytes;
}

sub _cipher_envelope {
	my ( $value, $label ) = @_;

	my $map = _dict_map( $value, $label, 'Dict envelope' );
	_error( "$label expects envelope.version 1" )
		if not defined $map->{version} or $map->{version} != 1;
	my $algorithm = _cipher_algorithm( $map->{algorithm}, $label );
	my $meta = _cipher_meta( $algorithm, $label );

	return (
		$algorithm,
		_envelope_bytes(
			$map,
			'nonce',
			$label,
			$meta->{nonce_length},
		),
		_envelope_bytes( $map, 'ciphertext', $label, undef ),
		_envelope_bytes( $map, 'tag', $label, $meta->{tag_length} ),
	);
}

sub _cipher_envelope_value {
	my ( $algorithm, $nonce, $ciphertext, $tag ) = @_;

	return Zuzu::Value::Dict->new(
		map => {
			version => 1,
			algorithm => $algorithm,
			nonce => Zuzu::Value::BinaryString->new( bytes => $nonce ),
			ciphertext => Zuzu::Value::BinaryString->new(
				bytes => $ciphertext,
			),
			tag => Zuzu::Value::BinaryString->new( bytes => $tag ),
		},
	);
}

sub _cipher_generate_key {
	my ( $algorithm ) = @_;

	my $meta = _cipher_meta( $algorithm, 'Cipher.generate_key' );
	return _random_bytes( $meta->{key_length} );
}

sub _cipher_encrypt {
	my ( $plaintext, $key, $options ) = @_;

	my $label = 'Cipher.encrypt';
	my $bytes = _binary_bytes( $plaintext, $label, 'BinaryString plaintext' );
	my ( $algorithm, $aad ) = _cipher_options( $options, $label );
	my $meta = _cipher_meta( $algorithm, $label );
	$key = _cipher_key( $key, $label, $meta );
	my $nonce = urandom( $meta->{nonce_length} );
	my ( $ciphertext, $tag );
	if ( exists $meta->{gcm_cipher} ) {
		( $ciphertext, $tag ) = gcm_encrypt_authenticate(
			$meta->{gcm_cipher},
			$key,
			$nonce,
			$aad,
			$bytes,
		);
	}
	elsif ( $algorithm eq 'chacha20-poly1305' ) {
		( $ciphertext, $tag ) = chacha20poly1305_encrypt_authenticate(
			$key,
			$nonce,
			$aad,
			$bytes,
		);
	}

	return _cipher_envelope_value( $algorithm, $nonce, $ciphertext, $tag );
}

sub _cipher_decrypt {
	my ( $envelope, $key, $options ) = @_;

	my $label = 'Cipher.decrypt';
	my ( $algorithm, $nonce, $ciphertext, $tag ) = _cipher_envelope(
		$envelope,
		$label,
	);
	my ( $option_algorithm, $aad, $algorithm_supplied ) =
		_cipher_options( $options, $label );
	_error( "$label options.algorithm does not match envelope.algorithm" )
		if $algorithm_supplied and $option_algorithm ne $algorithm;
	my $meta = _cipher_meta( $algorithm, $label );
	$key = _cipher_key( $key, $label, $meta );
	my $plaintext;
	if ( exists $meta->{gcm_cipher} ) {
		$plaintext = gcm_decrypt_verify(
			$meta->{gcm_cipher},
			$key,
			$nonce,
			$aad,
			$ciphertext,
			$tag,
		);
	}
	elsif ( $algorithm eq 'chacha20-poly1305' ) {
		$plaintext = chacha20poly1305_decrypt_verify(
			$key,
			$nonce,
			$aad,
			$ciphertext,
			$tag,
		);
	}
	_error( 'Cipher.decrypt authentication failed' )
		if not defined $plaintext;

	return Zuzu::Value::BinaryString->new( bytes => $plaintext );
}

sub _string_arg {
	my ( $value, $label, $arg_name ) = @_;

	$arg_name //= 'String';
	_error( 'TypeException: '
		. "$label expects $arg_name, got "
		. _type_name($value) )
		if not defined $value or blessed($value);

	return encode_utf8("$value");
}

sub _option_string {
	my ( $options, $key, $default ) = @_;

	return $default if not defined $options->{$key};
	return "$options->{$key}";
}

sub _option_positive_integer {
	my ( $options, $key, $default, $label ) = @_;

	return $default if not defined $options->{$key};
	return _positive_integer( $options->{$key}, "$label option '$key'" );
}

sub _password_hash_algorithm {
	my ( $options, $label ) = @_;

	my $algorithm = _option_string(
		$options,
		'algorithm',
		$DEFAULT_PASSWORD_HASH_ALGORITHM,
	);
	_error( "$label password hash algorithm '$algorithm' is not available" )
		if not $PASSWORD_HASH_CAPABILITIES{$algorithm};

	return $algorithm;
}

sub _base64url_decode {
	my ( $text ) = @_;

	return undef if not defined $text or $text =~ /[^A-Za-z0-9_-]/;
	my $b64 = $text;
	$b64 =~ tr/-_/+\//;
	$b64 .= '=' x ( ( 4 - length($b64) % 4 ) % 4 );

	my $bytes = eval { decode_base64($b64) };
	return $@ ? undef : $bytes;
}

sub _base64_nopad {
	my ( $bytes ) = @_;

	my $out = encode_base64( $bytes, '' );
	$out =~ s/=+\z//;
	return $out;
}

sub _base64_nopad_decode {
	my ( $text ) = @_;

	return undef if not defined $text or $text =~ /[^A-Za-z0-9+\/]/;
	my $b64 = $text . ( '=' x ( ( 4 - length($text) % 4 ) % 4 ) );
	my $bytes = eval { decode_base64($b64) };
	return $@ ? undef : $bytes;
}

sub _constant_time_eq {
	my ( $left, $right ) = @_;

	return 0 if not defined $left or not defined $right;
	return 0 if length($left) != length($right);
	my $diff = 0;
	for my $i ( 0 .. length($left) - 1 ) {
		$diff |= ord( substr( $left, $i, 1 ) )
			^ ord( substr( $right, $i, 1 ) );
	}
	return $diff == 0;
}

sub _pbkdf2_options {
	my ( $options, $label ) = @_;

	return (
		_option_positive_integer(
			$options,
			'iterations',
			$PBKDF2_SHA256_ITERATIONS,
			$label,
		),
		_option_positive_integer(
			$options,
			'length',
			$PASSWORD_HASH_LENGTH,
			$label,
		),
	);
}

sub _argon2id_options {
	my ( $options, $label ) = @_;

	return (
		_option_positive_integer(
			$options,
			'memory',
			$ARGON2ID_MEMORY,
			$label,
		),
		_option_positive_integer(
			$options,
			'iterations',
			$ARGON2ID_ITERATIONS,
			$label,
		),
		_option_positive_integer(
			$options,
			'parallelism',
			$ARGON2ID_PARALLELISM,
			$label,
		),
		_option_positive_integer(
			$options,
			'length',
			$PASSWORD_HASH_LENGTH,
			$label,
		),
	);
}

sub _scrypt_options {
	my ( $options, $label ) = @_;

	my $log_n = _option_positive_integer(
		$options,
		'log_n',
		$SCRYPT_LOG_N,
		$label,
	);
	my $n = _option_positive_integer(
		$options,
		'cost',
		1 << $log_n,
		$label,
	);
	_error( "$label option 'cost' must be a power of two" )
		if $n < 2 or ( $n & ( $n - 1 ) ) != 0;
	$log_n = 0;
	my $tmp = $n;
	while ( $tmp > 1 ) {
		$tmp >>= 1;
		$log_n++;
	}

	return (
		$log_n,
		$n,
		_option_positive_integer( $options, 'r', $SCRYPT_R, $label ),
		_option_positive_integer( $options, 'p', $SCRYPT_P, $label ),
		_option_positive_integer(
			$options,
			'length',
			$PASSWORD_HASH_LENGTH,
			$label,
		),
	);
}

sub _parse_pdkv {
	my ( $text ) = @_;

	my %out;
	for my $part ( split /,/, $text ) {
		my ( $key, $value ) = split /=/, $part, 2;
		return undef if not defined $key or not defined $value;
		$out{$key} = $value;
	}
	return \%out;
}

sub _parse_password_hash {
	my ( $encoded ) = @_;

	return { algorithm => 'crypt', encoded => $encoded }
		if defined $encoded
			and (
				$encoded =~ /^\$[156]\$/
				or $encoded =~ /^\$2[aby]\$/
			);

	if (
		defined $encoded
		and $encoded =~ m{
			\A
			\$zuzu-pbkdf2-sha256
			\$v=1
			\$([^\$]+)
			\$([^\$]+)
			\$([^\$]+)
			\z
		}x
	) {
		my ( $param_text, $salt_text, $hash_text ) = ( $1, $2, $3 );
		my $params = _parse_pdkv($param_text) // return undef;
		return undef
			if not defined $params->{i}
				or not defined $params->{l}
				or $params->{i} !~ /^\d+\z/
				or $params->{l} !~ /^\d+\z/;
		my $salt = _base64url_decode($salt_text);
		my $hash = _base64url_decode($hash_text);
		return undef if not defined $salt or not defined $hash;
		return {
			algorithm => 'pbkdf2-sha256',
			iterations => int( $params->{i} ),
			length => int( $params->{l} ),
			salt => $salt,
			hash => $hash,
		};
	}

	if (
		defined $encoded
		and $encoded =~ m{
			\A
			\$argon2id
			\$v=19
			\$([^\$]+)
			\$([^\$]+)
			\$([^\$]+)
			\z
		}x
	) {
		my ( $param_text, $salt_text, $hash_text ) = ( $1, $2, $3 );
		my $params = _parse_pdkv($param_text) // return undef;
		return undef
			if not defined $params->{m}
				or not defined $params->{t}
				or not defined $params->{p}
				or $params->{m} !~ /^\d+\z/
				or $params->{t} !~ /^\d+\z/
				or $params->{p} !~ /^\d+\z/;
		my $salt = _base64_nopad_decode($salt_text);
		my $hash = _base64_nopad_decode($hash_text);
		return undef if not defined $salt or not defined $hash;
		return {
			algorithm => 'argon2id',
			memory => int( $params->{m} ),
			iterations => int( $params->{t} ),
			parallelism => int( $params->{p} ),
			length => length($hash),
			salt => $salt,
			hash => $hash,
		};
	}

	if (
		defined $encoded
		and $encoded =~ m{
			\A
			\$scrypt
			\$([^\$]+)
			\$([^\$]+)
			\$([^\$]+)
			\z
		}x
	) {
		my ( $param_text, $salt_text, $hash_text ) = ( $1, $2, $3 );
		my $params = _parse_pdkv($param_text) // return undef;
		return undef
			if not defined $params->{ln}
				or not defined $params->{r}
				or not defined $params->{p}
				or not defined $params->{l}
				or $params->{ln} !~ /^\d+\z/
				or $params->{r} !~ /^\d+\z/
				or $params->{p} !~ /^\d+\z/
				or $params->{l} !~ /^\d+\z/;
		my $salt = _base64url_decode($salt_text);
		my $hash = _base64url_decode($hash_text);
		return undef if not defined $salt or not defined $hash;
		return {
			algorithm => 'scrypt',
			log_n => int( $params->{ln} ),
			r => int( $params->{r} ),
			p => int( $params->{p} ),
			length => int( $params->{l} ),
			salt => $salt,
			hash => $hash,
		};
	}

	return undef;
}

sub _password_hash_derive_bytes {
	my ( $password, $algorithm, $salt, $options, $label ) = @_;

	if ( $algorithm eq 'pbkdf2-sha256' ) {
		my ( $iterations, $length ) = _pbkdf2_options( $options, $label );
		return pbkdf2( $password, $salt, $iterations, 'SHA256', $length );
	}
	if ( $algorithm eq 'argon2id' ) {
		my ( $memory, $iterations, $parallelism, $length )
			= _argon2id_options( $options, $label );
		return argon2_pbkdf(
			'argon2id',
			$password,
			$salt,
			$iterations,
			$memory,
			$parallelism,
			$length,
		);
	}
	if ( $algorithm eq 'scrypt' ) {
		my ( undef, $n, $r, $p, $length ) = _scrypt_options(
			$options,
			$label,
		);
		return scrypt_pbkdf( $password, $salt, $n, $r, $p, $length );
	}

	_error( "$label does not support algorithm '$algorithm' for key derivation" );
}

sub _password_hash {
	my ( $password, $options_value ) = @_;

	my $label = 'PasswordHash.hash';
	$password = _string_arg( $password, $label, 'String password' );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $algorithm = _password_hash_algorithm( $options, $label );

	if ( $algorithm eq 'crypt' ) {
		my $salt = _base64_nopad( urandom(12) );
		$salt =~ tr|+/|./|;
		$salt = substr( $salt, 0, 16 );
		return crypt( $password, "\$6\$rounds=5000\$$salt\$" );
	}

	my $salt = exists $options->{salt}
		? _binary_bytes( $options->{salt}, $label, 'BinaryString salt' )
		: urandom($PASSWORD_HASH_SALT_LENGTH);
	my $hash = _password_hash_derive_bytes(
		$password,
		$algorithm,
		$salt,
		$options,
		$label,
	);

	if ( $algorithm eq 'pbkdf2-sha256' ) {
		my ( $iterations, $length ) = _pbkdf2_options( $options, $label );
		return join '$',
			'',
			'zuzu-pbkdf2-sha256',
			'v=1',
			"i=$iterations,l=$length",
			_base64url($salt),
			_base64url($hash);
	}
	if ( $algorithm eq 'argon2id' ) {
		my ( $memory, $iterations, $parallelism ) = _argon2id_options(
			$options,
			$label,
		);
		return join '$',
			'',
			'argon2id',
			'v=19',
			"m=$memory,t=$iterations,p=$parallelism",
			_base64_nopad($salt),
			_base64_nopad($hash);
	}
	if ( $algorithm eq 'scrypt' ) {
		my ( $log_n, undef, $r, $p, $length ) = _scrypt_options(
			$options,
			$label,
		);
		return join '$',
			'',
			'scrypt',
			"ln=$log_n,r=$r,p=$p,l=$length",
			_base64url($salt),
			_base64url($hash);
	}

	_error( "$label password hash algorithm '$algorithm' is not available" );
}

sub _password_hash_verify {
	my ( $password, $encoded ) = @_;

	my $label = 'PasswordHash.verify';
	$password = _string_arg( $password, $label, 'String password' );
	$encoded = _string_arg( $encoded, $label, 'String encoded_hash' );
	my $parsed = _parse_password_hash($encoded);
	return _false() if not defined $parsed;
	return _false()
		if not $PASSWORD_HASH_CAPABILITIES{ $parsed->{algorithm} };

	if ( $parsed->{algorithm} eq 'crypt' ) {
		my $candidate = crypt( $password, $encoded );
		return defined $candidate && _constant_time_eq( $candidate, $encoded )
			? _true()
			: _false();
	}

	my %options = %{ $parsed };
	my $hash = eval {
		_password_hash_derive_bytes(
			$password,
			$parsed->{algorithm},
			$parsed->{salt},
			\%options,
			$label,
		);
	};
	return _false() if $@;
	return _constant_time_eq( $hash, $parsed->{hash} ) ? _true() : _false();
}

sub _password_hash_needs_rehash {
	my ( $encoded, $options_value ) = @_;

	my $label = 'PasswordHash.needs_rehash';
	$encoded = _string_arg( $encoded, $label, 'String encoded_hash' );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $target = _password_hash_algorithm( $options, $label );
	my $parsed = _parse_password_hash($encoded);
	return _true() if not defined $parsed;
	return _true() if $parsed->{algorithm} ne $target;
	return _true() if $parsed->{algorithm} eq 'crypt';

	if ( $target eq 'pbkdf2-sha256' ) {
		my ( $iterations, $length ) = _pbkdf2_options( $options, $label );
		return $parsed->{iterations} >= $iterations
			&& $parsed->{length} == $length
			? _false()
			: _true();
	}
	if ( $target eq 'argon2id' ) {
		my ( $memory, $iterations, $parallelism, $length )
			= _argon2id_options( $options, $label );
		return $parsed->{memory} >= $memory
			&& $parsed->{iterations} >= $iterations
			&& $parsed->{parallelism} == $parallelism
			&& $parsed->{length} == $length
			? _false()
			: _true();
	}
	if ( $target eq 'scrypt' ) {
		my ( $log_n, undef, $r, $p, $length ) = _scrypt_options(
			$options,
			$label,
		);
		return $parsed->{log_n} >= $log_n
			&& $parsed->{r} == $r
			&& $parsed->{p} == $p
			&& $parsed->{length} == $length
			? _false()
			: _true();
	}

	return _true();
}

sub _password_hash_derive_key {
	my ( $password, $options_value ) = @_;

	my $label = 'PasswordHash.derive_key';
	$password = _string_arg( $password, $label, 'String password' );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $algorithm = _password_hash_algorithm( $options, $label );
	_error( "$label does not support crypt" ) if $algorithm eq 'crypt';
	_error( "$label expects BinaryString salt" )
		if not exists $options->{salt};
	my $salt = _binary_bytes( $options->{salt}, $label, 'BinaryString salt' );

	return Zuzu::Value::BinaryString->new(
		bytes => _password_hash_derive_bytes(
			$password,
			$algorithm,
			$salt,
			$options,
			$label,
		),
	);
}

sub _signing_algorithm {
	my ( $value, $label ) = @_;

	$value = 'ed25519' if not defined $value;
	_error( "$label signing algorithm '$value' is not available" )
		if not $SIGNING_ALGORITHMS{"$value"};

	return "$value";
}

sub _signing_options {
	my ( $options_value, $label ) = @_;

	return _optional_dict_map( $options_value, $label, 'Dict options' );
}

sub _signing_algorithm_option {
	my ( $options, $label ) = @_;

	return undef if not defined $options->{algorithm};
	return _signing_algorithm( $options->{algorithm}, $label );
}

sub _signing_meta {
	my ( $algorithm ) = @_;

	return $SIGNING_ALGORITHMS{$algorithm};
}

sub _ecdsa_algorithm_for_public_length {
	my ( $length, $label ) = @_;

	return 'ecdsa-p256-sha256' if $length == 65;
	return 'ecdsa-p384-sha384' if $length == 97;
	return 'ecdsa-p521-sha512' if $length == 133;
	_error( "$label expects a 32-byte Ed25519 key, "
		. '65-byte P-256 public key, 97-byte P-384 public key, '
		. 'or 133-byte P-521 public key' );
}

sub _ecdsa_algorithm_for_key {
	my ( $pk, $label ) = @_;

	my $public = eval { $pk->export_key_raw('public') };
	_error( "$label expects an Ed25519, P-256, or P-384 key" )
		if not defined $public;
	return 'ecdsa-p256-sha256' if length($public) == 65;
	return 'ecdsa-p384-sha384' if length($public) == 97;
	return 'ecdsa-p521-sha512' if length($public) == 133;
	_error( "$label expects a P-256, P-384, or P-521 key" );
}

sub _new_key_for_algorithm {
	my ( $algorithm ) = @_;

	my $meta = _signing_meta($algorithm);
	return Crypt::PK::Ed25519->new if $meta->{type} eq 'ed25519';
	return Crypt::PK::ECC->new if $meta->{type} eq 'ecdsa';
	_error( "Unsupported signing algorithm '$algorithm'" );
}

sub _key_format {
	my ( $options_value, $value, $label ) = @_;

	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	return "$options->{format}" if defined $options->{format};
	return blessed($value) && $value->isa( 'Zuzu::Value::BinaryString' )
		? 'raw'
		: 'pem';
}

sub _new_signing_key {
	my ( $class, $algorithm, $pk ) = @_;

	return native_object(
		class => $class,
		slots => {
			_algorithm => $algorithm,
			_pk => $pk,
		},
		const => {
			_algorithm => 1,
			_pk => 1,
		},
	);
}

sub _new_public_key {
	my ( $class, $algorithm, $pk ) = @_;

	return native_object(
		class => $class,
		slots => {
			_algorithm => $algorithm,
			_pk => $pk,
		},
		const => {
			_algorithm => 1,
			_pk => 1,
		},
	);
}

sub _new_key_agreement {
	my ( $class, $algorithm, $pk ) = @_;

	return native_object(
		class => $class,
		slots => {
			_algorithm => $algorithm,
			_pk => $pk,
		},
		const => {
			_algorithm => 1,
			_pk => 1,
		},
	);
}

sub _signing_private_state {
	my ( $self, $label ) = @_;

	_error( "TypeException: $label expects SigningKey" )
		if not blessed($self)
			or not $self->can('class')
			or $self->class->name ne 'SigningKey';
	return ( $self->slots->{_algorithm}, $self->slots->{_pk} );
}

sub _public_key_state {
	my ( $self, $label ) = @_;

	_error( "TypeException: $label expects PublicKey" )
		if not blessed($self)
			or not $self->can('class')
			or $self->class->name ne 'PublicKey';
	return ( $self->slots->{_algorithm}, $self->slots->{_pk} );
}

sub _signing_public_state {
	my ( $self, $label ) = @_;

	my ( $algorithm, $pk ) = _public_key_state( $self, $label );
	_error( "$label expects a signing public key" )
		if not $SIGNING_ALGORITHMS{$algorithm};
	return ( $algorithm, $pk );
}

sub _key_agreement_state {
	my ( $self, $label ) = @_;

	_error( "TypeException: $label expects KeyAgreement" )
		if not blessed($self)
			or not $self->can('class')
			or $self->class->name ne 'KeyAgreement';
	return ( $self->slots->{_algorithm}, $self->slots->{_pk} );
}

sub _key_agreement_algorithm {
	my ( $value, $label ) = @_;

	$value = 'x25519' if not defined $value;
	_error( "$label only supports x25519" )
		if "$value" ne 'x25519';

	return 'x25519';
}

sub _key_agreement_algorithm_option {
	my ( $options, $label ) = @_;

	return undef if not defined $options->{algorithm};
	return _key_agreement_algorithm( $options->{algorithm}, $label );
}

sub _x25519_private {
	my ( $bytes, $label ) = @_;

	_error( "$label expects a 32-byte raw private key" )
		if length($bytes) != 32;
	my $pk = Crypt::PK::X25519->new;
	_error( "$label expects a valid X25519 private key" )
		if not eval { $pk->import_key_raw( $bytes, 'private' ); 1 };
	return $pk;
}

sub _x25519_public {
	my ( $bytes, $label ) = @_;

	_error( "$label expects a 32-byte raw public key" )
		if length($bytes) != 32;
	my $pk = Crypt::PK::X25519->new;
	_error( "$label expects a valid X25519 public key" )
		if not eval { $pk->import_key_raw( $bytes, 'public' ); 1 };
	return $pk;
}

sub _key_agreement_generate {
	my ( $key_agreement_class, $algorithm ) = @_;

	my $label = 'KeyAgreement.generate';
	$algorithm = _key_agreement_algorithm( $algorithm, $label );
	my $pk = Crypt::PK::X25519->new;
	$pk->generate_key;
	return _new_key_agreement( $key_agreement_class, $algorithm, $pk );
}

sub _key_agreement_import_private {
	my ( $key_agreement_class, $key, $options ) = @_;

	my $label = 'KeyAgreement.import_private';
	my $opts = _optional_dict_map( $options, $label, 'Dict options' );
	my $format = _key_format( $options, $key, $label );
	_key_agreement_algorithm_option( $opts, $label );
	_error( "$label only supports raw format" )
		if $format ne 'raw';
	my $bytes = _binary_bytes( $key, $label, 'BinaryString key' );
	my $pk = _x25519_private( $bytes, $label );
	return _new_key_agreement( $key_agreement_class, 'x25519', $pk );
}

sub _key_agreement_import_public {
	my ( $public_key_class, $key, $options ) = @_;

	my $label = 'KeyAgreement.import_public';
	my $opts = _optional_dict_map( $options, $label, 'Dict options' );
	my $format = _key_format( $options, $key, $label );
	_key_agreement_algorithm_option( $opts, $label );
	_error( "$label only supports raw format" )
		if $format ne 'raw';
	my $bytes = _binary_bytes( $key, $label, 'BinaryString key' );
	my $pk = _x25519_public( $bytes, $label );
	return _new_public_key( $public_key_class, 'x25519', $pk );
}

sub _key_agreement_public_key {
	my ( $public_key_class, $self ) = @_;

	my ( $algorithm, $pk ) = _key_agreement_state(
		$self,
		'KeyAgreement.public_key',
	);
	my $public = _x25519_public(
		$pk->export_key_raw('public'),
		'KeyAgreement.public_key',
	);
	return _new_public_key( $public_key_class, $algorithm, $public );
}

sub _key_agreement_export_private {
	my ( $self, $options_value ) = @_;

	my $label = 'KeyAgreement.export_private';
	my ( undef, $pk ) = _key_agreement_state( $self, $label );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $format = defined $options->{format} ? "$options->{format}" : 'raw';
	_error( "$label only supports raw format" )
		if $format ne 'raw';
	return Zuzu::Value::BinaryString->new(
		bytes => $pk->export_key_raw('private'),
	);
}

sub _key_agreement_derive {
	my ( $self, $peer ) = @_;

	my $label = 'KeyAgreement.derive';
	my ( $algorithm, $pk ) = _key_agreement_state( $self, $label );
	my ( $peer_algorithm, $peer_pk ) = _public_key_state( $peer, $label );
	_error( "$label expects an x25519 public key" )
		if $algorithm ne 'x25519' or $peer_algorithm ne 'x25519';
	my $secret = eval { $pk->shared_secret($peer_pk) };
	_error( "$label failed" )
		if not defined $secret;
	return Zuzu::Value::BinaryString->new( bytes => $secret );
}

sub _pem_blocks {
	my ( $pem, $label ) = @_;

	my @blocks;
	while (
		$pem =~ m{
			-----BEGIN\ CERTIFICATE-----
			(.*?)
			-----END\ CERTIFICATE-----
		}xsg
	) {
		my $body = $1;
		$body =~ s/\s+//g;
		my $der = eval { decode_base64($body) };
		_error( "$label expects PEM certificate text" )
			if not defined $der or length($der) == 0;
		push @blocks, $der;
	}
	_error( "$label expects PEM certificate text" ) if not @blocks;
	return @blocks;
}

sub _der_to_pem_certificate {
	my ( $der ) = @_;

	my $encoded = encode_base64( $der, '' );
	$encoded =~ s/(.{1,64})/$1\n/g;
	return "-----BEGIN CERTIFICATE-----\n"
		. $encoded
		. "-----END CERTIFICATE-----\n";
}

sub _parse_x509_der {
	my ( $certificate_class, $der, $label ) = @_;

	my $x509 = eval {
		Crypt::OpenSSL::X509->new_from_string(
			$der,
			Crypt::OpenSSL::X509::FORMAT_ASN1(),
		);
	};
	_error( "$label expects DER X.509 certificate data" )
		if not defined $x509;

	return native_object(
		class => $certificate_class,
		slots => {
			_der => $der,
			_x509 => $x509,
		},
		const => {
			_der => 1,
			_x509 => 1,
		},
	);
}

sub _certificate_parse {
	my ( $certificate_class, $input ) = @_;

	my $label = 'Certificate.parse';
	if (
		blessed($input)
		and $input->isa( 'Zuzu::Value::BinaryString' )
	) {
		return _parse_x509_der( $certificate_class, $input->bytes, $label );
	}
	my $pem = _string_arg( $input, $label, 'String pem' );
	my ( $der ) = _pem_blocks( $pem, $label );
	return _parse_x509_der( $certificate_class, $der, $label );
}

sub _certificate_parse_chain {
	my ( $certificate_class, $input ) = @_;

	my $label = 'Certificate.parse_chain';
	if (
		blessed($input)
		and $input->isa( 'Zuzu::Value::BinaryString' )
	) {
		return _array(
			_parse_x509_der( $certificate_class, $input->bytes, $label ),
		);
	}
	my $pem = _string_arg( $input, $label, 'String pem' );
	return _array(
		map {
			_parse_x509_der( $certificate_class, $_, $label );
		} _pem_blocks( $pem, $label )
	);
}

sub _certificate_state {
	my ( $self, $label ) = @_;

	_error( "TypeException: $label expects Certificate" )
		if not blessed($self)
			or not $self->can('class')
			or $self->class->name ne 'Certificate';
	return ( $self->slots->{_der}, $self->slots->{_x509} );
}

sub _certificate_net_x509 {
	my ( $der, $label ) = @_;

	my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem() );
	_error( "$label failed to initialize certificate parser" )
		if not $bio;
	Net::SSLeay::BIO_write( $bio, $der );
	my $x509 = Net::SSLeay::d2i_X509_bio($bio);
	Net::SSLeay::BIO_free($bio);
	_error( "$label expects DER X.509 certificate data" )
		if not $x509;
	return $x509;
}

sub _certificate_array_arg {
	my ( $value, $label ) = @_;

	_error( "TypeException: $label expects Array chain, got "
		. _type_name($value) )
		if not blessed($value)
			or not $value->isa( 'Zuzu::Value::Array' );
	my @items = $value->resolved_items;
	_error( "$label expects a non-empty certificate chain" )
		if not @items;
	for my $item ( @items ) {
		_certificate_state( $item, $label );
	}
	return @items;
}

sub _certificate_root_ders {
	my ( $value, $label ) = @_;

	return () if not defined $value;
	if (
		blessed($value)
		and $value->can('class')
		and $value->class->name eq 'Certificate'
	) {
		my ( $der ) = _certificate_state( $value, $label );
		return ($der);
	}
	if (
		blessed($value)
		and $value->isa( 'Zuzu::Value::Array' )
	) {
		return map {
			_certificate_root_ders( $_, $label );
		} $value->resolved_items;
	}
	if ( not blessed($value) ) {
		return _pem_blocks( "$value", $label );
	}
	_error( 'TypeException: '
		. "$label expects roots to be Certificate, String PEM, Array, "
		. 'or null' );
}

sub _certificate_bool_option {
	my ( $value, $label, $name, $default ) = @_;

	return $default if not defined $value;
	return $value->value ? 1 : 0
		if blessed($value)
			and $value->isa( 'Zuzu::Value::Boolean' );
	_error( "TypeException: $label option '$name' expects Boolean" );
}

sub _certificate_time_option {
	my ( $value, $label ) = @_;

	return time if not defined $value;
	return int( 0 + $value )
		if not blessed($value) and looks_like_number($value);
	return int( 0 + $value->slots->{_epoch} )
		if blessed($value)
			and $value->can('class')
			and $value->class->name eq 'Time'
			and exists $value->slots->{_epoch};
	_error(
		"TypeException: $label option 'time' expects Time, Number, or null",
	);
}

sub _certificate_verify_reason {
	my ( $error ) = @_;

	$error = lc( $error // '' );
	return 'ok' if $error eq '' or $error eq 'ok';
	return 'hostname-mismatch' if $error =~ /hostname/;
	return 'not-yet-valid' if $error =~ /not yet valid/;
	return 'expired' if $error =~ /expired/;
	return 'untrusted-root'
		if $error =~ /unable to get/
			or $error =~ /self[- ]signed/
			or $error =~ /unable to verify/
			or $error =~ /issuer certificate/;
	return 'invalid-chain';
}

sub _certificate_verify_result {
	my ( %result ) = @_;

	return Zuzu::Value::Dict->new(
		map => {
			valid => $result{valid} ? _true() : _false(),
			reason => $result{reason},
			error => $result{error},
			hostname => $result{hostname},
			verified_at => $result{verified_at},
			chain_length => $result{chain_length},
		},
	);
}

sub _certificate_verify_chain {
	my ( $chain_value, $options_value ) = @_;

	my $label = 'Certificate.verify_chain';
	my @chain = _certificate_array_arg( $chain_value, $label );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $hostname = defined $options->{hostname}
		? _string_arg( $options->{hostname}, $label, 'String hostname' )
		: undef;
	my $verified_at = _certificate_time_option( $options->{time}, $label );
	my $use_system_roots = _certificate_bool_option(
		$options->{use_system_roots},
		$label,
		'use_system_roots',
		0,
	);
	my @root_ders = _certificate_root_ders( $options->{roots}, $label );

	my $ctx_owner;
	my $store;
	if ($use_system_roots) {
		$ctx_owner = Net::SSLeay::CTX_new();
		_error( "$label failed to initialize system trust store" )
			if not $ctx_owner;
		Net::SSLeay::CTX_set_default_verify_paths($ctx_owner);
		$store = Net::SSLeay::CTX_get_cert_store($ctx_owner);
	}
	else {
		$store = Net::SSLeay::X509_STORE_new();
	}
	_error( "$label failed to initialize trust store" )
		if not $store;

	my $param = Net::SSLeay::X509_VERIFY_PARAM_new();
	Net::SSLeay::X509_VERIFY_PARAM_set_time( $param, $verified_at );
	Net::SSLeay::X509_VERIFY_PARAM_set1_host( $param, $hostname )
		if defined $hostname;
	Net::SSLeay::X509_STORE_set1_param( $store, $param );

	my @owned_x509;
	for my $root_der ( @root_ders ) {
		my $root = _certificate_net_x509( $root_der, $label );
		push @owned_x509, $root;
		Net::SSLeay::X509_STORE_add_cert( $store, $root );
	}

	my ( $leaf_der ) = _certificate_state( $chain[0], $label );
	my $leaf = _certificate_net_x509( $leaf_der, $label );
	push @owned_x509, $leaf;
	my $extra_chain = Net::SSLeay::sk_X509_new_null();
	for my $cert ( @chain[ 1 .. $#chain ] ) {
		my ( $der ) = _certificate_state( $cert, $label );
		my $intermediate = _certificate_net_x509( $der, $label );
		push @owned_x509, $intermediate;
		Net::SSLeay::sk_X509_push(
			$extra_chain,
			$intermediate,
		);
	}

	my $store_ctx = Net::SSLeay::X509_STORE_CTX_new();
	Net::SSLeay::X509_STORE_CTX_init(
		$store_ctx,
		$store,
		$leaf,
		$extra_chain,
	);
	my $ok = Net::SSLeay::X509_verify_cert($store_ctx) ? 1 : 0;
	my $error_code = Net::SSLeay::X509_STORE_CTX_get_error($store_ctx);
	my $error = $ok
		? undef
		: Net::SSLeay::X509_verify_cert_error_string($error_code);
	my $reason = $ok ? 'ok' : _certificate_verify_reason($error);

	Net::SSLeay::X509_STORE_CTX_free($store_ctx);
	Net::SSLeay::sk_X509_free($extra_chain);
	Net::SSLeay::X509_free($_) for @owned_x509;
	Net::SSLeay::X509_VERIFY_PARAM_free($param);
	Net::SSLeay::CTX_free($ctx_owner) if $ctx_owner;
	Net::SSLeay::X509_STORE_free($store) if not $ctx_owner;

	return _certificate_verify_result(
		valid => $ok,
		reason => $reason,
		error => $error,
		hostname => $hostname,
		verified_at => $verified_at,
		chain_length => scalar @chain,
	);
}

sub _certificate_time {
	my ( $time_class, $self, $method, $value ) = @_;

	my ( $mon_name, $day, $hour, $minute, $second, $year, $zone )
		= $value =~ /\A([A-Z][a-z]{2})\s+(\d{1,2})\s+(\d\d):(\d\d):(\d\d)\s+(\d{4})\s+([A-Z]+)\z/;
	_error( "$method returned unrecognised certificate time '$value'" )
		if not defined $mon_name;
	_error( "$method returned unsupported certificate time zone '$zone'" )
		if $zone ne 'GMT' and $zone ne 'UTC';

	my $dt = DateTime::Lite->new(
		year => 0 + $year,
		month => $CERTIFICATE_TIME_MONTH{$mon_name},
		day => 0 + $day,
		hour => 0 + $hour,
		minute => 0 + $minute,
		second => 0 + $second,
		time_zone => '+0000',
	);
	_error( "$method returned invalid certificate time '$value'" )
		if not $dt;

	return native_object(
		class => $time_class,
		slots => {
			_epoch => $dt->epoch,
		},
		const => {
			_epoch => 1,
		},
	);
}

sub _certificate_fingerprint {
	my ( $self, $algorithm ) = @_;

	my ( $der ) = _certificate_state( $self, 'Certificate.fingerprint' );
	$algorithm = 'sha256' if not defined $algorithm;
	my %digests = (
		sha256 => \&sha256,
		sha384 => \&sha384,
		sha512 => \&sha512,
	);
	my $digest = $digests{ lc("$algorithm") };
	_error( "Certificate.fingerprint algorithm '$algorithm' is not available" )
		if not defined $digest;
	return Zuzu::Value::BinaryString->new( bytes => $digest->($der) );
}

sub _certificate_public_key {
	my ( $public_key_class, $self ) = @_;

	my ( undef, $x509 ) = _certificate_state( $self, 'Certificate.public_key' );
	my $pem = $x509->pubkey;
	my $curve = eval { $x509->curve } // '';
	my ( $algorithm, $pk );
	if ( ( $x509->pubkey_type // '' ) eq 'ec' ) {
		$algorithm = $curve eq 'prime256v1'
			? 'ecdsa-p256-sha256'
			: $curve eq 'secp384r1'
				? 'ecdsa-p384-sha384'
				: $curve eq 'secp521r1'
					? 'ecdsa-p521-sha512'
					: undef;
		_error(
			'Certificate.public_key certificate public-key algorithm '
			. 'is unsupported',
		) if not defined $algorithm;
		$pk = Crypt::PK::ECC->new;
		_error( 'Certificate.public_key failed to import public key' )
			if not eval { $pk->import_key( \$pem ); 1 };
	}
	elsif ( ( $x509->pubkey_type // '' ) eq 'ed25519' ) {
		$algorithm = 'ed25519';
		$pk = Crypt::PK::Ed25519->new;
		_error( 'Certificate.public_key failed to import public key' )
			if not eval { $pk->import_key( \$pem ); 1 };
	}
	else {
		_error(
			'Certificate.public_key certificate public-key algorithm '
			. 'is unsupported',
		);
	}
	return _new_public_key( $public_key_class, $algorithm, $pk );
}

sub _new_tls_identity {
	my ( $tls_identity_class, %slots ) = @_;

	return native_object(
		class => $tls_identity_class,
		slots => \%slots,
		const => {
			_cert_pem => 1,
			_key_pem => 1,
			_password => 1,
			_chain_pem => 1,
			_source => 1,
		},
	);
}

sub _tls_identity_state {
	my ( $self, $label ) = @_;

	_error( "TypeException: $label expects TlsIdentity" )
		if not blessed($self)
			or not $self->can('class')
			or $self->class->name ne 'TlsIdentity';
	return $self->slots;
}

sub _tls_identity_from_pem {
	my ( $tls_identity_class, $certificate_pem, $private_key_pem, $password ) = @_;

	my $label = 'TlsIdentity.from_pem';
	my $cert_pem = _string_arg(
		$certificate_pem,
		$label,
		'String certificate_pem',
	);
	my $key_pem = _string_arg(
		$private_key_pem,
		$label,
		'String private_key_pem',
	);
	my $pass = _optional_password_text( $password, $label, 'String password' );
	my @blocks = _pem_blocks( $cert_pem, $label );
	_parse_x509_der( native_class( name => 'Certificate' ), $blocks[0], $label );
	_error( "$label expects PEM private key text" )
		if $key_pem !~ /-----BEGIN [A-Z ]*PRIVATE KEY-----/;

	return _new_tls_identity(
		$tls_identity_class,
		_cert_pem => _der_to_pem_certificate( $blocks[0] ),
		_key_pem => $key_pem,
		_password => $pass,
		_chain_pem => join( '', map { _der_to_pem_certificate($_) } @blocks ),
		_source => 'pem',
	);
}

sub _tls_identity_from_pkcs12 {
	my ( $tls_identity_class, $bytes_value, $password ) = @_;

	my $label = 'TlsIdentity.from_pkcs12';
	my $bytes = _binary_bytes( $bytes_value, $label, 'BinaryString bytes' );
	my $pass = _optional_password_text( $password, $label, 'String password' );
	my $pkcs12 = eval { Crypt::OpenSSL::PKCS12->new_from_string($bytes) };
	_error( "$label expects PKCS#12 data" ) if not defined $pkcs12;
	_error( "$label failed to decrypt PKCS#12 data" )
		if not eval { $pkcs12->mac_ok($pass) };
	my $cert_pem = eval { $pkcs12->certificate($pass) };
	my $key_pem = eval { $pkcs12->private_key($pass) };
	_error( "$label expects PKCS#12 data with certificate and private key" )
		if not defined $cert_pem or not defined $key_pem;
	my $ca_pem = eval { $pkcs12->ca_certificate($pass) } // '';
	my @blocks = _pem_blocks( $cert_pem, $label );

	return _new_tls_identity(
		$tls_identity_class,
		_cert_pem => _der_to_pem_certificate( $blocks[0] ),
		_key_pem => $key_pem,
		_password => '',
		_chain_pem => $cert_pem . $ca_pem,
		_source => 'pkcs12',
	);
}

sub _tls_identity_certificate {
	my ( $certificate_class, $self ) = @_;

	my $state = _tls_identity_state( $self, 'TlsIdentity.certificate' );
	my ( $der ) = _pem_blocks( $state->{_cert_pem}, 'TlsIdentity.certificate' );
	return _parse_x509_der( $certificate_class, $der, 'TlsIdentity.certificate' );
}

sub _tls_identity_private_key {
	my ( $signing_key_class, $self ) = @_;

	my $state = _tls_identity_state( $self, 'TlsIdentity.private_key' );
	my $options = Zuzu::Value::Dict->new(
		map => {
			format => 'pem',
			password => $state->{_password},
		},
	);
	return eval {
		_signing_import_private(
			$signing_key_class,
			$state->{_key_pem},
			$options,
		);
	} // do {
		_error(
			'TlsIdentity.private_key only supports Ed25519, ECDSA P-256, '
			. 'ECDSA P-384, and ECDSA P-521 private keys',
		);
	};
}

sub _signing_generate {
	my ( $signing_key_class, $algorithm ) = @_;

	my $label = 'SigningKey.generate';
	$algorithm = _signing_algorithm( $algorithm, $label );
	my $meta = _signing_meta($algorithm);
	my $pk = _new_key_for_algorithm($algorithm);
	if ( $meta->{type} eq 'ed25519' ) {
		$pk->generate_key;
	}
	elsif ( $meta->{type} eq 'ecdsa' ) {
		$pk->generate_key( $meta->{curve} );
	}
	return _new_signing_key( $signing_key_class, $algorithm, $pk );
}

sub _signing_import_private {
	my ( $signing_key_class, $key, $options ) = @_;

	my $label = 'SigningKey.import_private';
	my $opts = _signing_options( $options, $label );
	my $format = _key_format( $options, $key, $label );
	my $algorithm = _signing_algorithm_option( $opts, $label );
	my $password = exists $opts->{password}
		? _optional_password_text(
			$opts->{password},
			$label,
			'String options.password',
		)
		: undef;
	my $pk;
	if ( $format eq 'raw' ) {
		my $bytes = _binary_bytes( $key, $label, 'BinaryString key' );
		$algorithm //= 'ed25519';
		my $meta = _signing_meta($algorithm);
		_error( "$label expects a $meta->{private_length}-byte raw private key" )
			if length($bytes) != $meta->{private_length};
		$pk = _new_key_for_algorithm($algorithm);
		if ( $meta->{type} eq 'ed25519' ) {
			$pk->import_key_raw( $bytes, 'private' );
		}
		else {
			$pk->import_key_raw( $bytes, $meta->{curve} );
		}
	}
	elsif ( $format eq 'pem' ) {
		my $pem = _string_arg( $key, $label, 'String key' );
		if ( defined $algorithm ) {
			$pk = _new_key_for_algorithm($algorithm);
			_error( "$label expects PEM private key" )
				if not eval { $pk->import_key( \$pem, $password ); 1 };
			if ( _signing_meta($algorithm)->{type} eq 'ecdsa' ) {
				my $actual = _ecdsa_algorithm_for_key( $pk, $label );
				_error( "$label PEM key algorithm does not match $algorithm" )
					if $actual ne $algorithm;
			}
		}
		else {
			$pk = Crypt::PK::Ed25519->new;
			if ( not eval { $pk->import_key( \$pem, $password ); 1 } ) {
				$pk = Crypt::PK::ECC->new;
				$pk->import_key( \$pem, $password );
				$algorithm = _ecdsa_algorithm_for_key( $pk, $label );
			}
			else {
				$algorithm = 'ed25519';
			}
		}
	}
	else {
		_error( "$label only supports raw and pem formats" );
	}

	return _new_signing_key( $signing_key_class, $algorithm, $pk );
}

sub _signing_import_public {
	my ( $public_key_class, $key, $options ) = @_;

	my $label = 'SigningKey.import_public';
	my $opts = _signing_options( $options, $label );
	my $format = _key_format( $options, $key, $label );
	my $algorithm = _signing_algorithm_option( $opts, $label );
	my $pk;
	if ( $format eq 'raw' ) {
		my $bytes = _binary_bytes( $key, $label, 'BinaryString key' );
		if ( defined $algorithm ) {
			my $meta = _signing_meta($algorithm);
			_error( "$label expects a $meta->{public_length}-byte raw public key" )
				if length($bytes) != $meta->{public_length};
		}
		else {
			$algorithm = length($bytes) == 32
				? 'ed25519'
				: _ecdsa_algorithm_for_public_length( length($bytes), $label );
		}
		my $meta = _signing_meta($algorithm);
		if ( $meta->{type} eq 'ecdsa' ) {
			_error( "$label expects an uncompressed EC public key" )
				if substr( $bytes, 0, 1 ) ne "\x04";
		}
		$pk = _new_key_for_algorithm($algorithm);
		if ( $meta->{type} eq 'ed25519' ) {
			$pk->import_key_raw( $bytes, 'public' );
		}
		else {
			$pk->import_key_raw( $bytes, $meta->{curve} );
		}
	}
	elsif ( $format eq 'pem' ) {
		my $pem = _string_arg( $key, $label, 'String key' );
		if ( defined $algorithm ) {
			$pk = _new_key_for_algorithm($algorithm);
			_error( "$label expects PEM public key" )
				if not eval { $pk->import_key( \$pem ); 1 };
			if ( _signing_meta($algorithm)->{type} eq 'ecdsa' ) {
				my $actual = _ecdsa_algorithm_for_key( $pk, $label );
				_error( "$label PEM key algorithm does not match $algorithm" )
					if $actual ne $algorithm;
			}
		}
		else {
			$pk = Crypt::PK::Ed25519->new;
			if ( not eval { $pk->import_key( \$pem ); 1 } ) {
				$pk = Crypt::PK::ECC->new;
				$pk->import_key( \$pem );
				$algorithm = _ecdsa_algorithm_for_key( $pk, $label );
			}
			else {
				$algorithm = 'ed25519';
			}
		}
	}
	else {
		_error( "$label only supports raw and pem formats" );
	}

	return _new_public_key( $public_key_class, $algorithm, $pk );
}

sub _signing_public_key {
	my ( $public_key_class, $self ) = @_;

	my ( $algorithm, $pk ) = _signing_private_state(
		$self,
		'SigningKey.public_key',
	);
	my $meta = _signing_meta($algorithm);
	my $public = _new_key_for_algorithm($algorithm);
	my $raw = $pk->export_key_raw('public');
	if ( $meta->{type} eq 'ed25519' ) {
		$public->import_key_raw( $raw, 'public' );
	}
	else {
		$public->import_key_raw( $raw, $meta->{curve} );
	}
	return _new_public_key( $public_key_class, $algorithm, $public );
}

sub _signing_sign {
	my ( $self, $message ) = @_;

	my ( $algorithm, $pk ) = _signing_private_state( $self, 'SigningKey.sign' );
	my $bytes = _binary_bytes(
		$message,
		'SigningKey.sign',
		'BinaryString message',
	);
	my $meta = _signing_meta($algorithm);
	my $signature = $meta->{type} eq 'ed25519'
		? $pk->sign_message($bytes)
		: $pk->sign_message( $bytes, $meta->{hash} );
	return Zuzu::Value::BinaryString->new(
		bytes => $signature,
	);
}

sub _signing_export_private {
	my ( $self, $options_value ) = @_;

	my $label = 'SigningKey.export_private';
	my ( $algorithm, $pk ) = _signing_private_state( $self, $label );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $format = defined $options->{format} ? "$options->{format}" : 'raw';
	return Zuzu::Value::BinaryString->new(
		bytes => $pk->export_key_raw('private'),
	) if $format eq 'raw';
	return $pk->export_key_pem('private') if $format eq 'pem';
	_error( "$label only supports raw and pem formats" );
}

sub _public_key_verify {
	my ( $self, $message, $signature ) = @_;

	my ( $algorithm, $pk ) = _signing_public_state( $self, 'PublicKey.verify' );
	my $message_bytes = _binary_bytes(
		$message,
		'PublicKey.verify',
		'BinaryString message',
	);
	my $signature_bytes = _binary_bytes(
		$signature,
		'PublicKey.verify',
		'BinaryString signature',
	);
	my $meta = _signing_meta($algorithm);
	return _false()
		if $meta->{type} eq 'ed25519' and length($signature_bytes) != 64;
	my $valid = $meta->{type} eq 'ed25519'
		? eval { $pk->verify_message( $signature_bytes, $message_bytes ) }
		: eval {
			$pk->verify_message(
				$signature_bytes,
				$message_bytes,
				$meta->{hash},
			);
		};
	return $valid
		? _true()
		: _false();
}

sub _public_key_export {
	my ( $self, $options_value ) = @_;

	my $label = 'PublicKey.export';
	my ( $algorithm, $pk ) = _public_key_state( $self, $label );
	my $options = _optional_dict_map( $options_value, $label, 'Dict options' );
	my $format = defined $options->{format} ? "$options->{format}" : 'raw';
	return Zuzu::Value::BinaryString->new(
		bytes => $pk->export_key_raw('public'),
	) if $format eq 'raw';
	_error( "$label only supports raw format for x25519 public keys" )
		if $algorithm eq 'x25519';
	return $pk->export_key_pem('public') if $format eq 'pem';
	_error( "$label only supports raw and pem formats" );
}

sub _hkdf_sha256 {
	my ( $input_key_material, $length, $salt, $info ) = @_;

	my $label = 'KeyDerivation.hkdf_sha256';
	my $ikm = _binary_bytes( $input_key_material, $label );
	$length = _hkdf_length( $length, $label );
	$salt = _optional_binary_bytes( $salt, $label, 'BinaryString salt' );
	$info = _optional_binary_bytes( $info, $label, 'BinaryString info' );

	return Zuzu::Value::BinaryString->new( bytes => '' ) if $length == 0;

	my $prk = hmac_sha256( $ikm, $salt );
	my $previous = '';
	my $out = '';
	my $counter = 1;
	while ( length($out) < $length ) {
		$previous = hmac_sha256(
			$previous . $info . chr($counter),
			$prk,
		);
		$out .= $previous;
		$counter++;
	}

	return Zuzu::Value::BinaryString->new(
		bytes => substr( $out, 0, $length ),
	);
}

sub _random_bytes {
	my ( $length ) = @_;

	return Zuzu::Value::BinaryString->new(
		bytes => urandom($length),
	);
}

sub _base64url {
	my ( $bytes ) = @_;

	my $out = '';
	my $i = 0;
	my $len = length($bytes);
	while ( $i < $len ) {
		my $b0 = ord( substr( $bytes, $i, 1 ) );
		my $b1 = $i + 1 < $len ? ord( substr( $bytes, $i + 1, 1 ) ) : 0;
		my $b2 = $i + 2 < $len ? ord( substr( $bytes, $i + 2, 1 ) ) : 0;
		my $triple = ( $b0 << 16 ) | ( $b1 << 8 ) | $b2;

		$out .= $BASE64URL[ ( $triple >> 18 ) & 0x3f ];
		$out .= $BASE64URL[ ( $triple >> 12 ) & 0x3f ];
		$out .= $BASE64URL[ ( $triple >> 6 ) & 0x3f ]
			if $i + 1 < $len;
		$out .= $BASE64URL[ $triple & 0x3f ]
			if $i + 2 < $len;

		$i += 3;
	}

	return $out;
}

sub _random_int {
	my ( $max ) = @_;

	return 0 if $max == 1;

	my $limit = $RANDOM_INT_SPACE - ( $RANDOM_INT_SPACE % $max );
	while (1) {
		my $value = unpack( 'Q>', "\0" . urandom(7) );
		return $value % $max if $value < $limit;
	}
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $secure_class = native_class(
		name => 'Secure',
		static_methods => {
			capabilities => native_function(
				name => 'capabilities',
				native => sub {
					return _capabilities();
				},
			),
			has => native_function(
				name => 'has',
				native => sub {
					my ( $self, $area, $name ) = @_;
					return _has_capability( $area, $name )
						? _true()
						: _false();
				},
			),
			require => native_function(
				name => 'require',
				native => sub {
					my ( $self, $area, $name ) = @_;
					return _require_capability( $area, $name );
				},
			),
		},
	);
	my $random_class = native_class(
		name => 'SecureRandom',
		static_methods => {
			bytes => native_function(
				name => 'bytes',
				native => sub {
					my ( $self, $length ) = @_;
					$length = _non_negative_integer(
						$length,
						'SecureRandom.bytes',
					);
					return _random_bytes($length);
				},
			),
			token => native_function(
				name => 'token',
				native => sub {
					my ( $self, $length ) = @_;
					$length = 32 if not defined $length;
					$length = _non_negative_integer(
						$length,
						'SecureRandom.token',
					);
					return _base64url( urandom($length) );
				},
			),
			int => native_function(
				name => 'int',
				native => sub {
					my ( $self, $max ) = @_;
					$max = _positive_integer(
						$max,
						'SecureRandom.int',
					);
					return _random_int($max);
				},
			),
		},
	);
	my $password_hash_class = native_class(
		name => 'PasswordHash',
		static_methods => {
			default_algorithm => native_function(
				name => 'default_algorithm',
				native => sub {
					return $DEFAULT_PASSWORD_HASH_ALGORITHM;
				},
			),
			hash => native_function(
				name => 'hash',
				native => sub {
					my ( $self, $password, $options ) = @_;
					return _password_hash( $password, $options );
				},
			),
			hash_async => native_function(
				name => 'hash_async',
				native => sub {
					my ( $self, $password, $options ) = @_;
					my $value = _password_hash( $password, $options );
					return $runtime->_new_task(
						name => 'PasswordHash.hash_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			verify => native_function(
				name => 'verify',
				native => sub {
					my ( $self, $password, $encoded ) = @_;
					return _password_hash_verify( $password, $encoded );
				},
			),
			verify_async => native_function(
				name => 'verify_async',
				native => sub {
					my ( $self, $password, $encoded ) = @_;
					my $value = _password_hash_verify(
						$password,
						$encoded,
					);
					return $runtime->_new_task(
						name => 'PasswordHash.verify_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			needs_rehash => native_function(
				name => 'needs_rehash',
				native => sub {
					my ( $self, $encoded, $options ) = @_;
					return _password_hash_needs_rehash(
						$encoded,
						$options,
					);
				},
			),
			derive_key => native_function(
				name => 'derive_key',
				native => sub {
					my ( $self, $password, $options ) = @_;
					return _password_hash_derive_key(
						$password,
						$options,
					);
				},
			),
			derive_key_async => native_function(
				name => 'derive_key_async',
				native => sub {
					my ( $self, $password, $options ) = @_;
					my $value = _password_hash_derive_key(
						$password,
						$options,
					);
					return $runtime->_new_task(
						name => 'PasswordHash.derive_key_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
		},
	);
	my $kdf_class = native_class(
		name => 'KeyDerivation',
		static_methods => {
			hkdf_sha256 => native_function(
				name => 'hkdf_sha256',
				native => sub {
					my ( $self, $ikm, $length, $salt, $info ) = @_;
					return _hkdf_sha256( $ikm, $length, $salt, $info );
				},
			),
			hkdf_sha256_async => native_function(
				name => 'hkdf_sha256_async',
				native => sub {
					my ( $self, $ikm, $length, $salt, $info ) = @_;
					my $value = _hkdf_sha256(
						$ikm,
						$length,
						$salt,
						$info,
					);
					return $runtime->_new_task(
						name => 'KeyDerivation.hkdf_sha256_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
		},
	);
	my $cipher_class = native_class(
		name => 'Cipher',
		static_methods => {
			generate_key => native_function(
				name => 'generate_key',
				native => sub {
					my ( $self, $algorithm ) = @_;
					return _cipher_generate_key($algorithm);
				},
			),
			encrypt => native_function(
				name => 'encrypt',
				native => sub {
					my ( $self, $plaintext, $key, $options ) = @_;
					return _cipher_encrypt( $plaintext, $key, $options );
				},
			),
			decrypt => native_function(
				name => 'decrypt',
				native => sub {
					my ( $self, $envelope, $key, $options ) = @_;
					return _cipher_decrypt( $envelope, $key, $options );
				},
			),
			encrypt_async => native_function(
				name => 'encrypt_async',
				native => sub {
					my ( $self, $plaintext, $key, $options ) = @_;
					my $value = _cipher_encrypt(
						$plaintext,
						$key,
						$options,
					);
					return $runtime->_new_task(
						name => 'Cipher.encrypt_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			decrypt_async => native_function(
				name => 'decrypt_async',
				native => sub {
					my ( $self, $envelope, $key, $options ) = @_;
					my $value = _cipher_decrypt(
						$envelope,
						$key,
						$options,
					);
					return $runtime->_new_task(
						name => 'Cipher.decrypt_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
		},
	);
	my $public_key_class = native_class(
		name => 'PublicKey',
		methods => {
			verify => native_function(
				name => 'verify',
				native => sub {
					my ( $self, $message, $signature ) = @_;
					return _public_key_verify(
						$self,
						$message,
						$signature,
					);
				},
			),
			verify_async => native_function(
				name => 'verify_async',
				native => sub {
					my ( $self, $message, $signature ) = @_;
					my $value = _public_key_verify(
						$self,
						$message,
						$signature,
					);
					return $runtime->_new_task(
						name => 'PublicKey.verify_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			export => native_function(
				name => 'export',
				native => sub {
					my ( $self, $options ) = @_;
					return _public_key_export( $self, $options );
				},
			),
		},
	);
	my $time_class = native_class(
		name => 'Time',
		methods => {
			epoch => native_function(
				name => 'epoch',
				native => sub {
					my ( $self ) = @_;
					return $self->slots->{_epoch};
				},
			),
		},
	);
	my $certificate_class;
	$certificate_class = native_class(
		name => 'Certificate',
		static_methods => {
			parse => native_function(
				name => 'parse',
				native => sub {
					my ( $self, $input ) = @_;
					return _certificate_parse(
						$certificate_class,
						$input,
					);
				},
			),
			parse_chain => native_function(
				name => 'parse_chain',
				native => sub {
					my ( $self, $input ) = @_;
					return _certificate_parse_chain(
						$certificate_class,
						$input,
					);
				},
			),
			verify_chain => native_function(
				name => 'verify_chain',
				native => sub {
					my ( $self, $chain, $options ) = @_;
					return _certificate_verify_chain(
						$chain,
						$options,
					);
				},
			),
		},
		methods => {
			subject => native_function(
				name => 'subject',
				native => sub {
					my ( $self ) = @_;
					my ( undef, $x509 ) = _certificate_state(
						$self,
						'Certificate.subject',
					);
					return $x509->subject;
				},
			),
			issuer => native_function(
				name => 'issuer',
				native => sub {
					my ( $self ) = @_;
					my ( undef, $x509 ) = _certificate_state(
						$self,
						'Certificate.issuer',
					);
					return $x509->issuer;
				},
			),
			serial_number => native_function(
				name => 'serial_number',
				native => sub {
					my ( $self ) = @_;
					my ( undef, $x509 ) = _certificate_state(
						$self,
						'Certificate.serial_number',
					);
					my $serial = uc( $x509->serial // '' );
					$serial =~ s/[^0-9A-F]//g;
					return $serial eq '' ? '00' : $serial;
				},
			),
			not_before => native_function(
				name => 'not_before',
				native => sub {
					my ( $self ) = @_;
					my ( undef, $x509 ) = _certificate_state(
						$self,
						'Certificate.not_before',
					);
					return _certificate_time(
						$time_class,
						$self,
						'not_before',
						$x509->notBefore,
					);
				},
			),
			not_after => native_function(
				name => 'not_after',
				native => sub {
					my ( $self ) = @_;
					my ( undef, $x509 ) = _certificate_state(
						$self,
						'Certificate.not_after',
					);
					return _certificate_time(
						$time_class,
						$self,
						'not_after',
						$x509->notAfter,
					);
				},
			),
			fingerprint => native_function(
				name => 'fingerprint',
				native => sub {
					my ( $self, $algorithm ) = @_;
					return _certificate_fingerprint(
						$self,
						$algorithm,
					);
				},
			),
			to_der => native_function(
				name => 'to_der',
				native => sub {
					my ( $self ) = @_;
					my ( $der ) = _certificate_state(
						$self,
						'Certificate.to_der',
					);
					return Zuzu::Value::BinaryString->new(
						bytes => $der,
					);
				},
			),
			to_pem => native_function(
				name => 'to_pem',
				native => sub {
					my ( $self ) = @_;
					my ( $der ) = _certificate_state(
						$self,
						'Certificate.to_pem',
					);
					return _der_to_pem_certificate($der);
				},
			),
			public_key => native_function(
				name => 'public_key',
				native => sub {
					my ( $self ) = @_;
					return _certificate_public_key(
						$public_key_class,
						$self,
					);
				},
			),
		},
	);
	my $key_agreement_class;
	$key_agreement_class = native_class(
		name => 'KeyAgreement',
		static_methods => {
			generate => native_function(
				name => 'generate',
				native => sub {
					my ( $self, $algorithm ) = @_;
					return _key_agreement_generate(
						$key_agreement_class,
						$algorithm,
					);
				},
			),
			generate_async => native_function(
				name => 'generate_async',
				native => sub {
					my ( $self, $algorithm ) = @_;
					my $value = _key_agreement_generate(
						$key_agreement_class,
						$algorithm,
					);
					return $runtime->_new_task(
						name => 'KeyAgreement.generate_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			import_private => native_function(
				name => 'import_private',
				native => sub {
					my ( $self, $key, $options ) = @_;
					return _key_agreement_import_private(
						$key_agreement_class,
						$key,
						$options,
					);
				},
			),
			import_private_async => native_function(
				name => 'import_private_async',
				native => sub {
					my ( $self, $key, $options ) = @_;
					my $value = _key_agreement_import_private(
						$key_agreement_class,
						$key,
						$options,
					);
					return $runtime->_new_task(
						name => 'KeyAgreement.import_private_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			import_public => native_function(
				name => 'import_public',
				native => sub {
					my ( $self, $key, $options ) = @_;
					return _key_agreement_import_public(
						$public_key_class,
						$key,
						$options,
					);
				},
			),
			import_public_async => native_function(
				name => 'import_public_async',
				native => sub {
					my ( $self, $key, $options ) = @_;
					my $value = _key_agreement_import_public(
						$public_key_class,
						$key,
						$options,
					);
					return $runtime->_new_task(
						name => 'KeyAgreement.import_public_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
		},
		methods => {
			public_key => native_function(
				name => 'public_key',
				native => sub {
					my ( $self ) = @_;
					return _key_agreement_public_key(
						$public_key_class,
						$self,
					);
				},
			),
			derive => native_function(
				name => 'derive',
				native => sub {
					my ( $self, $peer ) = @_;
					return _key_agreement_derive( $self, $peer );
				},
			),
			derive_async => native_function(
				name => 'derive_async',
				native => sub {
					my ( $self, $peer ) = @_;
					my $value = _key_agreement_derive( $self, $peer );
					return $runtime->_new_task(
						name => 'KeyAgreement.derive_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			export_private => native_function(
				name => 'export_private',
				native => sub {
					my ( $self, $options ) = @_;
					return _key_agreement_export_private(
						$self,
						$options,
					);
				},
			),
		},
	);
	my $signing_key_class;
	$signing_key_class = native_class(
		name => 'SigningKey',
		static_methods => {
			generate => native_function(
				name => 'generate',
				native => sub {
					my ( $self, $algorithm ) = @_;
					return _signing_generate(
						$signing_key_class,
						$algorithm,
					);
				},
			),
			generate_async => native_function(
				name => 'generate_async',
				native => sub {
					my ( $self, $algorithm ) = @_;
					my $value = _signing_generate(
						$signing_key_class,
						$algorithm,
					);
					return $runtime->_new_task(
						name => 'SigningKey.generate_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			import_private => native_function(
				name => 'import_private',
				native => sub {
					my ( $self, $key, $options ) = @_;
					return _signing_import_private(
						$signing_key_class,
						$key,
						$options,
					);
				},
			),
			import_private_async => native_function(
				name => 'import_private_async',
				native => sub {
					my ( $self, $key, $options ) = @_;
					my $value = _signing_import_private(
						$signing_key_class,
						$key,
						$options,
					);
					return $runtime->_new_task(
						name => 'SigningKey.import_private_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			import_public => native_function(
				name => 'import_public',
				native => sub {
					my ( $self, $key, $options ) = @_;
					return _signing_import_public(
						$public_key_class,
						$key,
						$options,
					);
				},
			),
			import_public_async => native_function(
				name => 'import_public_async',
				native => sub {
					my ( $self, $key, $options ) = @_;
					my $value = _signing_import_public(
						$public_key_class,
						$key,
						$options,
					);
					return $runtime->_new_task(
						name => 'SigningKey.import_public_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
		},
		methods => {
			public_key => native_function(
				name => 'public_key',
				native => sub {
					my ( $self ) = @_;
					return _signing_public_key(
						$public_key_class,
						$self,
					);
				},
			),
			sign => native_function(
				name => 'sign',
				native => sub {
					my ( $self, $message ) = @_;
					return _signing_sign( $self, $message );
				},
			),
			sign_async => native_function(
				name => 'sign_async',
				native => sub {
					my ( $self, $message ) = @_;
					my $value = _signing_sign( $self, $message );
					return $runtime->_new_task(
						name => 'SigningKey.sign_async',
						status => 'fulfilled',
						result => $value,
					);
				},
			),
			export_private => native_function(
				name => 'export_private',
				native => sub {
					my ( $self, $options ) = @_;
					return _signing_export_private(
						$self,
						$options,
					);
				},
			),
		},
	);
	my $tls_identity_class;
	$tls_identity_class = native_class(
		name => 'TlsIdentity',
		static_methods => {
			from_pem => native_function(
				name => 'from_pem',
				native => sub {
					my (
						$self,
						$certificate_pem,
						$private_key_pem,
						$password,
					) = @_;
					return _tls_identity_from_pem(
						$tls_identity_class,
						$certificate_pem,
						$private_key_pem,
						$password,
					);
				},
			),
			from_pkcs12 => native_function(
				name => 'from_pkcs12',
				native => sub {
					my ( $self, $bytes, $password ) = @_;
					return _tls_identity_from_pkcs12(
						$tls_identity_class,
						$bytes,
						$password,
					);
				},
			),
		},
		methods => {
			certificate => native_function(
				name => 'certificate',
				native => sub {
					my ( $self ) = @_;
					return _tls_identity_certificate(
						$certificate_class,
						$self,
					);
				},
			),
			private_key => native_function(
				name => 'private_key',
				native => sub {
					my ( $self ) = @_;
					return _tls_identity_private_key(
						$signing_key_class,
						$self,
					);
				},
			),
		},
	);

	return {
		Secure => $secure_class,
		SecureRandom => $random_class,
		PasswordHash => $password_hash_class,
		KeyDerivation => $kdf_class,
		Cipher => $cipher_class,
		KeyAgreement => $key_agreement_class,
		SigningKey => $signing_key_class,
		Certificate => $certificate_class,
		PrivateKey => native_class( name => 'PrivateKey' ),
		PublicKey => $public_key_class,
		SealedBox => native_class( name => 'SealedBox' ),
		TlsIdentity => $tls_identity_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Secure - std/secure bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the Phase 1 C<std/secure> runtime-supported module skeleton.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Secure >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

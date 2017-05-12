package WWW::LetsEncrypt::JWK;
$WWW::LetsEncrypt::JWK::VERSION = '0.002';
use strict;
use warnings;

use Carp qw(confess);

use JSON;
use Moose::Role;

has 'key_type' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has '_RefObj' => (
	is      => 'ro',
	isa     => 'Object',
);

requires 'generate_new';
requires 'load_cert';
requires 'load_parameters';
requires 'get_privatekey_string';
requires 'sign';
requires 'thumbprint';
requires '_get_public_key_components';

sub serialize_public_key {
	my ($self) = @_;
	my %jwk = $self->_get_public_key_components();
	$jwk{kty} = $self->key_type;

	return \%jwk;
}

1;

__END__

=pod

=head1 NAME

WWW::LetsEncrypt::JWK;

=head1 SYNOPSIS

use Moose;

extends qw(WWW::LetsEncrypt::JWK);



=head1 DESCRIPTION

This is a role that when used together with WWW::LetsEncrypt::JWA as parents
will create a JSON Web Key that implements all of the functions needed for
signing JSON Web Signature objects. Specifically, this role deals with storing
the key object and its parameters.

=head2 Attributes

'key_type' a scalar attribute necessary for holding what the key type may be.
The permitted key types should be either: ECDSA, RSA, or HMAC (as per the RFC
and our restriction).

'_RefObj' a private object attribute meant to hold the concrete implementation
of the key type. Eg: a Crypt::OpenSSL::RSA object is held here for JWK::RSA,
and it is used to perform signing (and all associated necessities, such as
padding).

=head2 Public Functions

=over 4

=item generate_new

This function, when implemented, should create a new JSON Web Key of a specific algorithm type.

Input

	$number - key_length
	$string - key id

Output

	JWK Object

=item get_privatekey_string

This function, when implemented, should return the PKCS#1 encoding of the private key.

Output

	Scalar string that is the PKCS#1 representation of the RSA private key.

=item load_cert

This function, when implemented, should accept a private key string as a parameter and return new JSON Web Key.

Input

	{
		private_key => $scalar string of the private key to use,
	}

Output

	JWK Object

=item load_parameters

This function, when implemented, should accept a private key as per the serialized parameters from JWK and return new JSON Web Key.

Input

	{
		parameters => \%hash_ref of parameters that are base64url encoded,
	}

Output

	JWK Object

=item serialize_public_key

Object method, with _get_public_key_components implemented, returns a valid serialization of a JWK's public key.

Input

	$self

Output

	\%hash_ref that is the public key components

=item sign

When implemented, the function takes a single parameter that is the digested value, and returns a signed string.

Input

	$scalar string of digested data.

Output

	$scalar string of signed digested data.

=item thumbprint

Object method that returns the rfc7638 JWK thumbprint for the key.

Output

	$scalar string that is the thumbprint of the key

=back

=head2 Private Functions

=over 4

=item _get_public_key_components

Abstract object function which should return a hash of public key parameters (see the RFC)

Input

	$self - Object Reference

Output

	%hash of the public key parameters

=back

=cut


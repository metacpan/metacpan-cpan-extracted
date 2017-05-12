package WWW::LetsEncrypt::JWS;
$WWW::LetsEncrypt::JWS::VERSION = '0.002';
use strict;
use warnings;

use Encode qw(encode_utf8);
use MIME::Base64 qw(encode_base64url);

use JSON;
use Moose;

has 'payload' => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { return {}; },
);

has 'headers' => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { return {}; },
);

has 'protected_headers' => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { return {}; },
);

has 'jwk' => (
	is       => 'rw',
	isa      => 'Object',
	required => 1,
);

sub serialize {
	my ($self) = @_;

	my $protected_headers_ref     = $self->protected_headers;
	$protected_headers_ref->{alg} = $self->jwk->alg;
	$protected_headers_ref->{jwk} = $self->jwk->serialize_public_key();

	my $serialized_p_header = _serialize_hash($protected_headers_ref);
	my $serialized_payload  = _serialize_hash($self->payload);
	my $protected_data      = "$serialized_p_header.$serialized_payload";
	my $signed_data         = encode_base64url($self->jwk->sign($protected_data));

	my $output = {
		payload   => $serialized_payload,
		protected => $serialized_p_header,
		signature => $signed_data,
	};

	# Empty headers are not allowed as per the RFC, not sure why this is a thing but it is.
	$output->{header} = $self->headers if %{$self->headers};

	return encode_json($output);
}

sub _serialize_hash {
	my ($hash_ref) = @_;
	return encode_base64url(encode_utf8(encode_json($hash_ref)));
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

WWW::LetsEncrypt::JWS

=head1 SYNOPSIS

use WWW::LetsEncrypt::JWS;
use WWW::LetsEncrypt::JWK;

my $JWK = WWW::LetsEncrypt::JWK->new(...);

my $JWS = WWW::LetsEncrypt::JWS->new({jwk => $JWK});

$JWS->payload({
	item1 => 'a',
});

IOFunction($JWS->serialize());

=head1 DESCRIPTION

A (mostly) implemented JSON Web Signature object as per the RFC specification.
This object's implementation follows the JWS RFC enough to meet the minimum
requirements for ACME, and deviates as ACME may require.

=head2 Attributes

'payload' a hashref attribute used to store the json payload that should be
communicated to the server.

'headers' a hashref attribute used to store any headers that should be included
in the JWS.

'protected_headers' a hashref attribute similar to headers, but are integrity
checked, should contain things like the nonce.

'jwk' a JWK object that will used to create a signature of all integrity
protected items (payload and protected headers). The public key will also be
included in the protected headers of the JWS serialized output.

=head2 Public Functions

=over 4

=item serialize

Object function that takes all of the set attributes and outputs a
flattened JSON Web Signature.

Input

	$self - Object Reference

Output

	scalar string that mostly conforms to the RFC

=back

=head2 Private Functions

=over 4

=item _serialize_hash

Internal helper function that performs the necessary encoding for the payload and protected-headers.

Input

	\%hash_ref

Output

	scalar string representing the necessary encoding for various JWS elements

=back

=cut


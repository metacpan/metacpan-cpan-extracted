package WWW::LetsEncrypt::JWK::RSA;
$WWW::LetsEncrypt::JWK::RSA::VERSION = '0.002';
use strict;
use warnings;

use Carp qw(confess);
use Digest::SHA;
use MIME::Base64 qw(encode_base64url decode_base64url);

use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::RSA;
use JSON;
use Moose;

with qw(WWW::LetsEncrypt::JWK WWW::LetsEncrypt::JWA);

sub generate_new {
	my ($key_length) = @_;

	confess 'Invalid key length' if $key_length < 2048 || $key_length > 4096;

	my $RSA = Crypt::OpenSSL::RSA->generate_key($key_length);
	return _new_from_object($RSA);
}

sub get_privatekey_string {
	my ($self) = @_;
	return $self->_RefObj->get_private_key_string();
}

sub load_cert {
	my ($args_ref) = @_;
	my $private_key = $args_ref->{private_key};
	my $alg         = $args_ref->{alg};

	confess 'Private Key must be provided' if !$private_key;

	my $RSA = Crypt::OpenSSL::RSA->new_private_key($private_key);
	confess 'Cannot load key.' if !$RSA;

	return _new_from_object($RSA, $alg);
}

sub load_parameters {
	my ($args_ref) = @_;
	my $parameters = $args_ref->{parameters};
	my $alg        = $args_ref->{alg};

	my @required_parameters = qw{n e d p q};

	for my $param (@required_parameters) {
		confess "Required parameter '$param' not found!" if !$parameters->{$param};
	}

	my @params;
	for my $parameter (@required_parameters) {
		my $decoded_string = decode_base64url($parameters->{$parameter});
		my $param = Crypt::OpenSSL::Bignum->new_from_bin($decoded_string);
		push @params, $param;
	}

	my $RSA = Crypt::OpenSSL::RSA->new_key_from_parameters(@params);
	confess "Could not load key." if !$RSA;
	return _new_from_object($RSA, $alg);
}

sub sign {
	my ($self, $message) = @_;
	$self->_set_hash;
	return $self->_RefObj->sign($message);
}

sub thumbprint {
	my ($self) = @_;

	# RFC requires the keys to be sorted lexically.
	my $JSON = JSON->new();
	$JSON->canonical(1);

	my %pubkey = $self->_get_public_key_components();
	$pubkey{kty} = 'RSA';

	my $hash_method = Digest::SHA->can($self->_hash);
	confess "Hashing method " . $self->_hash . " is not supported!" if !$hash_method;

	my $jsonified_sorted_pk   = $JSON->encode(\%pubkey);
	my $digested_jsonified_pk = $hash_method->($jsonified_sorted_pk);
	return encode_base64url($digested_jsonified_pk);
}

sub _get_public_key_components {
	my ($self) = @_;

	my %b64_pk;

	my ($n, $e) = map { $_->to_bin() } $self->_RefObj->get_key_parameters();

	$b64_pk{n} = encode_base64url($n);
	$b64_pk{e} = encode_base64url($e);

	return %b64_pk;
}

sub _new_from_object {
	my ($RSA, $alg) = @_;
	$alg ||= 'RS256';

	my $RefObj = $RSA;
	$RefObj->use_pkcs1_padding();

	return WWW::LetsEncrypt::JWK::RSA->new({
		key_type => 'RSA',
		use      => {enc => 1, sign => 1},
		alg      => $alg,
		_RefObj  => $RefObj,
	});
}

sub _set_hash {
	my ($self) = @_;
	my $hash = $self->_hash;
	my $hash_method = "use_${hash}_hash";
	$self->_RefObj->$hash_method;
	return 1;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

WWW::LetsEncrypt::JWK::RSA

=head1 SYNOPSIS

use WWW::LetsEncrypt::JWK::RSA

my $JWK = WWW::LetsEncrypt::JWK::RSA::generate_new(4096);

(see SYNOPSIS from JWK);

=head1 DESCRIPTION

This is a concrete implementation of JWK and JWA using RSA for signing.

=head2 Attributes

The following attributes are inherited:

from JWK: 'key_type', '_RefObj'

from JWA: 'alg'

'key_type' is automatically set to RSA.

_RefObj contains a Crypt::OpenSSL::RSA object, which is the concrete
implementation of RSA. This object takes care of padding and hashing during
signing.

=head2 Private Functions

=over 4

=item _new_from_object

Internal helper function that creates the new JWK::RSA object with the various
passed parameters from the public load_* or generate_new functions.

Input

	$RSA    - object that holds Crypt::OpenSSL::RSA
	$alg    - scalar string representing the algorithm that will be used
	          for signing

Output

	WWW::LetsEncrypt::JWK::RSA object

=back

=cut


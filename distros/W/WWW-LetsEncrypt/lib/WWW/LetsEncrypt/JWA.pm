package WWW::LetsEncrypt::JWA;
$WWW::LetsEncrypt::JWA::VERSION = '0.002';
use strict;
use warnings;

use Carp qw(confess);

use Moose::Role;
use Moose::Util::TypeConstraints;

has 'alg' => (
	is       => 'ro',
	isa      => enum([qw(RS256 RS384 RS512 ES256 ESA384 ES512)]),
	required => 1,
);


# '_hash' a private scalar attribute meant to hold the hashing algorithm
# that will be used when signing or generating the thumbprint.

has '_hash' => (
	is       => 'rw',
	isa      => 'Str',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build__hash'
);

requires 'sign';
requires '_set_hash';

sub _build__hash {
	my ($self) = @_;
	my ($hash) = $self->alg =~ m/(\d+)$/;
	return "sha$hash";
}

1;
__END__


=pod

=head1 NAME

WWW::LetsEncrypt::JWA

=head1 SYNOPSIS

use Moose;

with qw(WWW::LetsEncrypt::JWA ...)

sub sign {
	my ($self, $message) = @_;
	...
	return ...;
}

sub _set_hash {
	...
}

=head1 DESCRIPTION

This is a role that when used together with WWW::LetsEncrypt::JWK as parents
will create a JSON Web Key that implements all the functions needed for signing
JSON Web Signature objects.

=head2 Attributes

'alg' a scalar attribute meant to hold the algorithm that will be used for
signing, as defined in the JWA RFC.

Currently allowed algorithms:
ES256, ES384, ES512,
RS256, RS384, RS512,


=head2 Public Functions

=over 4

=item sign($message)

Abstract object function that takes an argument and signs it based off of the
internal configuration of the JWA subclass.

Input

	$self    - Object Reference
	$message - scalar string of what needs to be signed

Output

	scalar octets representing the signature of the message.

=back

=head2 Private Functions

=over 4

=item _set_hash($hash)

Abstract object function that takes a number argument, which is used to
determine which SHA2 algorithm will be used for hashing.

Implementers should permit values of (256, 384, 512). All other values should
throw an error.

Input

	$self - Object Reference
	$hash - numerical value

Output

	boolean if setting the value was successful

=item _verify_alg($alg)

Trigger function that is called after the 'alg' parameter has been set.
Assuming an accept algorithm was used, this function calls $self->_set_hash
with the SHA2 hashing algorithm selected.

=back

=cut


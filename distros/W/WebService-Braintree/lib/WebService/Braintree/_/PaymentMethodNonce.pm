# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::PaymentMethodNonce;
$WebService::Braintree::_::PaymentMethodNonce::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::PaymentMethodNonce

=head1 PURPOSE

This class represents a payment method nonce.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::BinData;
use WebService::Braintree::_::PaymentMethodNonceDetails;
use WebService::Braintree::_::ThreeDSecureInfo;

=head1 ATTRIBUTES

=cut

=head2 bin_data()

This returns the nonce's bin data. This will be an object of type
L<bin data|WebService::Braintree::_::BinData/>.

=cut

has bin_data => (
    is => 'ro',
    isa => 'WebService::Braintree::_::BinData',
    coerce => 1,
);

=head2 consumed()

This returns if this nonce has been consumed.

C<< is_consumed() >> is an alias for this attribute.

=cut

has consumed => (
    is => 'ro',
    alias => 'is_consumed',
);

=head2 default()

This returns if this nonce is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 description()

This returns the nonce's description.

=cut

has description => (
    is => 'ro',
);

=head2 details()

This returns the nonce's details. This will be an object of type
L<defaults|WebService::Braintree::_::PaymentMethodNonceDetails/>.

=cut

has details => (
    is => 'ro',
    isa => 'WebService::Braintree::_::PaymentMethodNonceDetails',
    coerce => 1,
);

=head2 is_locked()

This returns true if this nonce is locked.

=cut

has is_locked => (
    is => 'ro',
);

=head2 nonce()

This returns the nonce's nonce.

=cut

has nonce => (
    is => 'ro',
);

=head2 security_questions()

This returns the nonce's security questions.

=cut

has security_questions => (
    is => 'ro',
);

=head2 three_d_secure_info()

This returns the nonce's ThreeD secure info. This will be an object of type
L<ThreeD secure info|WebService::Braintree::_::ThreeDSecureInfo/>.

=cut

has three_d_secure_info => (
    is => 'ro',
    isa => 'WebService::Braintree::_::ThreeDSecureInfo|Undef',
    coerce => 1,
);

=head2 type()

This returns the nonce's type.

=cut

has type => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__

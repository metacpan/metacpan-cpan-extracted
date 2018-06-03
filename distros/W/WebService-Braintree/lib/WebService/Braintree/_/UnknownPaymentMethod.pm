# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::UnknownPaymentMethod;
$WebService::Braintree::_::UnknownPaymentMethod::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::UnknownPaymentMethod

=head1 PURPOSE

This class represents an unknown payment method.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.  Specifically,
this class will only be created if Braintree responds with a payment method this
SDK does not know how to handle.

Because this SDK does not know how to handle this, the class will have very
limited functionality relative to the other payment methods.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head2 customer_id()

This returns the account's customer's ID.

=cut

has customer_id => (
    is => 'ro',
);

=head2 default()

This returns if this account is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 token()

This returns the account's token.

=cut

has token => (
    is => 'ro',
);

# There is some code in the Ruby SDK that walks nested attributes.
# It's unclear if that code is needed here.
#     nested_attributes = attributes[attributes.keys.first]
#     set_instance_variables_from_hash(nested_attributes)

=head1 METHODS

=cut

=head2 image_url()

This returns the "unknown payment methods" image URL. This is a URL provided
by and hosted by Braintree.

=cut

sub image_url {
    "https://assets.braintreegateway.com/payment_method_logo/unknown.png";
}

__PACKAGE__->meta->make_immutable;

1;
__END__

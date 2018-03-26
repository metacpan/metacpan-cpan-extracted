# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorResult;
$WebService::Braintree::ErrorResult::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorResult

=head1 PURPOSE

This class represents a result from the Braintree API with one or more
validation errors.

=cut

use Moose;
use MooseX::Aliases;

use WebService::Braintree::ValidationErrorCollection;

=head1 METHODS

=cut

=head2 credit_card_verification()

This is an alias of L<verification()/verification()>.

=head2 errors()

This returns the L<collection/WebService::Braintree::ValidationErrorCollection>
of specfic validation errors associatd with this result.

=cut

has errors => (
    is => 'ro',
    isa => 'WebService::Braintree::ValidationErrorCollection',
    coerce => 1,
);

=head2 merchant_account()

This returns the L<merchant account/WebService::Braintree::_::MerchantAccount>
(if any) associated with this error.

=cut

has merchant_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount',
    coerce => 1,
);

=head2 message()

This returns the string from Braintree that describes the full error.

=cut

has message => (
    is => 'ro',
);

=head2 params()

TODO

=cut

has params => (
    is => 'ro',
);

=head2 response()

This is the actual response received from Braintree.

=cut

has response => (
    is => 'ro',
);

=head2 subscription()

This returns the L<subscription/WebService::Braintree::_::Subscription>
(if any) associated with this error.

=cut

has subscription => (
    is => 'ro',
    isa => 'WebService::Braintree::_::Subscription',
    coerce => 1,
);

=head2 transaction()

This returns the L<transaction/WebService::Braintree::_::Transaction>
(if any) associated with this error.

=cut

has transaction => (
    is => 'ro',
    isa => 'WebService::Braintree::_::Transaction',
    coerce => 1,
);

=head2 verification()

This returns the L<verification/WebService::Braintree::_::CreditCardVerification>
(if any) associated with this error.

=cut

has verification => (
    is => 'ro',
    isa => 'WebService::Braintree::_::CreditCardVerification',
    coerce => 1,
    alias => 'credit_card_verification',
);

=head2 is_success

This always returns false.

=cut

sub is_success { 0 }

__PACKAGE__->meta->make_immutable;

1;
__END__

# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::MerchantAccount;
$WebService::Braintree::_::MerchantAccount::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::MerchantAccount

=head1 PURPOSE

This class represents a merchant account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::MerchantAccount::BusinessDetails;
use WebService::Braintree::_::MerchantAccount::FundingDetails;
use WebService::Braintree::_::MerchantAccount::IndividualDetails;

=head1 ATTRIBUTES

=cut

=head2 business()

This returns the merchant account's business details. This will be an
object of type L<WebService::Braintree::_::MerchantAccount::BusinessDetails/>.

C<< business_details() >> is an alias for this attribute.

=cut

has business => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount::BusinessDetails',
    coerce => 1,
    alias => 'business_details',
);

=head2 currency_iso_code()

This is the currency ISO code for this merchant account.

=cut

has currency_iso_code => (
    is => 'ro',
);

=head2 default()

This returns true if this merchant account is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 funding()

This returns the merchant account's funding details. This will be an
object of type L<WebService::Braintree::_::MerchantAccount::FundingDetails/>.

C<< funding_details() >> is an alias for this attribute.

=cut

has funding => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount::FundingDetails',
    coerce => 1,
    alias => 'funding_details',
);

=head2 id()

This is the id for this merchant account.

=cut

has id => (
    is => 'ro',
);

=head2 individual()

This returns the merchant account's individual details. This will be an
object of type L<WebService::Braintree::_::MerchantAccount::IndividualDetails/>.

C<< individual_details() >> is an alias for this attribute.

=cut

has individual => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount::IndividualDetails',
    coerce => 1,
    alias => 'individual_details',
);

=head2 master_merchant_account()

This is the master merchant account (if any) for this merchant account. This will be an
object of type L<WebService::Braintree::_::MerchantAccount/>.

=cut

has master_merchant_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount',
    coerce => 1,
);

=head2 status()

This is the status for this merchant account.

=cut

has status => (
    is => 'ro',
);

=head2 sub_merchant_account()

This returns true if this merchant account is a sub-merchant account.

C<< is_sub_merchant_account() >> is an alias for this attribute.

=cut

has sub_merchant_account => (
    is => 'ro',
    alias => 'is_sub_merchant_account',
);

__PACKAGE__->meta->make_immutable;

1;
__END__

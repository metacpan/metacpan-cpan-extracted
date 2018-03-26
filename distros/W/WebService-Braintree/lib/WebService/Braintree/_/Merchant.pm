# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Merchant;
$WebService::Braintree::_::Merchant::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Merchant

=head1 PURPOSE

This class represents a merchant.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 company_name()

This is the company name for this merchant.

=cut

has company_name => (
    is => 'ro',
);

=head2 commercial_code_alpha2()

This is the commercial code (alpha2) for this merchant.

=cut

has commercial_code_alpha2 => (
    is => 'ro',
);

=head2 commercial_code_alpha2()

This is the commercial code (alpha3) for this merchant.

=cut

has commercial_code_alpha3 => (
    is => 'ro',
);

=head2 commercial_name()

This is the commercial name for this merchant.

=cut

has commercial_name => (
    is => 'ro',
);

=head2 email()

This is the email for this merchant.

=cut

has email => (
    is => 'ro',
);

=head2 id()

This is the ID for this merchant.

=cut

has id => (
    is => 'ro',
);

=head2 merchant_accounts()

This is an arrayref of L<merchant accounts|WebService::Braintree::_::MerchantAccount>
associated with this merchant.

=cut

has merchant_accounts => (
    is => 'ro',
    isa => 'ArrayRefOfMerchantAccount',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

1;
__END__

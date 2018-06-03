# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::IbanBankAccount;
$WebService::Braintree::_::IbanBankAccount::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::IbanBankAccount

=head1 PURPOSE

This class represents a IBAN bank account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 account_holder_name()

This is the account holder name for this IBAN bank account.

=cut

has account_holder_name => (
    is => 'ro',
);

=head2 bic()

This is the bic for this IBAN bank account.

=cut

has bic => (
    is => 'ro',
);

=head2 description()

This is the description for this IBAN bank account.

=cut

has description => (
    is => 'ro',
);

=head2 iban_account_number_last_4()

This is the IBAN account holder's last-4 for this IBAN bank account.

=cut

has iban_account_number_last_4 => (
    is => 'ro',
);

=head2 iban_country()

This is the country for this IBAN bank account.

=cut

has iban_country => (
    is => 'ro',
);

=head2 masked_iban()

This is the masked IBAN for this IBAN bank account.

=cut

has masked_iban => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__

# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::SettlementBatchSummaryRecord;
$WebService::Braintree::_::SettlementBatchSummaryRecord::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::SettlementBatchSummaryRecord

=head1 PURPOSE

This class represents a settlement batch summary record.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount_settled()

This is the amount settled for this settlement batch summary record.

=cut

has amount_settled => (
    is => 'ro',
);

=head2 card_type()

This is the card type for this settlement batch summary record.

=cut

has card_type => (
    is => 'ro',
);

=head2 count()

This is the count for this settlement batch summary record.

=cut

has count => (
    is => 'ro',
);

=head2 kind()

This is the kind for this settlement batch summary record.

=cut

has kind => (
    is => 'ro',
);

=head2 merchant_account_id()

This is the merchant account ID for this settlement batch summary record.

=cut

has merchant_account_id => (
    is => 'ro',
);

=head2 store_me()

This is the store_me for this settlement batch summary record.

=cut

has store_me => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__

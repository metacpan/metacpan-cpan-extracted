# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Dispute;
$WebService::Braintree::_::Dispute::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Dispute

=head1 PURPOSE

This class represents a dispute.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef);
use WebService::Braintree::Types qw(
    Dispute_Evidence
    Dispute_HistoryEvent
    Dispute_Transaction
    Dispute_TransactionDetails
);

=head1 ATTRIBUTES

=cut

=head2 amount()

This returns the dispute's amount.

=cut

# Coerce this to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 amount_disputed()

This returns the dispute's amount disputed.

=cut

# Coerce this to "big_decimal"
has amount_disputed => (
    is => 'ro',
);

=head2 amount_won()

This returns the dispute's amount won.

=cut

# Coerce this to "big_decimal"
has amount_won => (
    is => 'ro',
);

=head2 case_number()

This returns the dispute's case number.

=cut

has case_number => (
    is => 'ro',
);

=head2 created_at()

This returns when this dispute was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 currency_iso_code()

This returns the dispute's currency ISO code.

=cut

has currency_iso_code => (
    is => 'ro',
);

=head2 date_opened()

This returns when this dispute was opened.

=cut

# Coerce this to DateTime
has date_opened => (
    is => 'ro',
);

=head2 date_won()

This returns when this dispute was won.

=cut

# Coerce this to DateTime
has date_won => (
    is => 'ro',
);

=head2 evidence()

This returns the dispute's evidence (if it exists). This will be an
arrayref of L<WebService::Braintree::_::Dispute::Evidence/>.

=cut

has evidence => (
    is => 'ro',
    isa => ArrayRef[Dispute_Evidence],
    coerce => 1,
);

=head2 forwarded_comments()

This returns the dispute's forwarded comments.

=cut

has forwarded_comments => (
    is => 'ro',
);

=head2 id()

This returns the dispute's ID.

=cut

has id => (
    is => 'ro',
);

=head2 kind()

This returns the dispute's kind.

=cut

has kind => (
    is => 'ro',
);

=head2 merchant_account_id()

This returns the dispute's merchant account ID.

=cut

has merchant_account_id => (
    is => 'ro',
);

=head2 original_dispute_id()

This returns the dispute's original dispute ID.

=cut

has original_dispute_id => (
    is => 'ro',
);

=head2 processor_comments()

This returns the dispute's processor comments.

=cut

has processor_comments => (
    is => 'ro',
);

=head2 reason()

This returns the dispute's reason.

=cut

has reason => (
    is => 'ro',
);

=head2 reason_code()

This returns the dispute's reason code.

=cut

has reason_code => (
    is => 'ro',
);

=head2 reason_description()

This returns the dispute's reason description.

=cut

has reason_description => (
    is => 'ro',
);

=head2 received_date()

This returns when this dispute was received.

=cut

# Coerce this to DateTime
has received_date => (
    is => 'ro',
);

=head2 reference_number()

This returns the dispute's reference number.

=cut

has reference_number => (
    is => 'ro',
);

=head2 reply_by_date()

This returns when this dispute must be replied to.

=cut

# Coerce this to DateTime
has reply_by_date => (
    is => 'ro',
);

=head2 status()

This returns the dispute's status.

=cut

has status => (
    is => 'ro',
);

=head2 status_history()

This returns the dispute's status history. This will be an
arrayref of L<WebService::Braintree::_::Dispute::Evidence/>.

=cut

has status_history => (
    is => 'ro',
    isa => ArrayRef[Dispute_HistoryEvent],
    coerce => 1,
);

=head2 transaction()

This returns the dispute's transaction. This will be an
object of type L<WebService::Braintree::_::Dispute::Transaction/>.

=cut

has transaction => (
    is => 'ro',
    isa => Dispute_Transaction,
    coerce => 1,
);

=head2 transaction_details()

This returns the dispute's transaction details. This will be an
object of type L<WebService::Braintree::_::Dispute::TransactionDetails/>.

=cut

has transaction_details => (
    is => 'ro',
    isa => Dispute_TransactionDetails,
    coerce => 1,
);

=head2 updated_at()

This returns when this dispute was last updated.

=cut

has updated_at => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__

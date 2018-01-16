package WebService::Braintree::DisputeSearch;
$WebService::Braintree::DisputeSearch::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
use WebService::Braintree::AdvancedSearch;

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);
$field->text("case_number");
$field->text("id");
$field->text("reference_number");
$field->text("transaction_id");

$field->multiple_values("ids");
$field->multiple_values("merchant_account_id");
$field->multiple_values("reason");
$field->multiple_values("reason_code");
$field->multiple_values("status");
$field->multiple_values("transaction_source");

$field->range("amount_disputed");
$field->range("amount_won");
$field->range("received_date");
$field->range("reply_by_date");

sub to_hash {
    WebService::Braintree::AdvancedSearch->search_to_hash(shift);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

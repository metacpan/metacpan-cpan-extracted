package WebService::Braintree::SubscriptionSearch;
$WebService::Braintree::SubscriptionSearch::VERSION = '0.92';
use Moose;
use WebService::Braintree::AdvancedSearch;

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);

$field->text("id");
$field->text("transaction_id");
$field->text("plan_id");

$field->multiple_values("in_trial_period");
$field->multiple_values("status", WebService::Braintree::Subscription::Status::All);
$field->multiple_values("merchant_account_id");
$field->multiple_values("ids");

$field->range("price");
$field->range("days_past_due");
$field->range("billing_cycles_remaining");
$field->range("next_billing_date");

sub to_hash {
    WebService::Braintree::AdvancedSearch->search_to_hash(shift);
}

__PACKAGE__->meta->make_immutable;
1;


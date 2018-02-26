package WebService::Braintree::CreditCardVerificationSearch;
$WebService::Braintree::CreditCardVerificationSearch::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
use WebService::Braintree::CreditCard::CardType;
use WebService::Braintree::AdvancedSearch;

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);
$field->text("id");
$field->text("credit_card_cardholder_name");
$field->equality("credit_card_expiration_date");
$field->partial_match("credit_card_number");
$field->multiple_values("ids");

$field->multiple_values("credit_card_card_type", @{WebService::Braintree::CreditCard::CardType::All()});

$field->range("created_at");

sub to_hash {
    WebService::Braintree::AdvancedSearch->search_to_hash(shift);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

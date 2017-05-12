package WWW::Shopify::Model::Refund::Transaction;
use parent 'WWW::Shopify::Model::Transaction';
use Clone qw(clone);

my $fields = clone(WWW::Shopify::Model::Transaction->fields);
$fields->{"receipt"} = new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::Transaction::Receipt");
$fields->{"receipt"}->name("receipt");
$fields->{"payment_details"} = new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::Transaction::PaymentDetails");
$fields->{"payment_details"}->name("payment_details");
$fields->{"order_id"} = new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Order");
$fields->{"order_id"}->name("order_id");

sub fields { return $fields; }

sub parent { return 'WWW::Shopify::Model::Refund'; }
sub included_in_parent { return 1; }
sub is_nested { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
package WWW::Shopify::Model::Refund::Transaction::PaymentDetails;
use parent 'WWW::Shopify::Model::Transaction::PaymentDetails';

sub parent { return 'WWW::Shopify::Model::Refund::Transaction'; }

1;
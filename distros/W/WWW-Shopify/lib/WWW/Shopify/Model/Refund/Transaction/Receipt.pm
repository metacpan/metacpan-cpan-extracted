package WWW::Shopify::Model::Refund::Transaction::Receipt;
use parent 'WWW::Shopify::Model::Transaction::Receipt';

sub parent { return 'WWW::Shopify::Model::Refund::Transaction'; }

1;
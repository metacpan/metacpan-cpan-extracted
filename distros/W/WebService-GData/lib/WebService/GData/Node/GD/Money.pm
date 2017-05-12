package WebService::GData::Node::GD::Money;
use WebService::GData::Node::GD;

set_meta(
   attributes=>[qw(amount currencyCode)],
   is_parent=>0
);

1;

use strict;
use Test::More;

BEGIN { 
	use_ok('WWW::Shopify');
	use_ok('WWW::Shopify::Public', 'scope_compare');
}


is(scope_compare(["read_products"], ["write_products"]), 1);
is(scope_compare(["write_products"], ["read_products"]), -1);
is(scope_compare(["write_products"], ["write_products", "write_orders"]), 1);
is(scope_compare(["read_products"], ["write_products", "write_orders"]), 1);
is(scope_compare(["write_products", "write_script_tag"], ["write_products", "write_orders"]), undef);


done_testing;

1;

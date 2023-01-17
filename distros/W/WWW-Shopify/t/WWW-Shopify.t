use strict;
use Test::More;

BEGIN { 
	use_ok('WWW::Shopify');
	use_ok('WWW::Shopify::Public', 'scope_compare','scope_clean');
}


is(scope_compare(["read_products"], ["write_products"]), 1);
is(scope_compare(["write_products"], ["read_products"]), -1);
is(scope_compare(["write_products"], ["write_products", "write_orders"]), 1);
is(scope_compare(["read_products"], ["write_products", "write_orders"]), 1);
is(scope_compare(["write_products", "write_script_tag"], ["write_products", "write_orders"]), undef);

is(scope_compare(["write_products"], ["read_products", "write_products"]), 0);
is(scope_compare(["write_products","write_orders"], ["read_products","write_orders","write_products"]), 0);

my $scope = scope_clean(["read_products","read_orders","write_script_tags","write_customers","write_themes"]);
my $scope2 = ["read_products","read_orders","write_script_tags","write_customers","write_themes"];
ok(eq_set($scope,$scope2));
 

is(scope_compare(["write_customers","write_script_tags","write_themes"], ["read_products","read_orders","write_script_tags","write_customers","write_themes"]), 1);


done_testing;

1;

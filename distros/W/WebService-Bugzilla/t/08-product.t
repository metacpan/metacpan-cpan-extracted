#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Product;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get product' => sub {
    my $product = $bz->product->get(3);
    isa_ok($product, 'WebService::Bugzilla::Product', 'get product returns product object');
    is($product->name, 'Test', 'product name is correct');
};

subtest 'Search products' => sub {
    my $products = $bz->product->search;
    isa_ok($products, 'ARRAY', 'search returns arrayref of products');
    is(scalar @{$products}, 1, 'one product returned');
};

subtest 'Create product' => sub {
    my $new_product = $bz->product->create(name => 'NewProduct');
    isa_ok($new_product, 'WebService::Bugzilla::Product', 'create returns product object');
    is($new_product->id, 10, 'new product id is correct');
};

subtest 'Update product' => sub {
    my $updated_product = $bz->product->update(3, name => 'UpdatedProduct');
    isa_ok($updated_product, 'WebService::Bugzilla::Product', 'update returns product object');
    is($updated_product->name, 'UpdatedProduct', 'product name updated');
};

subtest 'Update product via instance method' => sub {
    my $product = $bz->product->get(3);
    my $inst_updated_product = $product->update(name => 'InstUpdated');
    isa_ok($inst_updated_product, 'WebService::Bugzilla::Product', 'instance update returns product object');
};

done_testing();

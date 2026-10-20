use strict;
use warnings;

use lib 'lib';
use Test::More;
use OrderManagement::Pricing;
use OrderManagement::Store;

my $quote = OrderManagement::Pricing->quote('preferred', 1_999);
is($quote->{discount_cents}, 0, 'discount does not apply below the threshold');
$quote = OrderManagement::Pricing->quote('preferred', 2_000);
is($quote->{discount_cents}, 200, 'preferred discount begins at 2,000 cents');
is($quote->{total_cents}, 2_300, 'shipping is charged below the free-shipping threshold');
$quote = OrderManagement::Pricing->quote('preferred', 50_000);
is($quote->{shipping_cents}, 0, 'shipping is free after discount at 5,000 cents');
is(OrderManagement::Pricing->to_cents('20.01'), 2_001, 'decimal business input converts exactly to cents');
is(OrderManagement::Pricing->to_cents('20.1'), 2_010, 'one fractional digit is interpreted as tenths of a dollar');
is(OrderManagement::Pricing->from_cents(2_301), '23.01', 'cents format as two decimal digits');
my $bad_amount = eval { OrderManagement::Pricing->to_cents('20.001'); 1 };
ok(!$bad_amount, 'more than two fractional digits are rejected');
my $boundary_below = OrderManagement::Pricing->quote('preferred', OrderManagement::Pricing->to_cents('55.54'));
is($boundary_below->{shipping_cents}, 500, 'shipping remains charged one cent below the post-discount threshold');
my $boundary_at = OrderManagement::Pricing->quote('preferred', OrderManagement::Pricing->to_cents('55.55'));
is($boundary_at->{shipping_cents}, 0, 'shipping is free at the post-discount threshold');

my $store = OrderManagement::Store->new;
ok($store->customer_eligible('C-100'), 'active preferred customer is eligible');
ok($store->customer_eligible('C-200'), 'active standard customer is eligible');
ok(!$store->customer_eligible('C-300'), 'inactive customer is not eligible');
ok(!$store->customer_eligible('missing'), 'unknown customer is not eligible');

my $order = $store->create_order('C-100');
is($store->order_status($order), 'draft', 'new order starts in draft');
my ($accepted, $message) = $store->add_item($order, 'COFFEE', 2);
ok($accepted, 'valid item can be added');
is($store->order_subtotal($order), 1_000, 'subtotal uses integer cents');
($accepted, $message) = $store->reserve_inventory($order);
ok($accepted, 'available inventory can be reserved');
is($store->available('COFFEE'), 8, 'reservation reduces available inventory');
($accepted, $message) = $store->submit_order($order);
ok($accepted, 'reserved eligible order can be submitted');
is($store->order_status($order), 'submitted', 'submission advances order status');

my $shortage = $store->create_order('C-200');
$store->add_item($shortage, 'TEA', 6);
($accepted, $message) = $store->reserve_inventory($shortage);
ok(!$accepted, 'insufficient stock rejects the reservation');
is($message, 'Insufficient stock for TEA: requested 6, available 5.', 'shortage explains requested and available quantities');
is($store->available('TEA'), 5, 'failed multi-line reservation leaves stock unchanged');
is($store->order_status($shortage), 'draft', 'failed reservation leaves order in draft');

my $inactive = $store->create_order('C-300');
$store->add_item($inactive, 'MUG', 1);
($accepted, $message) = $store->reserve_inventory($inactive);
ok(!$accepted, 'inactive customer cannot reserve inventory');
is($message, 'Customer is not eligible to place an order.', 'eligibility rejection is explicit');

my $history = $store->orders_for_customer('C-100');
is_deeply([map { $_->{id} } @$history], ['ORD-001', 'ORD-022'], 'order query includes matching history and the newly created order');

done_testing;

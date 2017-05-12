use strict;
use warnings;

use Test::More tests => 9;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";   # For the Vending namespace
use lib File::Basename::dirname(__FILE__)."/../../../..";   # For the UR namespace
use Vending;

my $machine = Vending::Machine->get();
ok($machine, 'Got the Vending::Machine instance');
$machine->_initialize_for_tests();


# Stock the machine so there's something to get
my $quarter_type = Vending::CoinType->get(name => 'quarter');
my $dime_type = Vending::CoinType->get(name => 'dime');

my $change_disp = $machine->change_dispenser;
ok($change_disp->add_item(subtype_name => 'Vending::Coin', type_id => $quarter_type), "Added a quarter to the change");
ok($change_disp->add_item(subtype_name => 'Vending::Coin', type_id => $dime_type), "Added a dime to the change");

my $prod = Vending::Product->create(name => 'Battery', manufacturer => 'Acme', cost_cents => 65);
ok($prod, "defined Battery product");

my $slot_a = Vending::MachineLocation->get(name => 'a');
$slot_a->add_item(subtype_name => 'Vending::Merchandise', product_id => $prod);

ok($machine->insert('dollar'), 'Inserted a dollar');

my @items = $machine->buy('a');
is(scalar(@items), 3, 'Got back three items');

my %item_counts;
foreach my $item ( @items ) {
    $item_counts{$item->name}++;
}

is($item_counts{'Battery'}, 1, 'One of them was a Battery');
is($item_counts{'quarter'}, 1, 'One of them was a quarter');
is($item_counts{'dime'}, 1, 'One of them was a dime');


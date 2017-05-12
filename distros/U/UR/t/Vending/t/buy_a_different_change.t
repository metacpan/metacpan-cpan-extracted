use strict;
use warnings;

use Test::More tests => 18;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";   # For the Vending namespace
use lib File::Basename::dirname(__FILE__)."/../../../..";   # For the UR namespace
use Vending;

my $machine = Vending::Machine->get();
ok($machine, 'Got the Vending::Machine instance');
$machine->_initialize_for_tests();


# Stock the machine so there's something to get
my $dime_type = Vending::CoinType->get(name => 'dime');
my $nickel_type = Vending::CoinType->get(name => 'nickel');
# 5 dimes and 5 nickels
my $change_disp = $machine->change_dispenser;
foreach ( 1 .. 5 ) {
    ok($change_disp->add_item(subtype_name => 'Vending::Coin', type_id => $nickel_type), 'Added a nickel to the change');
    ok($change_disp->add_item(subtype_name => 'Vending::Coin', type_id => $dime_type), 'Added a dime to the change');
}

my $prod = Vending::Product->create(name => 'Orange', manufacturer => 'Acme', cost_cents => 65);
ok($prod, 'Defined "Orange" product');

my $slot_a = $machine->machine_locations(name => 'a');
my $inv = $slot_a->add_item(subtype_name => 'Vending::Merchandise', product_id => $prod);
ok($inv, 'Added an orange to slot A');

ok($machine->insert('dollar'), 'Inserted a dollar');

my @items = $machine->buy('a');
is(scalar(@items), 5, 'Got back five items');

my %item_counts;
foreach my $item ( @items ) {
    $item_counts{$item->name}++;
}

is($item_counts{'Orange'}, 1, 'One of them was an Orange');
is($item_counts{'nickel'}, 1, 'One of them was a nickel');
is($item_counts{'dime'}, 3, 'Three of them were dimes');



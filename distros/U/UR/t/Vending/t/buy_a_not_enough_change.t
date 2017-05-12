use strict;
use warnings;

use Test::More tests => 16;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";   # For the Vending namespace
use lib File::Basename::dirname(__FILE__)."/../../../..";   # For the UR namespace
use Vending;

my $machine = Vending::Machine->get();
ok($machine, 'Got the Vending::Machine instance');
$machine->_initialize_for_tests();


# Stock the machine, but not enough change
my $quarter_type = Vending::CoinType->get(name => 'quarter');
my $change_disp = $machine->change_dispenser;
ok($change_disp->add_item(subtype_name => 'Vending::Coin', type_id => $quarter_type),'Added a quarter to the change');

my $prod = Vending::Product->create(name => 'Orange', manufacturer => 'Acme', cost_cents => 65);
ok($prod, "Defined 'Orange' product");
my $slot_a = Vending::MachineLocation->get(name => 'a');
my $inv = $slot_a->add_item(subtype_name => 'Vending::Merchandise', product_id => $prod);
ok($inv, 'Added an orange to slot A');

ok($machine->insert('dollar'), 'Inserted a dollar');

my @errors;
$machine->dump_error_messages(0);
$machine->error_messages_callback(sub { push @errors, $_[1]; });
my @items = $machine->buy('a');
is(scalar(@items), 0, 'Got no items');

like($errors[0], qr(Not enough change), 'Error message indicated not enough change');

@items = $machine->coin_return();
is(scalar(@items),1, 'Coin return got us one thing back');
is($items[0]->name, 'dollar', 'The returned thing was a dollar');
is($items[0]->value, 100, 'The returned thing was worth 100 cents');

# Poke the machine and make sure everything is still in there
@items = Vending::Merchandise->get();
is(scalar(@items), 1, 'There is one item still in the inventory');
is($items[0]->name, 'Orange', 'It was an Orange');
is($items[0]->machine_location, $slot_a, 'The orange is in slot a');

my $bank = $machine->bank();
@items = $bank->items();
is(scalar(@items), 0, 'Nothing in the bank');

@items = $change_disp->items();
is(scalar(@items), 1, 'One thing in the change dispenser');
is($items[0]->name, 'quarter', 'It is a quarter');

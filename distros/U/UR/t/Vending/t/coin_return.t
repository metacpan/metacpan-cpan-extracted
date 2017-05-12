use strict;
use warnings;

use Test::More tests => 6;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";   # For the Vending namespace
use lib File::Basename::dirname(__FILE__)."/../../../..";   # For the UR namespace
use Vending;

my $machine = Vending::Machine->get();
ok($machine, 'Got the Vending::Machine instance');
$machine->_initialize_for_tests();

ok($machine->insert('quarter'), 'Inserted a quarter');
ok($machine->insert('quarter'), 'Inserted a quarter');

my @items = $machine->coin_return();
is(scalar(@items), 2, 'Got back two items');

is($items[0]->name, 'quarter', 'Item 1 is a quarter');
is($items[1]->name, 'quarter', 'Item 2 is a quarter');


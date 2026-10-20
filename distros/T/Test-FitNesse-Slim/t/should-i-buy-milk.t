use strict;
use warnings;
use Test::More;

use lib 't/lib';

BEGIN { use_ok('Fitnesse::Slim::Test::ShouldIBuyMilk') }

my $fixture = Fitnesse::Slim::Test::ShouldIBuyMilk->new;
isa_ok($fixture, 'Fitnesse::Slim::Test::ShouldIBuyMilk');

$fixture->set_cash_in_wallet(3);
$fixture->set_credit_card('no');
$fixture->set_pints_of_milk_remaining(0);
is($fixture->go_to_store, 'yes', 'three dollars and no milk means go to the store');

$fixture->set_cash_in_wallet(2);
is($fixture->go_to_store, 'no', 'less than three dollars without a card is insufficient');

$fixture->set_cash_in_wallet(0);
$fixture->set_credit_card('yes');
is($fixture->go_to_store, 'yes', 'a credit card allows buying milk without cash');

$fixture->set_pints_of_milk_remaining(1);
is($fixture->go_to_store, 'no', 'remaining milk means do not go to the store');

$fixture->set_pints_of_milk_remaining(0);
$fixture->set_credit_card('YES');
is($fixture->go_to_store, 'no', 'credit-card input matches the upstream lowercase yes token');

is($fixture->execute, undef, 'execute is an upstream no-op');
is($fixture->reset, undef, 'reset is an upstream no-op');
is($fixture->begin_table, undef, 'beginTable is an upstream no-op');
is($fixture->table([]), undef, 'table is an upstream no-op');
is($fixture->end_table, undef, 'endTable is an upstream no-op');

done_testing;

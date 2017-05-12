use strict;
use warnings;
use above 'Vending';

# Requires a 3-table database join (COIN, CONTENT and CONTENT_TYPE), plus a
# cross-datasource join to Vending::CoinType 
my @coins = Vending::Coin->get(value_cents => 25);

print "Found ",scalar(@coins)," coins:\n";
foreach my $coin ( @coins ) {
    printf("id %s name %s value %d in slot %s\n",$coin->id, $coin->name, $coin->value_cents, $coin->slot_name);
}

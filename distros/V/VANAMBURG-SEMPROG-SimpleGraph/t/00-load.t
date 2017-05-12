#!perl -T 

use Test::More tests => 14;

BEGIN {
	use_ok( 'VANAMBURG::SEMPROG::SimpleGraph' );
}

use VANAMBURG::SEMPROG::SimpleGraph;
use Text::CSV_XS;

my $g = VANAMBURG::SEMPROG::SimpleGraph->new();
isa_ok ($g, 'VANAMBURG::SEMPROG::SimpleGraph');


# ------------------------------------------------------------- #
# TEST SOME OF THE PRIVATE-LIKE FEATURES
# ------------------------------------------------------------- #

$g->add("gordon", "add", "triple1");

my @gkeys = keys %{$g->_spo()};
ok (@gkeys == 1, "got one item in keys of _spo");

my @poskeys = keys %{$g->_pos()};
ok (@poskeys = 1, "got one item inkeys of _pos");

my $predhr = $g->_spo()->{ $gkeys[0] };
my @gpredkeys = keys %{ $g->_spo()->{ $gkeys[0] } };

ok (@gpredkeys == 1, 'got one item in predicate keys of _spo');

my $t1set = $g->_spo()->{$gkeys[0]}->{$gpredkeys[0]};
isa_ok($t1set, 'Set::Scalar');

my @members = $t1set->members();

ok( @members == 1, 'found one member of object set');
diag (">>> t1 is ".$gkeys[0].", ". $gpredkeys[0].", ". $members[0]."\n");


# ------------------------------------------------------------- #

# TEST THE TRIPLES (QUERY) FUNCTION
# ------------------------------------------------------------- #

my @triples = $g->triples(undef, undef, undef);
ok ( @triples == 1, 'undef, undef, undef gives 1 triple');
diag(">>> $triples[0][0]\n");


$g->add("gordon", "add", "triple2");
ok( $t1set->members() == 2, 'found additional member of object set');


my @gtriples = $g->triples("gordon", undef, undef);
diag (">>> gordon triples is " . @gtriples . "\n");

ok ( scalar( @gtriples ) == 2, 'two triples with subject gordon');

my @triple2triples = $g->triples(undef, undef, "triple2");
diag (">>> triple2 triples is " . @triple2triples . "\n");

ok ( @triple2triples == 1, 'one triples with object triple2' );

# ------------------------------------------------------------- #
# TEST THE REMOVE METHOD
# ------------------------------------------------------------- #

$g->remove(undef, undef, "triple2");

@gtriples = $g->triples("gordon", undef, undef);
diag (">>> gordon triples is now " . @gtriples . "\n");
ok( @gtriples == 1, 'removed additional member of object set');



# ------------------------------------------------------------- #
# TEST THE VALUE METHOD
# ------------------------------------------------------------- #
my $x = $g->value(undef,'add', 'triple1');
ok($x eq 'gordon', 'found the value');



# ------------------------------------------------------------- #
# TEST THE LOAD METHOD
# ------------------------------------------------------------- #
my $g2 = VANAMBURG::SEMPROG::SimpleGraph->new();
$g2->load("data/DC_addresses.csv");

my $pot_belly_cost = $g2->value("Pot Belly", "cost", undef);
diag (">>> pot_belly_cost is $pot_belly_cost");

ok ($pot_belly_cost eq "cheap", 'pot belly cost correct');


# ------------------------------------------------------------- #
# TEST THE SAVE METHOD
# ------------------------------------------------------------- #
$g2->save("data/DC_addresses_saved.csv");

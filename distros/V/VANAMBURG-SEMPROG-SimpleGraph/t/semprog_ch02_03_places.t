#!perl -T
use strict;

use Test::More tests => 3;

use VANAMBURG::SEMPROG::SimpleGraph;

# ----------------------------------------------------- #
# Create the SimpleGraph and load the places triple file. 
# ----------------------------------------------------- #


my $graph = VANAMBURG::SEMPROG::SimpleGraph->new();
$graph->load("data/place_triples.txt");

# ----------------------------------------------------- #
# Filter variously, and run Test::More tests 
# and diagnostic messaging.
# ----------------------------------------------------- #

#
# Test 1
#
my @sanfran = $graph->triples(undef, "name", "San Francisco");
ok (@sanfran == 1, 'there is one subject with name san francisco');
diag("\n   sub=". $sanfran[0]->[0]);

#
# Test 2
#
my @sanfran_sub = $graph->triples("San_Francisco_California", undef, undef);
ok (@sanfran_sub == 6, 'there are six triples having subject San_Francisco_California');
for my $t (@sanfran_sub){
    diag(sprintf "   pred=%s  obj=%s",($t->[1], $t->[2]) ) ;
}

#
# Test 3
#
my @mayors = $graph->triples(undef,"mayor",undef); 
ok(@mayors > 21, ">>> there are > 21 mayors.");
for my $t ( @mayors ){
   diag(sprintf "   sub=%s  obj=%s",($t->[0], $t->[2]) ) ;
}


# ----------------------------------------------------- #
# Use multiple calls to triple to refine results.
#  1) Find cities inside California
#  2) Then find their mayors
# ----------------------------------------------------- #

my @cal_cities = map{ $_->[0] } $graph->triples(undef, "inside","California");
diag ("there are " . @cal_cities. " cal cities");

for my $city (@cal_cities){
    for my $t ( $graph->triples($city, "mayor", undef) ){
	diag ("mayor of $city is ". $t->[2]);
    }
}

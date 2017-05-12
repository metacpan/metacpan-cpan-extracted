#!perl 

use Modern::Perl;
use Test::More tests => 4;
use Data::Dumper;
use VANAMBURG::SEMPROG::SimpleGraph;
use VANAMBURG::SEMPROG::GeocodeRule;
use VANAMBURG::SEMPROG::CloseToRule;
use VANAMBURG::SEMPROG::TouristyRule;


my $graph = VANAMBURG::SEMPROG::SimpleGraph->new();

$graph->load("data/DC_addresses.csv") or die $!;

ok(14 == $graph->triples(undef,undef,undef), '14 triples to start');

diag("getting geo code data from internet -- could take a while...");

$graph->applyinference( VANAMBURG::SEMPROG::GeocodeRule->new() );

ok(24 == $graph->triples(undef,undef,undef), 
   '24 triples after first inference.');

$graph->applyinference( 
    VANAMBURG::SEMPROG::CloseToRule->new(
	place=>'White House', graph=>$graph
    ));

ok(29 == $graph->triples(undef,undef,undef), 
   '29 triples after second inference.');

$graph->applyinference(
    VANAMBURG::SEMPROG::TouristyRule->new()
    );

my @touristy_restaurants = $graph->triples(undef,'is_a','touristy restaurant');

ok(@touristy_restaurants == 1, 
   "there is one touristy restaurant after third inference.");

diag("touristy triples:\n". Dumper(@touristy_restaurants));


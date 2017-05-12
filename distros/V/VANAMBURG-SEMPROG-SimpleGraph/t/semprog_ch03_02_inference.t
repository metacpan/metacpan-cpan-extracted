#!perl -T

use Modern::Perl;
use Test::More tests => 2;
use Data::Dumper;
use VANAMBURG::SEMPROG::SimpleGraph;
use VANAMBURG::SEMPROG::GeocodeRule;


my $graph = VANAMBURG::SEMPROG::SimpleGraph->new();

$graph->add('White House', 
	    'address', 
	    '1600 Pennsylvania Avenue, Washington DC');

my @triples_before = $graph->triples(undef, undef, undef);

diag("triples before:\n". Dumper ( @triples_before ) );

ok(@triples_before == 1, 'there is one triple before inference');

my $rule = VANAMBURG::SEMPROG::GeocodeRule->new();

$graph->applyinference($rule);

my @triples_after = $graph->triples(undef, undef, undef);

diag("triples after:\n". Dumper (  $graph->triples(undef, undef, undef) ) );

ok(@triples_after == 3, 'there are three triples after inference');



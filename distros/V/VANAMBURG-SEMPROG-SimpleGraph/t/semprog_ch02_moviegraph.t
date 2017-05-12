#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

use VANAMBURG::SEMPROG::SimpleGraph;

my $graph = VANAMBURG::SEMPROG::SimpleGraph->new();
isa_ok($graph, 'VANAMBURG::SEMPROG::SimpleGraph');

$graph->add('blade_runner', 'name', 'Blade Runner');
$graph->add('blade_runner', 'directed_by', 'ridley_scott');
$graph->add('ridley_scott', 'name', 'Ridley Scott');

my @blade_runner_directed_by = 
    $graph->triples('blade_runner','directed_by', undef);
ok( $blade_runner_directed_by[0]->[2] eq 'ridley_scott', 'director is ridley_scott');


my @named = $graph->triples(undef, 'name', undef);
ok(@named == 2, 'there are two triples with "name" predicate.');


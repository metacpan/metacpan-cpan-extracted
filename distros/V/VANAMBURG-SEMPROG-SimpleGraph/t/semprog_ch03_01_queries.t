#!perl -T

use Modern::Perl;
use Test::More tests => 1;
use Data::Dumper;
use VANAMBURG::SEMPROG::SimpleGraph;

my $g = VANAMBURG::SEMPROG::SimpleGraph->new();

$g->load('data/business_triples.csv');

my @bindings = $g->query([
    ['?company','headquarters','New_York_New_York'],
    ['?company','industry','Investment Banking'],
    ['?cont','contributor','?company'],
    ['?cont', 'recipient', 'Orrin Hatch'],
    ['?cont', 'amount', '?dollars'],
]);

ok(@bindings == 1, 'contribution found.');

diag (Dumper(@bindings));


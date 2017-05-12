#!perl -T

use Test::More tests => 3;
use Modern::Perl;
use Data::Dumper;
use Set::Scalar;
use VANAMBURG::SEMPROG::SimpleGraph;


my $bg = VANAMBURG::SEMPROG::SimpleGraph->new();

$bg->load("data/business_triples.csv");

my $pg = VANAMBURG::SEMPROG::SimpleGraph->new();

$pg->load("data/place_triples.txt");

# Merge place graph data with business
# graph adding place data for all business
# headquarter locations.

my $location_set = Set::Scalar->new();

map {$location_set->insert($_->[2])} 
$bg->triples(undef, 'headquarters', undef);

ok(889 == $location_set->members(), 'There are 889 hq locations.');

ok(0 == $bg->triples(undef, 'mayor', undef), "num mayors before merge is 0");

for my $pt ($pg->triples(undef, undef, undef)){
    my $place = $pt->[0];
    $bg->add( @$pt ) if ($location_set->has($place));      
}

ok(24 == $bg->triples(undef, 'mayor', undef),"num mayors after merge is 24")



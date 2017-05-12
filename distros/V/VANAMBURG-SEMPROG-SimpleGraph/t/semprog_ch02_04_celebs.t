#!perl -T
use strict;

use Test::More tests => 1;

use VANAMBURG::SEMPROG::SimpleGraph;

my $cg = VANAMBURG::SEMPROG::SimpleGraph->new();

$cg->load("data/celeb_triples.csv") or die "$!";

my @jt_relations = map { $_->[0] }  $cg->triples(undef, 'with', 'Justin Timberlake');

ok( @jt_relations > 1, "\njt has relations." );
diag( "jt's partners");
for my $rel (@jt_relations){
    my @partners = map { $_->[2] } $cg->triples( $rel, 'with', undef);
    diag ("    ".  join " + ",@partners);
}

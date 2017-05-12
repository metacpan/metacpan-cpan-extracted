#!perl -T

use Test::More;
use WWW::VieDeMerde;

BEGIN { my $plan = 0; }
plan tests => $plan;

############################################################
# viedemerde.fr
############################################################

my $vdm = WWW::VieDeMerde->new();

############################################################
# last, page
BEGIN { $plan += 4; }
is($vdm->page(), 15, "page returns a list with 15 entries");
is($vdm->last(), 15, "last() returns a list with 15 messages");
is($vdm->page(3), 15, "page works with a page number");
is($vdm->page(10000), 0, "nothing on page 100000");

############################################################
# get, random
BEGIN { $plan += 3; }
my $g = $vdm->get(893417);
ok($g->isa('WWW::VieDeMerde::Message'), "get returns an entry");
is($g->id, 893417, "get returns the good entry");
my $r = $vdm->random();
ok($r->isa('WWW::VieDeMerde::Message'), "random returns an entry");


############################################################
# flop, top
BEGIN { $plan += 6; }
SKIP: {
    skip "fails on the beginning of a week or a month", 6;
    is($vdm->top(), 15, "top returns a list with 15 entries");
    is($vdm->top_jour(), 15, "top_jour returns a list with 15 entries");
    is($vdm->top_semaine(), 15, "top_semaine returns a list with 15 entries");
    is($vdm->top_mois(), 15, "top_mois returns a list with 15 entries");

    is($vdm->flop(), 15, "flop returns a list with 15 entries");
    is($vdm->flop_jour(), 15, "flop_jour returns a list with 15 entries");
    is($vdm->flop_semaine(), 15, "flop_semaine returns a list with 15 entries");
    is($vdm->flop_mois(), 15, "flop_mois returns a list with 15 entries");
}

############################################################
# cat
BEGIN { $plan += 6; }
for (qw/amour argent travail sante sexe inclassable/) {
    is($vdm->from_cat($_), 15, "cat($_) returns a list with 15 entries");
}


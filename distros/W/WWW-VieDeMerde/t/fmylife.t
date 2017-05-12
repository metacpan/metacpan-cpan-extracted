#!perl -T

use Test::More;
use WWW::VieDeMerde;

BEGIN { my $plan = 0; }
plan tests => $plan;

############################################################
# fmylife.com
############################################################

my $fml = WWW::VieDeMerde->new(lang => 'en');

############################################################
# last, page
BEGIN { $plan += 4; }
is($fml->page(), 15, "page returns a list with 15 entries");
is($fml->last(), 15, "last() returns a list with 15 messages");
is($fml->page(3), 15, "page works with a page number");
is($fml->page(10000), 0, "nothing on page 100000");

############################################################
# random
BEGIN { $plan += 3; }
my $g = $fml->get(4879906);
ok($g->isa('WWW::VieDeMerde::Message'), "get returns an entry");
is($g->id, 4879906, "get returns the good entry");
my $r = $fml->random();
ok($r->isa('WWW::VieDeMerde::Message'), "random returns an entry");


############################################################
# flop, top
BEGIN { $plan += 6; }
SKIP: {
    skip "fails on the beginning of a semaine or a month", 6;
    is($fml->top(), 15, "top returns a list with 15 entries");
    is($fml->top_day(), 15, "top_day returns a list with 15 entries");
    is($fml->top_semaine(), 15, "top_semaine returns a list with 15 entries");
    is($fml->top_month(), 15, "top_month returns a list with 15 entries");

    is($fml->flop(), 15, "flop returns a list with 15 entries");
    is($fml->flop_day(), 15, "flop_day returns a list with 15 entries");
    is($fml->flop_semaine(), 15, "flop_semaine returns a list with 15 entries");
    is($fml->flop_month(), 15, "flop_month returns a list with 15 entries");
}

############################################################
# cat
BEGIN { $plan += 7; }
for (qw/love money kids work health sex miscellaneous/) {
    is($fml->from_cat($_), 15, "from_cat($_) returns a list with 15 entries");
}


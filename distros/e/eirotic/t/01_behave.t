#! /usr/bin/perl
use Eirotic;
use Test::More;

sub yes ($block, $desc) {
    eval $_[0];
    ok( (not $@), $_[1] ) or diag $@;
}

yes 'sub ( $int ) { ok "int passed: $int" }'
, "signatures are working";
yes 'take 5, sub {"yes"}', "perlude is loaded";

done_testing;

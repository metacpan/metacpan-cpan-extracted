#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 7;
    use_ok( 'WordNet::BestStem' );
}

is(scalar WordNet::BestStem::best_stem('roses'), 'rose' );
is(scalar WordNet::BestStem::best_stem('rose'), 'rise' );

is(scalar WordNet::BestStem::best_stem('rose', {fre=>{'rose'=>2, 'rise'=>1}}), 'rose' );

my @a = qw( beautiful roses i would like a long stem rose );
my ($a_, $stem_of, $stem_fre, $str_fre) = WordNet::BestStem::deluxe_stems \@a;
$a_ = join(' ', @$a_);
my ($stem_of_, $stem_fre_) = ('', '');
for (sort keys %$stem_of)  { $stem_of_ .= "$_ $stem_of->{$_} "; }
for (sort keys %$stem_fre) { $stem_fre_ .= "$_ $stem_fre->{$_} "; }

is($a_, 'beautiful rose i would like a long stem rose' );
is($stem_of_, 'a a beautiful beautiful i i like like long long rose rose roses rose stem stem would would ');
is($stem_fre_,'a 1 beautiful 1 i 1 like 1 long 1 rose 2 stem 1 would 1 ');

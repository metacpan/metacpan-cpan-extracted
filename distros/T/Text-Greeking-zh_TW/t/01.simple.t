#!/usr/bin/env perl
use common::sense 2.02;
use utf8;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Text::Greeking::zh_TW' );
}

my $g = Text::Greeking::zh_TW->new;
$g->paragraphs(3,15); # min of 1 paragraph and a max of 2
$g->sentences(1,10);  # min of 2 sentences per paragraph and a max of 5
$g->words(8,16);     # min of 8 words per sentence and a max of 16

my $text = $g->generate;

ok(length($text) > 0);

#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;
use Benchmark ':all';
use Test::More tests => 4;
use Text::Levenshtein::Flexible;
use Text::Levenshtein::XS;
use Text::LevenshteinXS;
use Text::Fuzzy;

my $s = "xa"x100;
my $t = "yb"x100;
my $tf = Text::Fuzzy->new($s);
is(Text::Levenshtein::Flexible::levenshtein($s,$t), Text::Levenshtein::XS::distance($s,$t),
    "Same result Text::Levenshtein::Flexible vs. Text::Levenshtein::XS"
);
is(Text::Levenshtein::Flexible::levenshtein($s,$t), Text::LevenshteinXS::distance($s,$t),
    "Same result Text::Levenshtein::Flexible vs. Text::LevenshteinXS"
);
is(Text::Levenshtein::Flexible::levenshtein($s,$t), $tf->distance($t),
    "Same result Text::Levenshtein::Flexible vs. Text::Fuzzy"
);

cmpthese(100000, {
        'Text::Levenshtein::Flexible'   => sub { Text::Levenshtein::Flexible::levenshtein($s, $t); },
        'Text::Levenshtein::XS'         => sub { Text::Levenshtein::XS::distance($s, $t); },
        'Text::LevenshteinXS'           => sub { Text::LevenshteinXS::distance($s, $t); },
        'Text::Fuzzy'                   => sub { $tf->distance($t); },
    }
);

my $o = Text::Levenshtein::Flexible->new(1000000, 1, 2, 3);
is($o->distance_lc($s,$t), Text::Levenshtein::Flexible::levenshtein_lc($s, $t, 1000000, 1, 2, 3),
    "Same result OO vs. procedural"
);
cmpthese(100000, {
        OO      => sub { $o->distance_lc($s, $t); },
        Proc    => sub { Text::Levenshtein::Flexible::levenshtein_lc($s, $t, 1000000, 1, 2, 3); },
    }
);

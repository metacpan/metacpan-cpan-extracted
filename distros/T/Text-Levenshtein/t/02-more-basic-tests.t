#!perl

use strict;
use warnings;
use utf8;

use lib 't/lib';
use Text::Levenshtein::TestUtils qw/ run_data_tests /;

run_data_tests();

__DATA__
# Identical words
chocolate
chocolate
0
--
# Both empty strings


0
--
# One empty string
chocolate

9
--
# Identical words, one space character
 
 
0
--
# Completely different words
pink
blue
4
--
# Second word is the first, with a prefix
fly
butterfly
6
--
# Second word is the first, with a suffix
blue
bluebottle
6
--
# The only difference is an accent on one letter
cafe
café
1
--

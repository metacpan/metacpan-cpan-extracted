#!perl

use strict;
use warnings;
use utf8;

use lib 't/lib';
use Text::Levenshtein::TestUtils qw/ run_data_tests /;

run_data_tests({ ignore_diacritics => 1 });

__DATA__
låsa
läsa
0
--
mån
man
0
--
mått
mätt
0
--
café
cafe
--

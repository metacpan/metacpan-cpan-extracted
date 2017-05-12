#!perl

use strict;
use warnings;
use utf8;

use lib 't/lib';
use Text::Levenshtein::TestUtils qw/ run_data_tests /;

run_data_tests();

__DATA__
läsa
lösa
1
--
lösa
låsa
1
--
fästa
festa
1
--
fästa
fastna
2
--
fasta
fresta
2
--
fästing
fästning
1
--
råda
röda
1
--
röda
röta
1
--
röda
rida
1
--
tråna
trana
1
--
tråna
träna
1
--
trana
träna
1
--
möta
mata
1
--
möta
mäta
1
--
mata
matta
1
--
mata
mätta
2
--
mäta
mätta
1
--

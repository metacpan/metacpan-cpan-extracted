#!perl

use strict;
use warnings;
use utf8;

use lib 't/lib';
use Text::Levenshtein::TestUtils qw/ run_data_tests /;

run_data_tests();

__DATA__
решение
решето
3
--
статуя
статус
1
--
дверь
двор
2
--
смысл
мысль
2
--
кость
кисть
1
--
распределение
определение
3
--

#!perl

use strict;
use warnings;
use utf8;

use lib 't/lib';
use Text::Levenshtein::TestUtils qw/ run_data_tests /;

run_data_tests();

__DATA__
カタナ
カタカナ
1
--
あいうえお
あいうお
1
--
しか
あしか
1
--
はし
はしご
1
--
事務
事務所
1
--
じむ
じむしょ
2
--
事務機
事務局
1
--
じむき
じむきょく
2
--
勉強
勉強家
1
--
べんきょう
べんきょうか
1
--
ヘン
アヘン
1
--
ヘン
ペン
1
--
あやまり
あやまち
1
--
謝り
誤り
1
--

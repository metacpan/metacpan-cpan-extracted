use strict;
use utf8;

use Test::More tests => 7;
use Text::TinySegmenter;

my $str = '私の名前は中野です';
my @words = Text::TinySegmenter->segment($str);

is(scalar @words, 6);
is($words[0], '私');
is($words[1], 'の');
is($words[2], '名前');
is($words[3], 'は');
is($words[4], '中野');
is($words[5], 'です');


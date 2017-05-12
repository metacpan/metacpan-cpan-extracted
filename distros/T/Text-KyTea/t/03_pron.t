use strict;
use warnings;
use Test::Base;
plan tests => 3 * blocks;

use Text::KyTea;

my $kytea  = Text::KyTea->new(model => './model/test.mod');
my $kytea2 = Text::KyTea->new(model => './model/test.mod', prontag_num => 0);

run
{
    my $block = shift;
    my $pron  = $kytea->pron($block->input);
    my $pron2 = $kytea->pron($block->input, 'ピー');
    my $pron3 = $kytea2->pron($block->input);
    is($pron,  $block->expected);
    is($pron2, $block->expected2);
    is($pron3, $block->expected3);
};

__DATA__
===
--- input:     コーパスの文です。
--- expected:  こーぱすのぶんです。
--- expected2: こーぱすのぶんです。
--- expected3: 名詞助詞名詞助動詞語尾補助記号

===
--- input:     もうひとつの文です。
--- expected:  もうひとつのぶんです。
--- expected2: もうひとつのぶんです。
--- expected3: 副詞名詞接尾辞助詞名詞助動詞語尾補助記号

===
--- input:     放出で乗車です。
--- expected:  放出で乗車です。
--- expected2: ピーピーでピーピーです。
--- expected3: 放出助動詞乗車助動詞語尾補助記号

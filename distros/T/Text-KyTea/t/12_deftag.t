use strict;
use warnings;
use Test::Base;
plan tests => 5 * blocks;

use Text::KyTea;

my $kytea = Text::KyTea->new(
    model  => './model/test.mod',
    deftag => '(´・ω・｀)',
);

run
{
    my $block   = shift;
    my $results = $kytea->parse($block->input);

    my ($surf, $pron, @pos) = split_results($results);

    is($surf,  $block->expected_surf, 'surf');
    is($pron,  $block->expected_pron, 'pron');
    is("@pos", $block->expected_pos,  'pos');

    is($kytea->pron($block->input, '( ･`ω･´)'), $block->expected_pron2, 'pron method');
    is($kytea->pron($block->input),             $block->expected_pron3, 'pron method');
};


sub split_results
{
    my $results = shift;

    my ($surf, $pron, @pos);

    for my $result (@{$results})
    {
        $surf .= $result->{surface};

        push(@pos, $result->{tags}[0][0]{feature});
        $pron .= $result->{tags}[1][0]{feature};
    }

    return ($surf, $pron, @pos);
}


__DATA__
===
--- input:          コーパスの文です。
--- expected_surf:  コーパスの文です。
--- expected_pron : こーぱすのぶんです。
--- expected_pron2: こーぱすのぶんです。
--- expected_pron3: こーぱすのぶんです。
--- expected_pos:   名詞 助詞 名詞 助動詞 語尾 補助記号

===
--- input:          もうひとつの文です。
--- expected_surf:  もうひとつの文です。
--- expected_pron:  もうひとつのぶんです。
--- expected_pron2: もうひとつのぶんです。
--- expected_pron3: もうひとつのぶんです。
--- expected_pos:   副詞 名詞 接尾辞 助詞 名詞 助動詞 語尾 補助記号

===
--- input:          XXYBA文
--- expected_surf:  XXYBA文
--- expected_pron:  (´・ω・｀)(´・ω・｀)(´・ω・｀)(´・ω・｀)(´・ω・｀)ぶん
--- expected_pron2: ( ･`ω･´)( ･`ω･´)( ･`ω･´)( ･`ω･´)( ･`ω･´)ぶん
--- expected_pron3: XXYBAぶん
--- expected_pos:   (´・ω・｀) (´・ω・｀) (´・ω・｀) (´・ω・｀) (´・ω・｀) 名詞

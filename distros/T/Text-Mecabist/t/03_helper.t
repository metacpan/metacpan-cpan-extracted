use strict;
use warnings;
use utf8;
use Test::More;

use Text::Mecabist;

subtest 'readable' => sub {
    my $nodes = Text::Mecabist->new->parse('こんにちは')->nodes();
    ok($nodes->[0]->readable);
    ok(not $nodes->[1]->readable);
};

subtest 'is()' => sub {
    my $nodes = Text::Mecabist->new->parse('ゴジラが上陸しました。')->nodes();
    
    is($nodes->[0]->pos, '名詞');
    ok($nodes->[0]->is('名詞'));
    
    is($nodes->[1]->pos, '助詞');
    ok($nodes->[1]->is('助詞'));
    
    is($nodes->[2]->pos, '名詞');
    ok($nodes->[2]->is('名詞'));

    is($nodes->[3]->pos, '動詞');
    ok($nodes->[3]->is('動詞'));
    is($nodes->[3]->inflection_type, 'サ変・スル');
    ok($nodes->[3]->is('サ変・スル'));
    is($nodes->[3]->inflection_form, '連用形');
    ok($nodes->[3]->is('連用形'));
};


done_testing();

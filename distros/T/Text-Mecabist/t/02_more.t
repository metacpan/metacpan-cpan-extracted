use strict;
use warnings;
use utf8;
use Test::More;

use Text::Mecabist;

my $parser = Text::Mecabist->new();
my $doc = $parser->parse('庭には二羽鶏がいる', sub {
    my $node = shift;
    return if not $node->readable;
    $node->text($node->reading);
});

is($doc->join('text'), 'ニワニハニワニワトリガイル');

$doc->each(sub {
    my $node = shift;
    return if not $node->readable;
    $node->text($node->text .'!');
});

is($doc->join('text'), 'ニワ!ニ!ハ!ニ!ワ!ニワトリ!ガ!イル!');

done_testing();

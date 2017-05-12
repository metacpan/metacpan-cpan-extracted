use strict;
use warnings;
use utf8;
use Test::More;

use Text::Mecabist;

my $parser = Text::Mecabist->new();

my $doc = $parser->parse('庭には二羽鶏がいる', sub {
    my $node = shift;
    $node->text($node->reading) if $node->readable;
});

is($doc->stringify, 'ニワニハニワニワトリガイル');
is("$doc", 'ニワニハニワニワトリガイル');
is($doc, 'ニワニハニワニワトリガイル');

done_testing();

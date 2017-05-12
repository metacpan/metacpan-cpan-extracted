use strict;
use utf8;
use Test::More;
use Text::MeCab;
use Encode;

my $data = encode(Text::MeCab::ENCODING, "私はサバです");
my @expect = qw(私 は サバ です);
my $mecab = Text::MeCab->new();
for (
    my $node = $mecab->parse($data);
    $node;
    $node = $node->next
) {
    is decode(Text::MeCab::ENCODING, $node->surface), shift @expect;
}

done_testing;

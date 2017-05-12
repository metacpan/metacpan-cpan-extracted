use strict;
use Test::More;

BEGIN
{
    eval "use MeCab";
    if ($@) {
        plan skip_all => "SWIG MeCab not available";
    } else {
        plan tests => 2;
        use_ok("Text::MeCab");
    }
}

my $text = "今日は晴れ";

my $swig_result = '';
{
    my $swig_mecab = MeCab::Tagger->new("--all-morphs");
    for (
        my $node = $swig_mecab->parseToNode($text);
        $node;
        $node = $node->{next}
    ) {
        $swig_result .= $node->{feature}."\n";
    }
}

my $xs_result = '';
{
    my $xs_mecab = Text::MeCab->new({ all_morphs => 1 });
    for (
        my $node = $xs_mecab->parse($text);
        $node;
        $node = $node->next
    ) {
        $xs_result .= $node->feature . "\n";
    }
}

is $xs_result, $swig_result;

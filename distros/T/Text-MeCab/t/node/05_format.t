use strict;
use utf8;
use Test::More qw(no_plan);
use Encode qw(encode from_to);

BEGIN
{
    use_ok("Text::MeCab");
}

my $text = encode(Text::MeCab::ENCODING, "となりの客は良く柿食う客だ");

my $mecab = Text::MeCab->new({ 
    node_format => "%m",
});

for( my $node = $mecab->parse($text);
        $node;
        $node = $node->next
) {
    my $surface = $node->surface;
    from_to( $surface, Text::MeCab::ENCODING, 'utf-8');
    next unless $surface;

    my $format = $node->format($mecab);
    my $feature = $node->feature;
    if (ok($format, "format returns " . (defined $format ? $format : '(null)') . "'")) {
        unlike($format, qr/,/, "'$format' doesn't contain any comma");
        like($feature, qr/,/, "'$feature' does contain commas");
    }
}

for( my $node = $mecab->parse($text)->dclone;
        $node;
        $node = $node->next
) {
    my $surface = $node->surface;
    from_to( $surface, Text::MeCab::ENCODING, 'utf-8');
    next unless $surface;
    

    my $format = $node->format($mecab);
    my $feature = $node->feature;
    if (ok($format, "format returns '" . (defined $format ? $format : '(null)') . "' for surface '$surface'") ) {
        unlike($format, qr/,/, "'$format' doesn't contain any comma");
        like($feature, qr/,/, "'$feature' does contain commas");
    }
}

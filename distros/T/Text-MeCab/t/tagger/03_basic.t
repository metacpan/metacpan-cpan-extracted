#!perl
use strict;
use utf8;
use Test::More qw(no_plan);
use Encode;

BEGIN
{
    use_ok("Text::MeCab");
}

my $data = encode(Text::MeCab::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

my $mecab = Text::MeCab->new({
    all_morphs => 1
});
ok($mecab);

my @fields = qw(surface feature length cost);
if (&Text::MeCab::MECAB_VERSION >= 0.90) {
    push @fields, qw(rcattr lcattr stat isbest alpha beta prob wcost);
}

for (
    my $node = $mecab->parse($data);
    $node;
    $node = $node->next
) {
    foreach my $field (@fields) {
        my $p = eval { $node->$field };
        ok(!$@, "$field ok (" . (defined $p ? 
            encode_utf8(decode(Text::MeCab::ENCODING, $p)) : "(null)") . ")");
    }
}

$mecab = Text::MeCab->new({
    all_morphs => 1
});
ok($mecab);

for (
    my $node = $mecab->parse($data);
    $node;
    $node = $node->next
) {
    foreach my $field (@fields) {
        my $p = eval { $node->$field };
        ok(!$@, "$field encoded ok (" . (defined $p ? 
            encode_utf8(decode(Text::MeCab::ENCODING, $p)) : "(null)") . ")");
    }
}


1;
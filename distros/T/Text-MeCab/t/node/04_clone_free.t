#!perl
use strict;
use utf8;
use Test::More qw(no_plan);
use Encode;

BEGIN
{
    use_ok("Text::MeCab");
}

my $node;
my $data = encode(Text::MeCab::ENCODING, "太郎は次郎が持っている本を花子に渡した。");
{
    my $mecab = Text::MeCab->new;
    $node = $mecab->parse($data);
    $mecab = undef;
}

ok($node); # yes, node exists, but DO NOT use node->surface.

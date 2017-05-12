#!perl
use strict;
use utf8;
use Test::More;
use Encode;

BEGIN
{
    use_ok("Text::MeCab");
}

my $data = {
    taro => encode(Text::MeCab::ENCODING, "太郎は次郎が持っている本を花子に渡した。"),
    sumomo => encode(Text::MeCab::ENCODING, "すもももももももものうち。"),
};

my $mecab = Text::MeCab->new;

my ($node_A, $node_B);
{
    my $node_A_orig = $mecab->parse($data->{taro});
    ok($node_A_orig, "Original node A OK");
    $node_A = $node_A_orig->dclone;
    ok $node_A, "Clone Node A successful";

    my $node = $node_A;
    while ( $node_A_orig ) {
        check_node( $node, $node_A_orig );
        $node = $node->next;
        $node_A_orig = $node_A_orig->next;
    }
}

{
    my $node_B_orig = $mecab->parse($data->{sumomo});
    ok($node_B_orig, "Original node B OK");
    $node_B = $node_B_orig->dclone;
    ok $node_B, "Clone Node B successful";

    my $node = $node_B;
    while ( $node_B_orig ) {
        check_node( $node, $node_B_orig );
        $node = $node->next;
        $node_B_orig = $node_B_orig->next;
    }
}

# finally, make sure that node_A, node_B are NOT identical
ok $node_A;
ok $node_B;
isnt $node_A->surface, $node_B->surface;

done_testing();

sub check_node {
    my ($clone, $orig) = @_;
    if (ok($clone, "Deep clone node OK")) {
        note $clone->surface;
    }
    isa_ok($clone, "Text::MeCab::Node::Cloned", "Deep clone node isa OK");
    is $clone->surface, $orig->surface;
}

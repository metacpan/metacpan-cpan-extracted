# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 2;
    BEGIN { use_ok('XML::TreePP') };
# ----------------------------------------------------------------
    my $source = '<root><foo bar="hoge" /></root>';
    my $tpp = XML::TreePP->new(empty_element_tag_end => '>');
    my $tree1 = $tpp->parse( $source );
    like $tpp->write($tree1), qr!<foo bar="hoge">!;
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

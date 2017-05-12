# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 113;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
{
    my $rss = <<'EOT';
<rss version="2.0">
    <channel>
        <item>
            <link>http://www.example.com/1.html</link>
            <category>cate_a</category>
        </item>
        <item>
            <link>http://www.example.com/2.html</link>
            <category>cate_b</category>
            <category>cate_c</category>
        </item>
        <item>
            <link>http://www.example.com/3.html</link>
            <category type="d">cate_d</category>
        </item>
        <item>
            <link>http://www.example.com/4.html</link>
            <category type="e">cate_e</category>
            <category domain="f">cate_f</category>
        </item>
        <item>
            <link>http://www.example.com/5.html</link>
            <category type="g">cate_g</category>
            <category>cate_h</category>
            <category domain="i">cate_i</category>
            <category>cate_j</category>
        </item>
    </channel>
</rss>
EOT
    &test_default( $rss );
    my $rdf = &test_as_rdf( $rss );
    &test_as_rss( $rdf );
    my $atom10 = &test_as_atom10( $rss );
    &test_as_rss( $atom10 );
}
# ----------------------------------------------------------------
sub test_as_atom10 {
    my $source = shift;
    my $feed = XML::FeedPP::Atom::Atom10->new();
    ok( $feed, 'TESTING AS Atom10' );
    $feed->merge( $source );
    my $xml = $feed->to_string();
    &test_fetch( $feed );
    &test_update( $feed );
    $xml;
}
# ----------------------------------------------------------------
sub test_as_rdf {
    my $source = shift;
    my $feed = XML::FeedPP::RDF->new();
    ok( $feed, 'TESTING AS RDF' );
    $feed->merge( $source );
    my $xml = $feed->to_string();
    &test_fetch( $feed );
    &test_update( $feed );
    $xml;
}
# ----------------------------------------------------------------
sub test_as_rss {
    my $source = shift;
    my $feed = XML::FeedPP::RSS->new();
    ok( $feed, 'TESTING AS RSS' );
    $feed->merge( $source );
    &test_fetch( $feed );
    &test_update( $feed );
}
# ----------------------------------------------------------------
sub test_default {
    my $source = shift;
    my $feed = XML::FeedPP->new( $source );
    ok( $feed, 'TESTING DEFAULT' );
    &test_fetch( $feed );
    &test_attribute( $feed );
}
# ----------------------------------------------------------------
sub test_update {
    my $feed = shift;

    my $cnt1 = 0;
    foreach my $item ( $feed->get_item() ) {
        $item->category( 'cate_'.$cnt1 );
        $cnt1 ++;
    }

    my $cnt2 = 0;
    foreach my $item ( $feed->get_item() ) {
        my $cate = $item->category();
        is( $cate, 'cate_'.$cnt2, 'update category '.$cnt2 );
        $cnt2 ++;
    }
}
# ----------------------------------------------------------------
sub test_attribute {
    my $feed = shift;

    my $item0 = $feed->get_item( 0 );
    $item0->set( 'category@type', 'XXX' );
    my $type0 = $item0->get( 'category@type' );
    is( $type0, 'XXX', '0: update type' );

    my $item1 = $feed->get_item( 1 );
    $item1->set( 'category@domain', 'YYY' );
    my $doma1 = $item1->get( 'category@domain' );
    is( $doma1, 'YYY', '1: update domain' );

    my $item2 = $feed->get_item( 2 );
    my $type2 = $item2->get( 'category@type' );
    is( $type2, 'd', '2: with attribute / type' );

    my $item3 = $feed->get_item( 3 );
    my $type3 = $item3->get( 'category@type' );
    my $doma3 = $item3->get( 'category@domain' );
    is( $type3, 'e', '3: multiple with attribute / type' );
    is( $doma3, 'f', '3: multiple with attribute / domain' );

    my $item4 = $feed->get_item( 4 );
    my @type4 = $item4->get( 'category@type' );
    is( $type4[0], 'g', '4: mixed / type g' );
    my @doma4 = $item4->get( 'category@domain' );
    is( $doma4[2], 'i', '4: mixed / domain i' );
}
# ----------------------------------------------------------------
sub test_fetch {
    my $feed = shift;

    my $item0 = $feed->get_item( 0 );
    my $cate0 = $item0->category;
    is( $cate0, 'cate_a', '0: normal / val a' );

    my $item1 = $feed->get_item( 1 );
    my $cate1 = $item1->category;
    ok( ref $cate1, '1: multiple / ref' );
    is( (scalar @$cate1), 2, '1: multiple / num' );
    is( $cate1->[0], 'cate_b', '1: multiple / val b' );
    is( $cate1->[1], 'cate_c', '1: multiple / val c' );

    my $item2 = $feed->get_item( 2 );
    my $cate2 = $item2->category;
    is( $cate2, 'cate_d', '2: with type / val d' );

    my $item3 = $feed->get_item( 3 );
    my $cate3 = $item3->category;
    ok( ref $cate3, '3: multiple with attribute / ref' );
    is( (scalar @$cate3), 2, '3: multiple with attribute / num' );
    is( $cate3->[0], 'cate_e', '3: multiple with attribute / val e' );
    is( $cate3->[1], 'cate_f', '3: multiple with attribute / val f' );

    my $item4 = $feed->get_item( 4 );
    my $cate4 = $item4->category;
    ok( ref $cate4, '4: mixed / ref' );
    is( (scalar @$cate4), 4, '4: mixed / num' );
    is( $cate4->[0], 'cate_g', '4: mixed / val g' );
    is( $cate4->[1], 'cate_h', '4: mixed / val h' );
    is( $cate4->[2], 'cate_i', '4: mixed / val i' );
    is( $cate4->[3], 'cate_j', '4: mixed / val j' );
}
# ----------------------------------------------------------------

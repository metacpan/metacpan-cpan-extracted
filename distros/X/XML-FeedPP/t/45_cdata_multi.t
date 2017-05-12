# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 23;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $url = "http://www.kawa.net/";
    my $cate1 = "hoge";
    my $cate2 = "pomu";
    my $cate3 = "foobar";
    my $catem = [ \$cate1, \$cate2, \$cate3 ];
    my $caten = scalar @$catem;
# ----------------------------------------------------------------
    my $feed0 = XML::FeedPP::RSS->new();
    $feed0->link( $url );
    my $item0 = $feed0->add_item( $url );
    $item0->category( $catem );
    ok( ref $item0->category(), "init multi ref" );
    my $source = $feed0->to_string();
    like( $source, qr/><!\[CDATA\[\Q$cate1\E\]\]></s, "init multi 1/3" );
    like( $source, qr/><!\[CDATA\[\Q$cate2\E\]\]></s, "init multi 2/3" );
    like( $source, qr/><!\[CDATA\[\Q$cate3\E\]\]></s, "init multi 3/3" );
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RDF->new(),
        XML::FeedPP::RSS->new(),
#       XML::FeedPP::Atom::Atom10->new(),   # Atom 1.0's <category> doesn't use CDATA
    ];
# ----------------------------------------------------------------
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        $feed1->merge( $source );
        my $item1 = $feed1->get_item(0);
        my $icate = $item1->category();
        ok( ref $icate, "$type load ref" );
        is( scalar @$icate, $caten, "$type load count" );

        $item1->category( \$cate1 );
        is( $item1->category(), $cate1, "$type one" );
        like( $feed1->to_string(), qr/><!\[CDATA\[\Q$cate1\E\]\]></s, "$type one source" );

        $item1->category( $catem );
        my $jcate = $item1->category();
        ok( ref $jcate, "$type multi ref" );
        is( scalar @$jcate, $caten, "$type multi count" );

        $source = $feed1->to_string();
        like( $source, qr/><!\[CDATA\[\Q$cate1\E\]\]></s, "$type multi 1/3" );
        like( $source, qr/><!\[CDATA\[\Q$cate2\E\]\]></s, "$type multi 2/3" );
        like( $source, qr/><!\[CDATA\[\Q$cate3\E\]\]></s, "$type multi 3/3" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

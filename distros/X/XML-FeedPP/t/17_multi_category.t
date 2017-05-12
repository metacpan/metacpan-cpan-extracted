# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 26;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $url = "http://www.kawa.net/";
    my $cate1 = "hoge";
    my $cate2 = "pomu";
    my $cate3 = "foobar";
    my $catem = [ $cate1, $cate2, $cate3 ];
    my $caten = scalar @$catem;
# ----------------------------------------------------------------
    my $feed0 = XML::FeedPP::RSS->new();
	$feed0->link( $url );
    my $item0 = $feed0->add_item( $url );
    $item0->category( $catem );
    ok( ref $item0->category(), "init multi ref" );
    my $source = $feed0->to_string();
    like( $source, qr/>\s*\Q$cate1\E\s*</s, "init multi 1/3" );
    like( $source, qr/>\s*\Q$cate2\E\s*</s, "init multi 2/3" );
    like( $source, qr/>\s*\Q$cate3\E\s*</s, "init multi 3/3" );
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RDF->new(),
        XML::FeedPP::RSS->new(),
        XML::FeedPP::Atom::Atom10->new(),
    ];
# ----------------------------------------------------------------
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        $feed1->merge( $source );
        my $item1 = $feed1->get_item(0);
        my $icate = $item1->category();
        my $icatn = scalar @$icate if ref $icate;
        is( $icatn, $caten, "$type load count" );

        $item1->category( $cate1 );
        is( $item1->category(), $cate1, "$type one" );
        ok( $feed1->to_string() =~ /\W\Q$cate1\E\W/s, "$type one source" );

        $item1->category( $catem );
        my $jcate = $item1->category();
        my $jcatn = scalar @$jcate if ref $jcate;
        is( $jcatn, $caten, "$type multi count" );

        $source = $feed1->to_string();
        like( $source, qr/\W\Q$cate1\E\W/s, "$type multi 1/3" );
        like( $source, qr/\W\Q$cate2\E\W/s, "$type multi 2/3" );
        like( $source, qr/\W\Q$cate3\E\W/s, "$type multi 3/3" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

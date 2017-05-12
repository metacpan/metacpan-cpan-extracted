# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 57;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $flink  = "http://www.kawa.net/";
    my $ilink  = "http://kawanet.blogspot.com/";
    my $ftitle = "hoge";
    my $ititle = "pomu";
    my $fdesc  = "foo";
    my $idesc  = "bar";
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RDF->new(),
        XML::FeedPP::RSS->new(),
        XML::FeedPP::Atom::Atom03->new(),
        XML::FeedPP::Atom::Atom10->new(),
    ];
# ----------------------------------------------------------------
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        
        $feed1->link($flink);
        $feed1->title(\$ftitle);
        $feed1->description(\$fdesc);        

        my $item1 = $feed1->add_item($ilink);
        $item1->link($ilink);
        $item1->title(\$ititle);
        $item1->description(\$idesc);

        my $source = $feed1->to_string();
        my $feed2 = XML::FeedPP ->new($source);
        my $item2 = $feed2->get_item(0);

        is( $feed1->link(), $flink, "$type feed link");
        is( $feed1->title(), $ftitle, "$type feed title");
        is( $feed1->description(), $fdesc, "$type feed description");
        
        like( $source, qr/<!\[CDATA\[\Q$ftitle\E\]\]>/s, "$type feed title source" );
        like( $source, qr/<!\[CDATA\[\Q$fdesc\E\]\]>/s, "$type feed description source" );

        is( $feed2->title(), $ftitle, "$type feed title back");
        is( $feed2->description(), $fdesc, "$type feed description back");

        is( $item1->link(), $ilink, "$type item link");
        is( $item1->title(), $ititle, "$type item title");
        is( $item1->description(), $idesc, "$type item description");

        like( $source, qr/<!\[CDATA\[\Q$ititle\E\]\]>/s, "$type item title source" );
        like( $source, qr/<!\[CDATA\[\Q$idesc\E\]\]>/s, "$type item description source" );

        is( $item2->title(), $ititle, "$type item title back");
        is( $item2->description(), $idesc, "$type item description back");
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

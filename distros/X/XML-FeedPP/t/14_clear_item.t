# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 28;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $link0  = "http://www.kawa.net/";
    my $title0 = "Site 0";
    my $link1  = "http://www.kawa.net/xp/index-e.html";
    my $title1 = "Entry 1";
    my $link2  = "http://www.flickr.com/photos/u-suke/";
    my $title2 = "Entry 2";
    my $link3  = "http://kawa.at.webry.info/";
    my $title3 = "Entry 3";
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RSS->new(),
        XML::FeedPP::RDF->new(),
        XML::FeedPP::Atom->new(),
    ];
# ----------------------------------------------------------------
    foreach my $feed ( @$feeds ) {
        my $type = ref $feed;
        $feed->link( $link0 );
        $feed->title( $title0 );
        is( scalar $feed->get_item(), 0, "$type no item at first" );

        my $item1 = $feed->add_item( $link1 );
        $item1->title( $title1 );
        my $item2 = $feed->add_item( $link2 );
        $item2->title( $title2 );
        my $item3 = $feed->add_item( $link3 );
        $item3->title( $title3 );
        is( scalar $feed->get_item(), 3, "$type 3 items" );

        my $srcA = $feed->to_string();
        ok( $srcA =~ m/<link[^<]+\Q$link1\E/s, "$type to_string 1" );
        ok( $srcA =~ m/<link[^<]+\Q$link2\E/s, "$type to_string 2" );
        ok( $srcA =~ m/<link[^<]+\Q$link3\E/s, "$type to_string 3" );

        $feed->clear_item();
        is( scalar $feed->get_item(), 0, "$type no item after clear" );

        my $srcB = $feed->to_string();
        ok( $srcB !~ m/<link[^<]+\Q$link1\E/s, "$type to_string 4" );
        ok( $srcB !~ m/<link[^<]+\Q$link2\E/s, "$type to_string 5" );
        ok( $srcB !~ m/<link[^<]+\Q$link3\E/s, "$type to_string 6" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

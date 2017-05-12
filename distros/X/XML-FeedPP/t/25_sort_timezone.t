# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 19;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $link1 = "http://www.kawa.net/";
    my $link2 = "http://kawa.at.webry.info/";
    my $link3 = "http://kawanet.blogspot.com/";
    my $link4 = "http://picasaweb.google.com/www.kawa.net/";
    my $link5 = "http://del.icio.us/kawa.net";
# ----------------------------------------------------------------
    my $date1 = "2004-11-09T11:33:20Z";             # 1100000000;
    my $date2 = "2004-11-09T11:33:20+01:00";
    my $date3 = "2004-11-09T11:33:20-01:30";
    my $date4 = "Tue, 09 Nov 2004 11:33:20 +0130";
    my $date5 = "Tue, 09 Nov 2004 11:33:20 -0100";
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RSS->new();
    my $feed2 = XML::FeedPP::RDF->new();
    my $feed3 = XML::FeedPP::Atom->new();
# ----------------------------------------------------------------
    foreach my $feed0 ( $feed1, $feed2, $feed3 ) {
        my $mode = ref $feed0;
        $feed0->add_item( link => $link1, pubDate => $date1 );
        $feed0->add_item( link => $link2, pubDate => $date2 );
        $feed0->add_item( link => $link3, pubDate => $date3 );
        $feed0->add_item( link => $link4, pubDate => $date4 );
        $feed0->add_item( link => $link5, pubDate => $date5 );
        $feed0->sort_item();
        is( scalar $feed0->get_item(), 5, "$mode count 5" );
        is( $feed0->get_item(0)->get_pubDate_w3cdtf(),  $date3, "$mode sort 0" );
        is( $feed0->get_item(1)->get_pubDate_rfc1123(), $date5, "$mode sort 1" );
        is( $feed0->get_item(2)->get_pubDate_w3cdtf(),  $date1, "$mode sort 2" );
        is( $feed0->get_item(3)->get_pubDate_w3cdtf(),  $date2, "$mode sort 3" );
        is( $feed0->get_item(4)->get_pubDate_rfc1123(), $date4, "$mode sort 4" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

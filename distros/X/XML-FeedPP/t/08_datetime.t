# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 50;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $date110u = 1100000000;
    my $date110w = "2004-11-09T11:33:20Z";              # 1100000000
    my $date110h = "Tue, 09 Nov 2004 11:33:20 GMT";
    my $date111w = "2005-03-05T14:20:00+09:00";         # 1110000000
    my $date111h = "Sat, 05 Mar 2005 14:20:00 +0900";
    my $date112w = "2005-06-29T08:06:30-09:00";         # 1120000000
    my $date112h = "Wed, 29 Jun 2005 08:06:30 -0900";
    my $date113w = "2005-10-23T01:53:20Z";              # 1130000000
    my $date113h = "Sun, 23 Oct 2005 01:53:20 GMT";
    my $date114w = "2006-02-15T19:40:00Z";              # 1140000000
    my $date114h = "Wed, 15 Feb 2006 19:40:00 GMT";
    my $url = "http://www.kawa.net/";
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RSS->new();
    $feed1->pubDate( $date111h );
    is( $feed1->pubDate(), $date111w, "RSS:  http - w3cdtf 1" );
    $feed1->pubDate( $date112h );
    is( $feed1->pubDate(), $date112w, "RSS:  http - w3cdtf 2" );
    $feed1->pubDate( $date113w );
    is( $feed1->pubDate(), $date113w, "RSS:  w3cdtf - http - w3cdtf 1" );
    $feed1->pubDate( $date114w );
    is( $feed1->pubDate(), $date114w, "RSS:  w3cdtf - http - w3cdtf 2" );
# ----------------------------------------------------------------
    my $feed2 = XML::FeedPP::RDF->new();
    $feed2->pubDate( $date111h );
    is( $feed2->pubDate(), $date111w, "RDF:  http - w3cdtf 1" );
    $feed2->pubDate( $date112w );
    is( $feed2->pubDate(), $date112w, "RDF:  w3cdtf - w3cdtf 1" );
    $feed2->pubDate( $date113h );
    is( $feed2->pubDate(), $date113w, "RDF:  http - w3cdtf 2" );
    $feed2->pubDate( $date114w );
    is( $feed2->pubDate(), $date114w, "RDF:  w3cdtf - w3cdtf 2" );
# ----------------------------------------------------------------
    my $feed3 = XML::FeedPP::Atom->new();
    $feed3->pubDate( $date111w );
    is( $feed3->pubDate(), $date111w, "Atom: w3cdtf - w3cdtf 1" );
    $feed3->pubDate( $date112h );
    is( $feed3->pubDate(), $date112w, "Atom: http - w3cdtf 1" );
    $feed3->pubDate( $date113w );
    is( $feed3->pubDate(), $date113w, "Atom: w3cdtf - w3cdtf 2" );
    $feed3->pubDate( $date114h );
    is( $feed3->pubDate(), $date114w, "Atom: http - w3cdtf 2" );
# ----------------------------------------------------------------
    is( $feed1->get_pubDate_native(),  $date114h, "RSS:  channel native" );
    is( $feed2->get_pubDate_native(),  $date114w, "RDF:  channel native" );
    is( $feed3->get_pubDate_native(),  $date114w, "Atom: channel native" );
    is( $feed1->get_pubDate_w3cdtf(),  $date114w, "RSS:  channel w3cdtf" );
    is( $feed2->get_pubDate_w3cdtf(),  $date114w, "RDF:  channel w3cdtf" );
    is( $feed3->get_pubDate_w3cdtf(),  $date114w, "Atom: channel w3cdtf" );
    is( $feed1->get_pubDate_rfc1123(), $date114h, "RSS:  channel rfc1123" );
    is( $feed2->get_pubDate_rfc1123(), $date114h, "RDF:  channel rfc1123" );
    is( $feed3->get_pubDate_rfc1123(), $date114h, "Atom: channel rfc1123" );
# ----------------------------------------------------------------
    $feed1->pubDate( $date110u );
    $feed2->pubDate( $date110u );
    $feed3->pubDate( $date110u );
    is( $feed1->get_pubDate_epoch(), $date110u, "RSS:  channel epoch" );
    is( $feed2->get_pubDate_epoch(), $date110u, "RDF:  channel epoch" );
    is( $feed3->get_pubDate_epoch(), $date110u, "Atom: channel epoch" );
    my $w3c1  = $feed1->get_pubDate_w3cdtf();
    my $w3c2  = $feed2->get_pubDate_w3cdtf();
    my $w3c3  = $feed3->get_pubDate_w3cdtf();
    is( $w3c2, $w3c1, "RSS/RDF:  epoch - w3cdtf" );
    is( $w3c3, $w3c1, "RSS/Atom: epoch - w3cdtf" );
    my $http1 = $feed1->get_pubDate_rfc1123();
    my $http2 = $feed2->get_pubDate_rfc1123();
    my $http3 = $feed3->get_pubDate_rfc1123();
    is( $http2, $http1, "RSS/RDF:  epoch - http" );
    is( $http3, $http1, "RSS/Atom: epoch - http" );
# ----------------------------------------------------------------
    my $item1 = $feed1->add_item( $url );
    my $item2 = $feed2->add_item( $url );
    my $item3 = $feed3->add_item( $url );
# ----------------------------------------------------------------
    $item1->pubDate( $date110u );
    $item2->pubDate( $date110u );
    $item3->pubDate( $date110u );
    is( $item1->get_pubDate_epoch(), $date110u, "RSS:  item epoch" );
    is( $item2->get_pubDate_epoch(), $date110u, "RDF:  item epoch" );
    is( $item3->get_pubDate_epoch(), $date110u, "Atom: item epoch" );
# ----------------------------------------------------------------
    $item1->pubDate( $date110h );
    $item2->pubDate( $date110h );
    $item3->pubDate( $date110h );
    is( $item1->pubDate(), $date110w, "RSS:  item http - w3cdtf" );
    is( $item2->pubDate(), $date110w, "RDF:  item http - w3cdtf" );
    is( $item3->pubDate(), $date110w, "Atom: item http - w3cdtf" );
    is( $item1->get_pubDate_native(), $date110h, "RSS:  item native http" );
    is( $item2->get_pubDate_native(), $date110w, "RDF:  item native http" );
    is( $item3->get_pubDate_native(), $date110w, "Atom: item native http" );
    is( $item1->get_pubDate_w3cdtf(), $date110w, "RSS:  item w3cdtf" );
    is( $item2->get_pubDate_w3cdtf(), $date110w, "RDF:  item w3cdtf" );
    is( $item3->get_pubDate_w3cdtf(), $date110w, "Atom: item w3cdtf" );
# ----------------------------------------------------------------
    $item1->pubDate( $date111w );
    $item2->pubDate( $date111w );
    $item3->pubDate( $date111w );
    is( $item1->pubDate(), $date111w, "RSS:  item http - w3cdtf" );
    is( $item2->pubDate(), $date111w, "RDF:  item http - w3cdtf" );
    is( $item3->pubDate(), $date111w, "Atom: item http - w3cdtf" );
    is( $item1->get_pubDate_native(),  $date111h, "RSS:  item native w3cdtf" );
    is( $item2->get_pubDate_native(),  $date111w, "RDF:  item native w3cdtf" );
    is( $item3->get_pubDate_native(),  $date111w, "Atom: item native w3cdtf" );
    is( $item1->get_pubDate_rfc1123(), $date111h, "RSS:  item rfc1123" );
    is( $item2->get_pubDate_rfc1123(), $date111h, "RDF:  item rfc1123" );
    is( $item3->get_pubDate_rfc1123(), $date111h, "Atom: item rfc1123" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

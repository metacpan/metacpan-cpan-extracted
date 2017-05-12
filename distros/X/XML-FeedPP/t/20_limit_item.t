# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 40;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $link1 = "http://www.kawa.net/";
    my $link2 = "http://www.youtube.com/user/YusukeKawasaki";
    my $link3 = "http://picasaweb.google.com/www.kawa.net/";
    my $link4 = "http://kawanet.blogspot.com/";
    my $link5 = "http://del.icio.us/kawa.net";
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RSS->new();
    my $feed2 = XML::FeedPP::RDF->new();
    my $feed3 = XML::FeedPP::Atom->new();
# ----------------------------------------------------------------
    my $links = [ $link1, $link2, $link3, $link4, $link5 ];
# ----------------------------------------------------------------
    foreach my $f ( $feed1, $feed2, $feed3 ) {
        my $mode = ( (ref $f) =~ /([^:]+)$/ )[0];
        foreach my $u ( @$links ) {
            $f->add_item( $u );
        }

        $f->limit_item( 4 );
        is( scalar $f->get_item(), 4, "$mode limit_item 4 count" );
        is( $f->get_item(0)->link(), $link1, "$mode limit_item 4 link 0" );
        is( $f->get_item(3)->link(), $link4, "$mode limit_item 4 link 3" );

        $f->limit_item( -3 );
        is( scalar $f->get_item(), 3, "$mode limit_recent_item 3 count" );
        is( $f->get_item(0)->link(), $link2, "$mode limit_recent_item 3 link 0" );
        is( $f->get_item(2)->link(), $link4, "$mode limit_recent_item 3 link 2" );

        $f->limit_item( 2 );
        is( scalar $f->get_item(), 2, "$mode limit_item 2 count" );
        is( $f->get_item(0)->link(), $link2, "$mode limit_item 2 link 0" );
        is( $f->get_item(1)->link(), $link3, "$mode limit_item 2 link 1" );

        $f->limit_item( -1 );
        is( scalar $f->get_item(), 1, "$mode limit_recent_item 1 count" );
        is( $f->get_item(0)->link(), $link3, "$mode limit_recent_item 1 link 0" );

        $f->limit_item( 10 );
        is( scalar $f->get_item(), 1, "$mode limit_item 10 count" );

        $f->limit_item( -10 );
        is( scalar $f->get_item(), 1, "$mode limit_recent_item 10 count" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

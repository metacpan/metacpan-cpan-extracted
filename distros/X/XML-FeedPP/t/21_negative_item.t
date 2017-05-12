# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 28;
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

        is( $f->get_item(-2)->link(),    $link4, "$mode get_item -2" );
        is( $f->remove_item(-2)->link(), $link4, "$mode remove_item -2" );

        is( $f->get_item(0)->link(),     $link1, "$mode get_item 0" );
        is( $f->remove_item(0)->link(),  $link1, "$mode remove_item 0" );

        is( $f->get_item(-1)->link(),    $link5, "$mode get_item -1" );
        is( $f->remove_item(-1)->link(), $link5, "$mode remove_item -1" );

        is( $f->get_item(1)->link(),     $link3, "$mode get_item 1" );
        is( $f->remove_item(1)->link(),  $link3, "$mode remove_item 1" );

        is( scalar $f->get_item(), 1, "$mode count 1" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

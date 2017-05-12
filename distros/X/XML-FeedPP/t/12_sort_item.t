# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 19;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $link1 = "http://www.kawa.net/";
    my $link2 = "http://www.flickr.com/photos/u-suke/";
    my $link3 = "http://feeds.feedburner.com/u-suke/";
    my $link4 = "http://kawa.suprglu.com/";
    my $link5 = "http://del.icio.us/kawa.net";
# ----------------------------------------------------------------
    my $date1 = 1100000000;
    my $date2 = "2005-03-05T14:20:00+09:00";        # 1110000000
    my $date3 = "Wed, 29 Jun 2005 08:06:30 -0900";  # 1120000000
    my $date4 = "2005-10-23T01:53:20Z";             # 1130000000
    my $date5 = "Wed, 15 Feb 2006 19:40:00 GMT";    # 1140000000
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RSS->new();
    my $feed2 = XML::FeedPP::RDF->new();
    my $feed3 = XML::FeedPP::Atom->new();
# ----------------------------------------------------------------
    my $map = {
        $link1  =>  $date1,
        $link2  =>  $date2,
        $link3  =>  $date3,
        $link4  =>  $date4,
        $link5  =>  $date5,
    };
# ----------------------------------------------------------------
    foreach my $f ( $feed1, $feed2, $feed3 ) {
        foreach my $u ( sort keys %$map ) {
            my $i = $f->add_item( $u );
            $i->pubDate( $map->{$u} ) if $map->{$u};
        }
        my $mode = ( (ref $f) =~ /([^:]+)$/ )[0];
        is( 5, scalar $f->get_item(), "$mode count #1" );
        $f->sort_item();
        is( 5, scalar $f->get_item(), "$mode count #2" );
        is( $date2, $f->get_item(3)->pubDate(), "$mode sort #1" );
        is( $date4, $f->get_item(1)->pubDate(), "$mode sort #2" );
        $f->get_item(4)->link( $link3 );
        $f->get_item(3)->link( $link3 );
        $f->normalize();
        is( 3, scalar $f->get_item(), "$mode count #3" );
        $f->limit_item( 1 );
        is( 1, scalar $f->get_item(), "$mode count #4" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

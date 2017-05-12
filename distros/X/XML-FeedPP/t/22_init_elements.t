# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 74;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $ftitle = 'Kawa.net XP';
    my $fdesc  = 'Description';
    my $fdateA = 'Mon, 02 Jan 2006 03:04:05 +0600';
    my $fdateB = '2006-01-02T03:04:05+06:00';
    my $fright = 'Owner';
    my $flink  = 'http://www.kawa.net/';
    my $flang  = 'ja';
    my $forgkey = 'hoge:pomu';
    my $forgval = 'Original Namespace: hoge';
# ----------------------------------------------------------------
    my $ilink1  = 'http://kawa.at.webry.info/';
    my $ilink2  = 'http://kawanet.blogspot.com/';
    my $ilink3  = 'http://picasaweb.google.com/www.kawa.net/';
    my $ititle1 = 'Kawa.net Blog (ja)';
    my $ititle2 = 'Kawa.net Blog (en)';
    my $ititle3 = 'Kawa.net Albums';
    my $idateA  = 'Sun, 11 Dec 2005 10:09:08 -0700';
    my $idateB  = '2005-12-11T10:09:08-07:00';
    my $idesc   = 'Description';
    my $icate   = 'Category';
    my $iauthor = 'Author';
    my $iguid   = 'GUID';
    my $iorgkey = 'foo:bar';
    my $iorgval = 'Original Namespace: foo';
# ----------------------------------------------------------------
    my $initfeed = {
        title       =>  $ftitle,
        description =>  $fdesc,
        pubDate     =>  $fdateA,
        copyright   =>  $fright,
        link        =>  $flink,
        language    =>  $flang,
        $forgkey    =>  $forgval,
    };
# ----------------------------------------------------------------
    my $initem1 = {
        link        =>  $ilink1,
        title       =>  $ititle1,
        pubDate     =>  $idateA,
        description =>  $idesc,
        category    =>  $icate,
        author      =>  $iauthor,
        guid        =>  $iguid,
        $iorgkey    =>  $iorgval,
    };
# ----------------------------------------------------------------
    my $initem2 = {
        link        =>  $ilink2,
        title       =>  $ititle2,
        pubDate     =>  $idateB,
    };
# ----------------------------------------------------------------
    my $initem3 = {
        link        =>  $ilink3,
        title       =>  $ititle3,
        pubDate     =>  $idateA,
    };
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RSS->new( %$initfeed ),
        XML::FeedPP::RDF->new( %$initfeed ),
        XML::FeedPP::Atom->new( %$initfeed ),
    ];
# ----------------------------------------------------------------
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        ok( 0 == $feed1->get_item(), "$type Feed has no item" );
        my $item1 = $feed1->add_item( %$initem1 );
        ok( 1 == $feed1->get_item(), "$type Feed has one item" );
        my $item2 = $feed1->add_item( %$initem2 );
        ok( 2 == $feed1->get_item(), "$type Feed has two items" );
        my $item3 = $feed1->add_item( %$initem3 );
        ok( 3 == $feed1->get_item(), "$type Feed has three items" );
# ----------------------------------------------------------------
        is( $feed1->title(),            $ftitle,    "$type Feed title()" );
        is( $feed1->description(),      $fdesc,     "$type Feed description()" );
        is( $feed1->pubDate(),          $fdateB,    "$type Feed pubDate()" );
        is( $feed1->copyright(),        $fright,    "$type Feed copyright()" );
        is( $feed1->link(),             $flink,     "$type Feed link()" );
        is( $feed1->language(),         $flang,     "$type Feed language()" );
        is( $feed1->get($forgkey),      $forgval,   "$type Feed set/get()" );
# ----------------------------------------------------------------
        is( $item1->link(),             $ilink1,    "$type Item1 link()" );
        is( $item1->title(),            $ititle1,   "$type Item1 title()" );
        is( $item1->get_pubDate_w3cdtf(), $idateB,  "$type Item1 pubDate()" );
        is( $item1->description(),      $idesc,     "$type Item1 description()" );
        is( $item1->author(),           $iauthor,   "$type Item1 author()" );
        is( $item1->get($iorgkey),      $iorgval,   "$type Item1 set/get()" );
        if ( $type ne 'XML::FeedPP::Atom' ) {
            is( $item1->category(),     $icate,     "$type Item1 category()" );
        }
        if ( $type ne 'XML::FeedPP::RDF' ) {
            is( $item1->guid(),         $iguid ,    "$type Item1 guid()" );
        }
# ----------------------------------------------------------------
        is( $item2->link(),             $ilink2,    "$type Item2 link()" );
        is( $item2->title(),            $ititle2,   "$type Item2 title()" );
        is( $item2->get_pubDate_rfc1123(), $idateA, "$type Item2 pubDate()" );
# ----------------------------------------------------------------
        is( $item3->link(),             $ilink3,    "$type Item3 link()" );
        is( $item3->title(),            $ititle3,   "$type Item3 title()" );
        is( $item3->get_pubDate_rfc1123(), $idateA, "$type Item3 pubDate()" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

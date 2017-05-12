# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 22;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $flink  = 'http://www.kawa.net/';
    my $ftitle = 'Kawa.net XP';
    my $ilink1  = 'http://kawa.at.webry.info/';
    my $ilink2  = 'http://kawanet.blogspot.com/';
    my $ilink3  = 'http://picasaweb.google.com/www.kawa.net/';
    my $ititle1 = 'Kawa.net Blog (ja)';
    my $ititle2 = 'Kawa.net Blog (en)';
    my $ititle3 = 'Kawa.net Albums';
    my $iorgkey = 'foo:bar';
    my $iorgv1  = 'test #1';
    my $iorgv2  = 'testing #2';
    my $iorgv3  = 'tested #3';
# ----------------------------------------------------------------
    my $initfeed = {
        link        =>  $flink,
        title       =>  $ftitle,
    };
# ----------------------------------------------------------------
    my $initem1 = {
        link        =>  $ilink1,
        title       =>  $ititle1,
        $iorgkey    =>  $iorgv1,
    };
# ----------------------------------------------------------------
    my $initem2 = {
        link        =>  $ilink2,
        title       =>  $ititle2,
        $iorgkey    =>  $iorgv2,
    };
# ----------------------------------------------------------------
    my $initem3 = {
        link        =>  $ilink3,
        title       =>  $ititle3,
        $iorgkey    =>  $iorgv3,
    };
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RSS->new( %$initfeed ),
        XML::FeedPP::RDF->new( %$initfeed ),
        XML::FeedPP::Atom->new( %$initfeed ),
    ];
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        my $item1 = $feed1->add_item( %$initem1 );
        my $item2 = $feed1->add_item( %$initem2 );
        my $item3 = $feed1->add_item( %$initem3 );
# ----------------------------------------------------------------
        my @item8 = $feed1->get_item();
        is( scalar @item8, 3, "$type feed has 3 items" );
# ----------------------------------------------------------------
        my @item4 = $feed1->match_item( link => qr/google.com/i );
        is( scalar @item4, 1, "$type match 1 item by title" );
        is( $item4[0]->link(), $ilink3, "$type match google.com by link" );
# ----------------------------------------------------------------
        my @item5 = $feed1->match_item( title => qr/blog/i );
        is( scalar @item5, 2, "$type match 2 items by title" );
# ----------------------------------------------------------------
        my @item6 = $feed1->match_item( $iorgkey => qr/^test/i );
        is( scalar @item6, 3, "$type match 3 items by $iorgkey" );
# ----------------------------------------------------------------
        my @item7 = $feed1->match_item(
            link     => $ilink2,
            title    => qr/blog/i,
            $iorgkey => qr/testing/i
        );
        is( scalar @item7, 1, "$type match 1 item by 3 args" );
        is( $item7[0]->link(), $ilink2, "$type match blogspot.com by 3 args" );
# ----------------------------------------------------------------
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

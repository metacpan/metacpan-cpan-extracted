# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 49;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $link = "http://www.kawa.net/";
    my $title = "Kawa.net XP";
    my $description = "Yusuke Kawasaki's website";
    my $author = "Yusuke Kawasaki";
    my $pubDate = "2004-11-09T11:33:20Z";
# ----------------------------------------------------------------
    my $media = {
        'media:title'           =>   'Kawa.net xp',
        'media:text'            =>   'Welcome to Kawa.net xp',
        'media:text@type'       =>   'text',
        'media:thumbnail@url'   =>   'http://www.kawa.net/xp/images/xp-title-256.gif',
        'media:thumbnail@width' =>   256,
        'media:thumbnail@height' =>  48,
        'media:content@url'     =>   'http://www.kawa.net/xp/images/xp-title-512.gif',
        'media:content@type'    =>   'image/gif',
        'media:content@width'   =>   512,
        'media:content@height'  =>   96,
    };
# ----------------------------------------------------------------
    my $feed0 = XML::FeedPP::RSS->new();
    $feed0->link( $link );
    my $item0 = $feed0->add_item( $link );
    $item0->title( $title );
    $item0->description( $description );
    $item0->author( $author );
    $item0->pubDate( $pubDate );
    $item0->set( %$media );
# ----------------------------------------------------------------
    my $prev = $item0;
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RSS->new(),
        XML::FeedPP::RDF->new(),
        XML::FeedPP::RDF->new(),
        XML::FeedPP::Atom->new(),
        XML::FeedPP::Atom->new(),
        XML::FeedPP::RSS->new(),
    ];
# ----------------------------------------------------------------
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        $feed1->link( $link );
        my $item1 = $feed1->add_item( $prev );

        is( $item1->link(),         $link,          "$type link" );
        is( $item1->title(),        $title,         "$type title" );
        is( $item1->description(),  $description,   "$type description" );
        is( $item1->author(),       $author,        "$type author" );
        is( $item1->pubDate(),      $pubDate,       "$type pubDate" );
        is( $item1->get('media:title'),       $media->{'media:title'},       "$type media:title" );
        is( $item1->get('media:text'),        $media->{'media:text'},        "$type media:text" );
        is( $item1->get('media:content@url'), $media->{'media:content@url'}, "$type media:content\@url" );

        $prev = $item1;
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

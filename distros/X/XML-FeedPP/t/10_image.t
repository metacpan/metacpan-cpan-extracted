# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 17;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
    my $fdateA = "Mon, 02 Jan 2006 03:04:05 +0600";
    my $fdateB = "2006-01-02T03:04:05+06:00";
    my $fright = "Owner of the site";
    my $flink  = "http://www.kawa.net/";
    my $flang  = "ja";
    my $link1 = "http://www.perl.org/";
    my $title1 = "The Perl Directory - perl.org";
# ----------------------------------------------------------------
    my $image_url   = "http://www.kawa.net/xp/images/mixi-3.jpg";
    my $image_title = "Yusuke Kawasaki";
    my $image_link  = "http://www.kawa.net/";
    my $image_desc  = "Hello from Japan!";
    my $image_width  = 640;
    my $image_height = 480;
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RSS->new();
    $feed1->title( $ftitle );
    $feed1->description( $fdesc );
    $feed1->pubDate( $fdateA );
    $feed1->copyright( $fright );
    $feed1->link( $flink );
    $feed1->language( $flang );
    my $item1 = $feed1->add_item( $link1 );
    $item1->title( $title1 );
    $feed1->image( $image_url, $image_title, $image_link );
    my $source1 = $feed1->to_string();
# ----------------------------------------------------------------
    my @image1 = $feed1->image();
    is( $image1[0], $image_url   , "image_url" );
    is( $image1[1], $image_title , "image_title" );
    is( $image1[2], $image_link  , "image_link" );
# ----------------------------------------------------------------
#   RSS -> RDF
# ----------------------------------------------------------------
    my $feed2 = XML::FeedPP::RDF->new();
    $feed2->merge( $source1 );
    my $source2 = $feed2->to_string();
# ----------------------------------------------------------------
#   RDF -> RSS
# ----------------------------------------------------------------
    my $feed3 = XML::FeedPP::RSS->new();
    $feed3->merge( $source2 );
    my $source3 = $feed3->to_string();
    is( $source1, $source3, "turn round" );
# ----------------------------------------------------------------
    $feed3->image( $image_url, $image_title, $image_link, $image_desc, $image_width, $image_height );
    my @image3 = $feed3->image();
    is( $image3[0], $image_url   , "image_url" );
    is( $image3[1], $image_title , "image_title" );
    is( $image3[2], $image_link  , "image_link" );
    is( $image3[3], $image_desc  , "image_desc" );
    is( $image3[4], $image_width , "image_width" );
    is( $image3[5], $image_height, "image_height" );
# ----------------------------------------------------------------
    my $source4 = $feed3->to_string();
    like( $source4, qr{
        <image[^>]*>.*<url[^>]*>\s*\Q$image_url\E\s*</url>.*</image>
    }xs, "<image><url>" );
    like( $source4, qr{
        <image[^>]*>.*<title[^>]*>\s*\Q$image_title\E\s*</title>.*</image>
    }xs, "<image><title>" );
    like( $source4, qr{
        <image[^>]*>.*<link[^>]*>\s*\Q$image_link\E\s*</link>.*</image>
    }xs, "<image><link>" );
    like( $source4, qr{
        <image[^>]*>.*<description[^>]*>\s*\Q$image_desc\E\s*</description>.*</image>
    }xs, "<image><description>" );
    like( $source4, qr{
        <image[^>]*>.*<width[^>]*>\s*\Q$image_width\E\s*</width>.*</image>
    }xs, "<image><width>" );
    like( $source4, qr{
        <image[^>]*>.*<height[^>]*>\s*\Q$image_height\E\s*</height>.*</image>
    }xs, "<image><height>" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

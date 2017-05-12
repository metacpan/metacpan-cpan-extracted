# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 32;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
    my $fdateA = "Mon, 02 Jan 2006 03:04:05 +0600";
    my $fdateB = "2006-01-02T03:04:05+06:00";
    my $fright = "Owner of the site";
    my $flink  = "http://www.kawa.net/";
    my $flang  = "ja";
# ----------------------------------------------------------------
    my $link1 = "http://www.perl.org/";
    my $link2  = "http://use.perl.org/";
    my $link3 = "http://cpan.perl.org/";
    my $title1 = "The Perl Directory - perl.org";
    my $title2 = "use Perl: All the Perl that's Practical to Extract and Report";
    my $title3 = "The Comprehensive Perl Archive Network";
# ----------------------------------------------------------------
    my $idesc  = "Description of the first item";
    my $icate  = "Category of the first item";
    my $idateA = "Sun, 11 Dec 2005 10:09:08 -0700";
    my $idateB = "2005-12-11T10:09:08-07:00";
    my $iauthor = "Author";
    my $iguid   = "GUID";
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RDF->new();
    $feed1->title( $ftitle );
    $feed1->description( $fdesc );
    $feed1->pubDate( $fdateB );
    $feed1->copyright( $fright );
    $feed1->link( $flink );
    $feed1->language( $flang );
# ----------------------------------------------------------------
    ok( 0 == $feed1->get_item(), "0 item" );
# ----------------------------------------------------------------
    my $item1 = $feed1->add_item( $link1 );
    $item1->title( $title1 );
    $item1->pubDate( $idateB );
    ok( 1 == $feed1->get_item(), "1 item" );
# ----------------------------------------------------------------
    $item1->description( $idesc );
    $item1->category( $icate );
    $item1->author( $iauthor, isPermaLink => "false" );
    $item1->guid( $iguid );
# ----------------------------------------------------------------
    my $item2 = $feed1->add_item( $link2 );
    $item2->title( $title2 );
    $item2->pubDate( $idateA );
    ok( 2 == $feed1->get_item(), "2 items" );
# ----------------------------------------------------------------
    my $item3 = $feed1->add_item( $link3 );
    $item3->title( $title3 );
    $item3->pubDate( $idateA );
    ok( 3 == $feed1->get_item(), "3 items" );
# ----------------------------------------------------------------
    my $source1 = $feed1->to_string();
    my $feed2 = XML::FeedPP::RDF->new( $source1 );
    ok( 3 == $feed2->get_item(), "3 items" );
# ----------------------------------------------------------------
    is( $feed2->title(),            $ftitle,    "RDF->title()" );
    is( $feed2->description(),      $fdesc,     "RDF->description()" );
    is( $feed2->pubDate(),          $fdateB,    "RDF->pubDate()" );
    is( $feed2->copyright(),        $fright,    "RDF->copyright()" );
    is( $feed2->link(),             $flink,     "RDF->link()" );
    is( $feed2->language(),         $flang,     "RDF->language()" );
# ----------------------------------------------------------------
    my $item4 = $feed2->get_item( 0 );
# ----------------------------------------------------------------
    is( $item4->link(),             $link1,     "Item->title()" );
    is( $item4->title(),            $title1,    "Item->title()" );
    is( $item4->pubDate(),          $idateB,    "Item->pubDate()" );
    is( $item4->description(),      $idesc,     "Item->description()" );
    is( $item4->category(),         $icate,     "Item->category()" );
    is( $item4->author(),           $iauthor,   "Item->author()" );
    is( $item4->guid(),             undef,      "Item->guid()" );
# ----------------------------------------------------------------
    my $source2 = $feed1->to_string();
    is( $source1, $source2, "turn around - rss source." );
# ----------------------------------------------------------------
    like( $source2, qr/<title[^>]*>\s*       \Q$ftitle\E/x,  "<title>" );
    like( $source2, qr/<description[^>]*>\s* \Q$fdesc\E/x,   "<description>" );
    like( $source2, qr/<dc:date[^>]*>\s*     \Q$fdateB\E/x,  "<dc:date>" );
    like( $source2, qr/<dc:rights[^>]*>\s*   \Q$fright\E/x,  "<dc:rights>" );
    like( $source2, qr/<link[^>]*>\s*        \Q$flink\E/x,   "<link>" );
    like( $source2, qr/<dc:lang[^>]*>\s*     \Q$flang\E/x,   "<dc:lang>" );
# ----------------------------------------------------------------
    like( $source2, qr/<link[^>]*>\s*        \Q$link1\E/x,   "<link>" );
    like( $source2, qr/<title[^>]*>\s*       \Q$title1\E/x,  "<title>" );
    like( $source2, qr/<dc:date[^>]*>\s*     \Q$idateB\E/x,  "<dc:date>" );
    like( $source2, qr/<description[^>]*>\s* \Q$idesc\E/x,   "<description>" );
    like( $source2, qr/<dc:subject[^>]*>\s*  \Q$icate\E/x,   "<dc:subject>" );
    like( $source2, qr/<dc:creator[^>]*>\s*     \Q$iauthor\E/x, "<creator>" );
#   like( $source2, qr/<guid[^>]*>\s*        \Q$iguid\E/x,   "<guid>" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

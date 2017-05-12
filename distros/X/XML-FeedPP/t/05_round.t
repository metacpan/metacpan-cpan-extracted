# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 21;
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
    my $feed1 = XML::FeedPP::RSS->new();
    $feed1->title( $ftitle );
    $feed1->description( $fdesc );
    $feed1->pubDate( $fdateA );
    $feed1->copyright( $fright );
    $feed1->link( $flink );
    $feed1->language( $flang );
# ----------------------------------------------------------------
    my $item1 = $feed1->add_item( $link1 );
    $item1->title( $title1 );
    $item1->pubDate( $idateA );
    $item1->description( $idesc );
    $item1->category( $icate );
    $item1->author( $iauthor, isPermaLink => "false" );
    $item1->guid( $iguid );
# ----------------------------------------------------------------
    ok( 1 == scalar $feed1->get_item(), "RSS 1st" );
    my $source1 = $feed1->to_string();
# ----------------------------------------------------------------
#   Round1: RSS -> RDF -> Atom -> RSS (w/1item)
# ----------------------------------------------------------------
    my $feed2 = XML::FeedPP::RDF->new();
    $feed2->merge( $source1 );
    ok( 1 == $feed2->get_item(), "RDF 1st" );
    my $source2 = $feed2->to_string();
    my $feed3 = XML::FeedPP::Atom->new();
    $feed3->merge( $source2 );
    ok( 1 == $feed3->get_item(), "Atom 1st" );
    my $source3 = $feed3->to_string();
    my $feed4 = XML::FeedPP::RSS->new();
    $feed4->merge( $source3 );
    ok( 1 == $feed4->get_item(), "RSS 2nd A" );
# ----------------------------------------------------------------
    my $item2 = $feed4->add_item( $link2 );
    $item2->title( $title2 );
    $item2->pubDate( $idateA );
    my $item3 = $feed4->add_item( $link3 );
    $item3->title( $title3 );
    $item3->pubDate( $idateA );
    ok( 3 == $feed4->get_item(), "RSS 2nd B" );
# ----------------------------------------------------------------
#   Round2: RSS -> Atom -> RDF -> RSS (w/3items)
# ----------------------------------------------------------------
    my $source4 = $feed4->to_string();
    my $feed5 = XML::FeedPP::Atom->new();
    $feed5->merge( $source4 );
    ok( 3 == $feed5->get_item(), "Atom 2nd" );
    my $source5 = $feed5->to_string();
    my $feed6 = XML::FeedPP::RDF->new();
    $feed6->merge( $source5 );
    ok( 3 == $feed6->get_item(), "RDF 2nd" );
    my $source6 = $feed6->to_string();
    my $feed7 = XML::FeedPP::RSS->new();
    $feed7->merge( $source6 );
    ok( 3 == $feed7->get_item(), "RSS 3rd" );
    my $source7 = $feed7->to_string();
# ----------------------------------------------------------------
    is( $source4, $source7, "turn round" );
    is( $feed7->title(),            $ftitle,    "RSS->title()" );
    is( $feed7->description(),      $fdesc,     "RSS->description()" );
    is( $feed7->pubDate(),          $fdateB,    "RSS->pubDate()" );
    is( $feed7->copyright(),        $fright,    "RSS->copyright()" );
    is( $feed7->link(),             $flink,     "RSS->link()" );
    is( $feed7->language(),         $flang,     "RSS->language()" );
# ----------------------------------------------------------------
    my $item7 = $feed7->get_item( 0 );
    is( $item7->link(),             $link1,     "Item->title()" );
    is( $item7->title(),            $title1,    "Item->title()" );
    is( $item7->pubDate(),          $idateB,    "Item->pubDate()" );
    is( $item7->description(),      $idesc,     "Item->description()" );
    is( $item7->author(),           $iauthor,   "Item->author()" );
# ----------------------------------------------------------------
#   use Data::Dumper;
#   my $text = Dumper( $feed1 );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

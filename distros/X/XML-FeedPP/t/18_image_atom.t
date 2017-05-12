# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 12;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $f_title = "Title of the site";
    my $f_link  = "http://www.kawa.net/";
    my $f_image   = "http://www.kawa.net/xp/images/mixi-3.jpg";
# ----------------------------------------------------------------
    my $i_link = "http://www.perl.org/";
    my $i_title = "The Perl Directory - perl.org";
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::Atom->new();
    $feed1->title( $f_title );
    $feed1->link( $f_link );
    $feed1->image( $f_image );
    my $item1 = $feed1->add_item( $i_link );
    $item1->title( $i_title );
# ----------------------------------------------------------------
    is( scalar $feed1->link(),  $f_link,  "Atom link 1" );
    is( scalar $feed1->image(), $f_image, "Atom image 1" );
    $feed1->image( $f_image );
    $feed1->link( $f_link );
    is( scalar $feed1->link(),  $f_link,  "Atom link 2" );
    is( scalar $feed1->image(), $f_image, "Atom image 2" );
# ----------------------------------------------------------------
#   Atom -> RDF -> Atom
# ----------------------------------------------------------------
    my $feed2 = XML::FeedPP::RDF->new();
    $feed2->merge( $feed1->to_string() );
    is( scalar $feed2->image(), $f_image, "RDF image" );
# ----------------------------------------------------------------
    my $feed3 = XML::FeedPP::Atom->new();
    $feed3->merge( $feed2->to_string() );
    is( scalar $feed1->link(),  $f_link,  "Atom link 3" );
    is( scalar $feed3->image(), $f_image, "Atom image 3" );
# ----------------------------------------------------------------
#   Atom -> RSS -> Atom
# ----------------------------------------------------------------
    my $feed4 = XML::FeedPP::RSS->new();
    $feed4->merge( $feed1->to_string() );
    is( scalar $feed4->image(), $f_image, "RSS image" );
# ----------------------------------------------------------------
    my $feed5 = XML::FeedPP::Atom->new();
    $feed5->merge( $feed4->to_string() );
    is( scalar $feed1->link(),  $f_link,  "Atom link 4" );
    is( scalar $feed5->image(), $f_image, "Atom image 4" );
# ----------------------------------------------------------------
    is( $feed3->to_string(), $feed5->to_string(), "Atom source" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

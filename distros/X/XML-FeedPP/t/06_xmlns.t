# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 19;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
# ----------------------------------------------------------------
	my $xmlns_media = 'http://search.yahoo.com/mrss';
	my $xmlns_taxo  = 'http://purl.org/rss/1.0/modules/taxonomy/';
	my $xmlns_syn   = 'http://purl.org/rss/1.0/modules/syndication/';
# ----------------------------------------------------------------
    my $feed1 = XML::FeedPP::RSS->new();
    $feed1->title( $ftitle );
	my $xmlns1 = $feed1->xmlns();
	is( join(" ",sort $feed1->xmlns()), "", "RSS xmlns=".$xmlns1 );
	$feed1->xmlns( 'xmlns:syn' => $xmlns_syn );
	is( $xmlns_syn, $feed1->xmlns('xmlns:syn'), 'RSS xmlns:syn' );
	ok( $xmlns1+1 == scalar $feed1->xmlns(), 'RSS +1' );
	my $source1 = $feed1->to_string();
	like( $source1, qr{ <rss [^>]+ xmlns:syn="\Q$xmlns_syn\E" }x, 'RSS to_string' );
# ----------------------------------------------------------------
    my $feed2 = XML::FeedPP::RDF->new();
    $feed2->title( $ftitle );
	my $xmlns2 = $feed2->xmlns();
	is( join(" ",sort $feed2->xmlns()), "xmlns xmlns:dc xmlns:rdf", "RDF xmlns=".$xmlns2 );
	$feed2->xmlns( 'xmlns:taxo' => $xmlns_taxo );
	is( $xmlns_taxo, $feed2->xmlns('xmlns:taxo'), 'RDF xmlns:taxo' );
	ok( $xmlns2+1 == scalar $feed2->xmlns(), 'RDF +1' );
	my $source2 = $feed2->to_string();
	like( $source2, qr{ <rdf:RDF [^>]+ xmlns:taxo="\Q$xmlns_taxo\E" }x, 'RDF to_string' );
# ----------------------------------------------------------------
    my $feed3 = XML::FeedPP::Atom->new();
    $feed3->title( $ftitle );
	my $xmlns3 = $feed3->xmlns();
	is( join(" ",sort $feed3->xmlns()), "xmlns", "Atom xmlns=".$xmlns3 );
	$feed3->xmlns( 'xmlns:media' => $xmlns_media );
	is( $xmlns_media, $feed3->xmlns('xmlns:media'), 'Atom xmlns:media' );
	ok( $xmlns3+1 == scalar $feed3->xmlns(), 'Atom +1' );
	my $source3 = $feed3->to_string();
	like( $source3, qr{ <feed [^>]+ xmlns:media="\Q$xmlns_media\E" }x, 'RDF to_string' );
# ----------------------------------------------------------------
	$feed1->merge( $source2 );
	is( $xmlns_taxo, $feed1->xmlns('xmlns:taxo'), 'RSS xmlns:taxo' );
	$feed1->merge( $source3 );
	ok( $xmlns1+3 == scalar $feed1->xmlns(), 'RSS +3' );
# ----------------------------------------------------------------
	$feed2->merge( $source3 );
	is( $xmlns_media, $feed2->xmlns('xmlns:media'), 'RDF xmlns:media' );
	$feed2->merge( $source1 );
	ok( $xmlns2+3 == scalar $feed2->xmlns(), 'RDF +3' );
# ----------------------------------------------------------------
	$feed3->merge( $source1 );
	is( $xmlns_syn, $feed1->xmlns('xmlns:syn'), 'Atom xmlns:syn' );
	$feed3->merge( $source2 );
	ok( $xmlns3+3 == scalar $feed3->xmlns(), 'Atom +3' );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

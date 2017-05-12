# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 13;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
	my $invalid = <<'EOT';
<?xml version="1.0" encoding="UTF-8" ?> 
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
    xmlns:cc="http://web.resource.org/cc/"
    xmlns="http://purl.org/rss/1.0/"
    xml:lang="ja">
    <channel rdf:about="http://www.cnc.co.jp/news/xml/rss.xml">
        <dc:language>ja</dc:language>
        <dc:date>2008-03-24T16:54:33 +0900</dc:date>
        <items>
            <rdf:Seq>
                <rdf:li rdf:resource="http://www.example.com/sample1.html" />
            </rdf:Seq>
            <rdf:Seq>
                <rdf:li rdf:resource="http://www.example.com/sample2.html" />
            </rdf:Seq>
            <rdf:Seq>
                <rdf:li rdf:resource="http://www.example.com/sample3.html" />
            </rdf:Seq>
        </items>
    </channel>
    <item rdf:about="http://www.example.com/sample1.html">
        <title>sample item #1</title> 
        <link>http://www.example.com/sample1.html</link>
        <dc:date>2008-03-24T16:54:33 +0900</dc:date>
    </item>
    <item rdf:about="http://www.example.com/sample2.html">
        <title>sample item #2</title> 
        <link>http://www.example.com/sample2.html</link>
        <dc:date>2008-02-29T18:21:38 +0900</dc:date>
    </item>
    <item rdf:about="http://www.example.com/sample3.html">
        <title>sample item #3</title> 
        <link>http://www.example.com/sample3.html</link>
        <dc:date>2008-02-25T11:54:15 +0900</dc:date>
    </item>
</rdf:RDF>
EOT
# ----------------------------------------------------------------
	my $valid = <<'EOT';
<?xml version="1.0" encoding="UTF-8" ?> 
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
    xmlns:cc="http://web.resource.org/cc/"
    xmlns="http://purl.org/rss/1.0/"
    xml:lang="ja">
    <channel rdf:about="http://www.cnc.co.jp/news/xml/rss.xml">
        <dc:language>ja</dc:language>
        <dc:date>2008-03-24T16:54:33+09:00</dc:date>
        <items>
            <rdf:Seq>
                <rdf:li rdf:resource="http://www.example.com/sample1.html" />
                <rdf:li rdf:resource="http://www.example.com/sample2.html" />
                <rdf:li rdf:resource="http://www.example.com/sample3.html" />
            </rdf:Seq>
        </items>
    </channel>
    <item rdf:about="http://www.example.com/sample1.html">
        <title>sample item #1</title> 
        <link>http://www.example.com/sample1.html</link>
        <dc:date>2008-03-24T16:54:33+09:00</dc:date>
    </item>
    <item rdf:about="http://www.example.com/sample2.html">
        <title>sample item #2</title> 
        <link>http://www.example.com/sample2.html</link>
        <dc:date>2008-02-29T18:21:38+09:00</dc:date>
    </item>
    <item rdf:about="http://www.example.com/sample3.html">
        <title>sample item #3</title> 
        <link>http://www.example.com/sample3.html</link>
        <dc:date>2008-02-25T11:54:15+09:00</dc:date>
    </item>
</rdf:RDF>
EOT
# ----------------------------------------------------------------
    my $vfeed = XML::FeedPP->new( $valid );
    is( $vfeed->pubDate, '2008-03-24T16:54:33+09:00', 'valid feed pubDate' );
    is( scalar $vfeed->get_item(), 3, 'valid feed item number' );
    my $vitem = $vfeed->get_item( 2 );
    is( $vitem->title, 'sample item #3', 'valid item title' );
    is( $vitem->pubDate, '2008-02-25T11:54:15+09:00', 'valid item pubDate' );
# ----------------------------------------------------------------
    my $ifeed = XML::FeedPP->new( $invalid );
    is( $ifeed->pubDate, '2008-03-24T16:54:33 +0900', 'invalid feed pubDate' );
    is( scalar $ifeed->get_item(), 3, 'invalid feed item number' );
    my $iitem = $ifeed->get_item( 2 );
    is( $iitem->title, 'sample item #3', 'invalid item title' );
    is( $iitem->pubDate, '2008-02-25T11:54:15 +0900', 'invalid item pubDate' );
# ----------------------------------------------------------------
    my $isource = $ifeed->to_string();
    my $rss = XML::FeedPP::RSS->new();
    $rss->merge( $isource );
    my $rsource = $rss->to_string();
    my $rfeed = XML::FeedPP::RDF->new();
    $rfeed->merge( $rsource );
# ----------------------------------------------------------------
    is( $rfeed->pubDate, '2008-03-24T16:54:33+09:00', 'round trip feed pubDate' );
    is( scalar $rfeed->get_item(), 3, 'round trip feed item number' );
    my $ritem = $rfeed->get_item( 2 );
    is( $ritem->title, 'sample item #3', 'round trip item title' );
    is( $ritem->pubDate, '2008-02-25T11:54:15+09:00', 'round trip item pubDate' );
# ----------------------------------------------------------------

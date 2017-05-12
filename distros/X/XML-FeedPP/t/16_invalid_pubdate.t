# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 13;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $date110w = "2004-11-09T11:33:20Z";              # 1100000000
    my $date110h = "Tue, 09 Nov 2004 11:33:20 GMT";
    my $date111w = "2005-03-05T14:20:00+09:00";         # 1110000000
    my $date111h = "Sat, 05 Mar 2005 14:20:00 +0900";
    my $date112w = "2005-06-29T08:06:30-09:00";         # 1120000000
    my $date112h = "Wed, 29 Jun 2005 08:06:30 -0900";
    my $date113w = "2005-10-23T01:53:20Z";              # 1130000000
    my $date113h = "Sun, 23 Oct 2005 01:53:20 GMT";
    my $date114w = "2006-02-15T19:40:00Z";              # 1140000000
    my $date114h = "Wed, 15 Feb 2006 19:40:00 GMT";
# ----------------------------------------------------------------
    my $url = "http://www.kawa.net/";
# ----------------------------------------------------------------
    my $src_rss = <<"EOT";
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
    <channel>
        <link>$url</link>
        <pubDate>$date110w</pubDate>
        <item>
            <link>$url</link>
            <pubDate>$date111w</pubDate>
        </item>
    </channel>
</rss>
EOT
# ----------------------------------------------------------------
    my $src_rdf = <<"EOT";
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns="http://purl.org/rss/1.0/">
    <channel rdf:about="$url">
        <link>$url</link>
        <dc:date>$date112h</dc:date>
        <rdf:Seq>
        <rdf:li rdf:resource="$url" />
        </rdf:Seq>
    </channel>
    <item rdf:about="$url">
        <link>$url</link>
        <dc:date>$date113h</dc:date>
    </item>
</rdf:RDF>
EOT
# ----------------------------------------------------------------
    my $src_atom = <<"EOT";
<?xml version="1.0" encoding="utf-8"?>
<feed version="0.3" xmlns="http://purl.org/atom/ns#">
    <link rel="alternate" type="text/html" href="$url"/>
    <modified>$date114h</modified>
    <entry>
        <link rel="alternate" type="text/html" href="$url"/>
        <issued>$date110h</issued>
        <modified>$date111h</modified>
    </entry>
</feed>
EOT
# ----------------------------------------------------------------
    my $feed_rss = XML::FeedPP->new( $src_rss );
    $feed_rss->normalize();
    is( $feed_rss->pubDate(), $date110w, "rss channel pubDate()" );
    my $item_rss = $feed_rss->get_item(0);
    is( $item_rss->pubDate(), $date111w, "rss item pubDate()" );
    my $out_rss = $feed_rss->to_string();
    ok( $out_rss =~ /\Q$date110h\E/, "rss channel to_string()" );
    ok( $out_rss =~ /\Q$date111h\E/, "rss item to_string()" );
# ----------------------------------------------------------------
    my $feed_rdf = XML::FeedPP->new( $src_rdf );
    $feed_rdf->normalize();
    is( $feed_rdf->pubDate(), $date112w, "rdf channel pubDate()" );
    my $item_rdf = $feed_rdf->get_item(0);
    is( $item_rdf->pubDate(), $date113w, "rdf item pubDate()" );
    my $out_rdf = $feed_rdf->to_string();
    ok( $out_rdf =~ /\Q$date112w\E/, "rdf channel to_string()" );
    ok( $out_rdf =~ /\Q$date113w\E/, "rdf item to_string()" );
# ----------------------------------------------------------------
    my $feed_atom = XML::FeedPP->new( $src_atom );
    $feed_atom->normalize();
    is( $feed_atom->pubDate(), $date114w, "atom channel pubDate()" );
    my $item_atom = $feed_atom->get_item(0);
    is( $item_atom->pubDate(), $date111w, "atom item pubDate()" );
    my $out_atom = $feed_atom->to_string();
    ok( $out_atom =~ /\Q$date114w\E/, "atom channel to_string()" );
    ok( $out_atom =~ /\Q$date111w\E/, "atom item to_string()" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

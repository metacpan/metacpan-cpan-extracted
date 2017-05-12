#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 33;

BEGIN { use_ok('XML::RSS::Feed') }

SKIP: {
    skip "/tmp directory not writeable", 32 unless -d "/tmp" && -w "/tmp";
    $SIG{__WARN__} = build_warn("could not cache");
    my $feed_bad_name = XML::RSS::Feed->new(
        name   => 'test_008/_title',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );
    isa_ok( $feed_bad_name, "XML::RSS::Feed" );
    ok( $feed_bad_name->parse( xml(1) ), "Parsed XML" );
    ok( !$feed_bad_name->cache, "Did Not Cache File" );

    my $feed_bad_tmpdir = XML::RSS::Feed->new(
        name   => 'test_008_title',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/fake/directory/that/no/one/will/actually/have",
    );
    isa_ok( $feed_bad_tmpdir, "XML::RSS::Feed" );
    ok( !$feed_bad_tmpdir->cache, "Did Not Cache File" );

    unlink "/tmp/test_008_title.sto";
    my $feed_title = XML::RSS::Feed->new(
        name   => 'test_008_title',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );
    isa_ok( $feed_title, "XML::RSS::Feed" );
    ok( !$feed_title->cache,          "Did Not Cache File" );
    ok( $feed_title->parse( xml(1) ), "Parsed XML" );
    ok( $feed_title->cache,           "Successfully Cached File" );

    my $feed_no_title = XML::RSS::Feed->new(
        name   => 'test_008_title',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );
    isa_ok( $feed_no_title, "XML::RSS::Feed" );

    my $feed_title_cache = XML::RSS::Feed->new(
        title  => 'Some Stupid Title',
        name   => 'test_008_title',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );
    isa_ok( $feed_title_cache, "XML::RSS::Feed" );

    unlink "/tmp/test_008.sto";
    my $feed = XML::RSS::Feed->new(
        name   => 'test_008',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );

    isa_ok( $feed, 'XML::RSS::Feed' );

    my $rss_xml = xml(2);

    ok( $feed->parse($rss_xml), "Failed to parse XML from " . $feed->url );
    cmp_ok( $feed->num_headlines, '==', 10,
        "Verify correct number of headlines" );
    cmp_ok( $feed->late_breaking_news, '==', 10,
        "Verify mark_all_headlines_read" );

    my @headlines_old = map { $_->headline } $feed->headlines;
    my $num_headlines = $feed->num_headlines;
    my @seen_old      = map { $_->first_seen_hires } $feed->headlines;
    $feed->cache;

    my $feed2 = XML::RSS::Feed->new(
        name   => 'test_008',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );
    isa_ok( $feed2, 'XML::RSS::Feed' );
    cmp_ok( $num_headlines, '==', $feed2->num_headlines,
        "Compare after restoring cache" );

    my $feed3 = XML::RSS::Feed->new(
        name   => 'test_008',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => "/tmp",
    );
    isa_ok( $feed3, 'XML::RSS::Feed' );
    cmp_ok( $num_headlines, '==', $feed3->num_headlines,
        "Compare after restoring cache" );

    unlink "/tmp/test_008.sto";
    my @headlines_new = map { $_->headline } $feed2->headlines;
    my @seen_new      = map { $_->first_seen_hires } $feed2->headlines;

    ok( eq_array( \@headlines_old, \@headlines_new ),
        "Comparing headlines before and after"
    );

    for my $i ( 0 .. $#seen_old ) {
        my $num = $i + 1;
        cmp_ok( $seen_old[$i], '==', $seen_new[$i],
            "Compare headline $num timestamp_hires" );
    }
}

sub xml {
    my ($index) = @_;
    $index--;
    return (
        qq|<?xml version="1.0" encoding="ISO-8859-1"?>

<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<link>http://slashdot.org/</link>
<description>News for nerds, stuff that matters</description>
</channel>

<image>
<title>Slashdot</title>
<url>http://images.slashdot.org/topics/topicslashdot.gif</url>
<link>http://slashdot.org/</link>
</image>

<item>
<title>States Link Databases to Find Tax Cheats</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/2021256</link>
</item>

<item>
<title>Invulnerable, Waterproof PDA</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1814258</link>
</item>

<item>
<title>Still More on Open Source Usability</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1811226</link>
</item>

<item>
<title>Moore's Law Limits Pushed Back Again</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/182224</link>
</item>

<item>
<title>Advanced Mobile Phone Tech in Japan</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1754231</link>
</item>

<item>
<title>Computerized Time Clocks Susceptible to 'Manager Attack'</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1655231</link>
</item>

<item>
<title>A Completely Separate Ecosystem on Earth</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1653233</link>
</item>

<item>
<title>3D, FPS File Manager</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1621251</link>
</item>

<item>
<title>Searching by Shape...</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1423210</link>
</item>

<item>
<title>New Wave of Web Ads?</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/1410251</link>
</item>

<textinput>
<title>Search Slashdot</title>
<description>Search Slashdot stories</description>
<name>query</name>
<link>http://slashdot.org/search.pl</link>
</textinput>

</rdf:RDF>|,
        q|<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>jbisbee.com</title>
<link>http://www.jbisbee.com/</link>
<description>Testing XML::RSS::Feed</description>
</channel>

<item>
<title>Wednesday 03rd of November 2004 08:48:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540080</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540050</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540020</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539990</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539960</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539930</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539900</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539870</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539840</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:43:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539810</link>
</item>
 

</rdf:RDF>|,
        q|<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>jbisbee.com</title>
<link>http://www.jbisbee.com/</link>
<description>Testing XML::RSS::Feed</description>
</channel>

<item>
<title>Wednesday 03rd of November 2004 08:48:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540110</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:48:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540080</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540050</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540020</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539990</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539960</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539930</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539900</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539870</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539840</link>
</item>
</rdf:RDF>|,
    )[$index];
}

sub build_warn {
    my @args = @_;
    return sub { my ($warn) = @_; like( $warn, qr/$_/i, $_ ) for @args };
}

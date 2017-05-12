#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 35;

BEGIN { use_ok('XML::RSS::Feed') }

$SIG{__WARN__} = build_warn("jbisbee");
my $feed = XML::RSS::Feed->new(
    url           => "http://www.jbisbee.com/rdf/",
    name          => 'jbisbee',
    debug         => 1,
    max_headlines => 10,
);
isa_ok( $feed, 'XML::RSS::Feed' );
ok( $feed->parse( xml(1) ), "Parse XML" );
ok( $feed->parse( xml(2) ), "Parse XML" );

$SIG{__WARN__} = build_warn("test_018_debug");
SKIP: {
    skip "/tmp directory doesn't exist", 26 unless -d "/tmp";

    unlink "/tmp/test_018_debug_legacy";
    unlink "/tmp/test_018_debug_legacy.sto";
    my $xml = xml(1);
    open my $fh, ">/tmp/test_018_debug_legacy";
    print $fh $xml;
    close $fh;

    my $feed_legacy_cache = XML::RSS::Feed->new(
        name   => 'test_018_debug_legacy',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => '/tmp',
        debug  => 1,
    );
    isa_ok( $feed_legacy_cache, 'XML::RSS::Feed' );
    ok( $feed_legacy_cache->num_headlines == 10,
        "making sure legacy caching still works"
    );

    my $feed_bad_name = XML::RSS::Feed->new(
        name   => 'test_018_debug/bad_name',
        url    => "http://www.jbisbee.com/rsstest",
        debug  => 1,
        tmpdir => "/tmp",
    );
    isa_ok( $feed_bad_name, "XML::RSS::Feed" );
    ok( $feed_bad_name->parse( xml(1) ), "Parse XML" );
    ok( !$feed_bad_name->cache, "Did Not Cache File" );

    unlink "/tmp/test_018_debug.sto";
    my $feed_title = XML::RSS::Feed->new(
        name   => 'test_018_debug',
        url    => "http://www.jbisbee.com/rsstest",
        debug  => 1,
        tmpdir => "/tmp",
    );
    isa_ok( $feed_title, "XML::RSS::Feed" );
    ok( $feed_title->parse( xml(1) ), "Parsed XML" );
    ok( $feed_title->cache, "Successfully Cached File" );

    my $feed_no_title = XML::RSS::Feed->new(
        name   => 'test_018_debug',
        url    => "http://www.jbisbee.com/rsstest",
        debug  => 1,
        tmpdir => "/tmp",
    );
    isa_ok( $feed_no_title, "XML::RSS::Feed" );

}

sub build_warn {
    my @args = @_;
    return sub { my ($warn) = @_; like( $warn, qr/$_/i, $_ ) for @args };
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
<title>States Link Databases to Find Tax Cheats Taxing Cheaters</title>
<link>http://slashdot.org/article.pl?sid=04/04/04/202125adfad</link>
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

</rdf:RDF>|
    )[$index];
}

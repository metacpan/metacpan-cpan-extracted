#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require File::Temp; };
    my $file_temp = $@ ? 0 : 1;
    sub TEST_LEGACY {$file_temp}
}

if (TEST_LEGACY) {
    plan tests => 3;
    use_ok("XML::RSS::Feed");

    my $dir  = File::Temp::tempdir( CLEANUP => 1 );
    my $name = 'jbisbee_test';
    my $rss  = do { local $/, <DATA> };

    open my $fh, ">", $dir . '/' . $name;
    print $fh $rss;
    close $fh;

    my $feed = XML::RSS::Feed->new(
        name   => 'jbisbee_test',
        url    => "http://www.jbisbee.com/rsstest",
        tmpdir => $dir,
    );
    isa_ok( $feed, 'XML::RSS::Feed' );
    ok( $feed->num_headlines == 10, "making sure legacy caching still works" );
}
else {
    plan skip_all => "File::Temp required";
}

__DATA__
<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>jbisbee.com</title>
<link>http://www.jbisbee.com/</link>
<description>Testing XML::RSS::Feed</description>
</channel>

<item>
<title>Wednesday 23rd of June 2004 06:21:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036490</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:21:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036460</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:20:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036430</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:20:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036400</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:19:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036370</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:19:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036340</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:18:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036310</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:18:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036280</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:17:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036250</link>
</item>
<item>
<title>Wednesday 23rd of June 2004 06:17:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1088036220</link>
</item>
 

</rdf:RDF>

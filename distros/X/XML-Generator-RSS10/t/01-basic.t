use strict;
use warnings;

use XML::Generator::RSS10;

use Test::More;

BEGIN {
    eval { require XML::SAX::Writer };

    if ($@) {
        plan skip_all => 'Cannot run tests without XML::SAX::Writer.';
    }
    else {
    }
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new( Handler => $writer, pretty => 1 );

    $gen->item(
        title => 'Item title',
        link  => 'http://example.com/foo',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'channel description',
    );

    like(
        $out, qr/<\?xml\s+version=.1\.0.\?>/s,
        'has processing instruction'
    );

    like(
        $out, qr{rdf:RDF[^>]+xmlns=.http://purl.org/rss/1.0/.}s,
        'has rdf:RDF tag with proper namespace'
    );

    my %ns = (
        dc  => 'http://purl.org/dc/elements/1.1/',
        sy  => 'http://purl.org/rss/1.0/modules/syndication/',
        rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    );

    while ( my ( $p, $uri ) = each %ns ) {
        like(
            $out, qr{xmlns:\Q$p\E=.\Q$uri\E.}s,
            "expect to find $p namespace declaration"
        );
    }

    like(
        $out, qr{<item\s+rdf:about=.http://example.com/foo.\s*>}s,
        'expect to find item tag'
    );

    like(
        $out, qr{<item[^>]+>.*<title>Item title</title>.*</item>}s,
        'expect to find title tag inside item tag'
    );

    like(
        $out, qr{<item[^>]+>.*<link>http://example\.com/foo</link>.*</item>}s,
        'expect to find link tag inside item tag'
    );

    like(
        $out, qr{<channel\s+rdf:about=.http://example\.com/.>}s,
        'expect to find channel tag'
    );

    like(
        $out, qr{<channel[^>]+>.*<title>Channel title</title>.*</channel>}s,
        'expect to find title tag inside channel tag'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<link>http://example\.com/</link>.*</channel>}s,
        'expect to find link tag inside channel tag'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<description><!\[CDATA\[channel description\]\]></description>.+</channel>}s,
        'expect to find description tag inside channel tag'
    );

    like(
        $out, qr{<channel[^>]+>.*<items>\s*<rdf:Seq>.*</channel>}s,
        'expect to find items & rdf:Seq tags inside channel tag'
    );

    like(
        $out,
        qr{<items>\s*<rdf:Seq>\s*<rdf:li\s+rdf:resource=.http://example\.com/foo.}s,
        'expect to find rdf:li tag inside channel rdf:Seq'
    );
}

done_testing();

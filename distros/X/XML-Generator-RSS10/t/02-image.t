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

    $gen->image(
        title => 'Image title',
        url   => 'http://example.com/image.jpg',
        link  => 'http://example.com/bar',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    like(
        $out, qr{<image\s*rdf:about=.http://example\.com/image\.jpg.>}s,
        'expect to find image tag'
    );

    like(
        $out, qr{<image[^>]+>.*<title>Image title</title>.*</image>}s,
        'expect to find title tag inside image tag'
    );

    like(
        $out,
        qr{<image[^>]+>.*<url>http://example\.com/image\.jpg</url>.*</image>}s,
        'expect to find url tag inside image tag'
    );

    like(
        $out,
        qr{<image[^>]+>.*<link>http://example\.com/bar</link>.*</image>}s,
        'expect to find link tag inside image tag'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<image\s*rdf:resource=.http://example\.com/image\.jpg.*</channel>}s,
        'expect to find image tag inside channel tag'
    );
}

done_testing();

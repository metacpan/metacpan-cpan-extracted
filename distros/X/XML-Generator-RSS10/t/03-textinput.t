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

    $gen->textinput(
        title       => 'Textinput title',
        name        => 'ti',
        description => 'Textinput description',
        url         => 'http://example.com/search',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    like(
        $out, qr{<textinput\s*rdf:about=.http://example\.com/search.>}s,
        'expect to find textinput tag'
    );

    like(
        $out,
        qr{<textinput[^>]+>.*<title>Textinput title</title>.*</textinput>}s,
        'expect to find title tag inside textinput'
    );

    like(
        $out, qr{<textinput[^>]+>.*<name>ti</name>.*</textinput>}s,
        'expect to find name tag inside textinput tag'
    );

    like(
        $out,
        qr{<textinput[^>]+>.*<url>http://example\.com/search</url>.*</textinput>}s,
        'expect to find url tag inside textinput'
    );

    like(
        $out,
        qr{<textinput[^>]+>.*<description>Textinput description</description>.*</textinput>}s,
        'expect to find link tag inside textinput'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<textinput\s*rdf:resource=.http://example\.com/search.*</channel>}s,
        'expect to find textinput tag inside channel tag'
    );
}

done_testing();

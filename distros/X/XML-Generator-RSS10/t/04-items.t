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
        title => 'Item 1 title',
        link  => 'http://example.com/foo1',
    );

    $gen->item(
        title       => 'Item 2 title',
        link        => 'http://example.com/foo2',
        description => 'Item 2 description',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    like(
        $out, qr{<item\s+rdf:about=.http://example.com/foo1.\s*>}s,
        'expect to find item tag for item 1'
    );

    like(
        $out, qr{<item\s+rdf:about=.http://example.com/foo2.\s*>}s,
        'expect to find item tag for item 2'
    );

    like(
        $out,
        qr{<item[^>]+>.*<description><!\[CDATA\[Item 2 description\]\]></description>.*</item>}s,
        'expect to find description tag inside item tag for item 2'
    );

    like(
        $out,
        qr{<items>\s*<rdf:Seq>.*<rdf:li\s+rdf:resource=.http://example\.com/foo1.}s,
        'expect to find rdf:li tag inside channel rdf:Seq for item 1'
    );

    like(
        $out,
        qr{<items>\s*<rdf:Seq>.*<rdf:li\s+rdf:resource=.http://example\.com/foo2.}s,
        'expect to find rdf:li tag inside channel rdf:Seq for item 2'
    );
}

done_testing();

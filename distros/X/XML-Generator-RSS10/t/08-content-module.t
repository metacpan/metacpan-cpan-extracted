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

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
        modules => [qw( content )],
    );

    $gen->item(
        title   => 'Item 1 title',
        link    => 'http://example.com/foo1',
        content => { encoded => '<foo>bar</foo>' },
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    my $p   = XML::Generator::RSS10::content->Prefix;
    my $uri = XML::Generator::RSS10::content->NamespaceURI;
    like(
        $out, qr{xmlns:\Q$p\E=.\Q$uri\E.}s,
        "expect to find $p namespace declaration"
    );

    like(
        $out,
        qr{<item[^>]+>.*<content:encoded>.+</content:encoded>.*</item>}s,
        'expect to find content:encoded tag inside item tag'
    );

    like(
        $out, qr{<item[^>]+>.*<!\[CDATA\[<foo>bar</foo>\]\]>.*</item>}s,
        'expect to find CDATA content inside item tag'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
        modules => [qw( content )],
    );

    $gen->item(
        title => 'Item 1 title',
        link  => 'http://example.com/foo1',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
        content     => {
            items => [
                {
                    format  => 'http://www.w3.org/1999/xhtml',
                    content => '<b>Axis</b> Love',
                },
                {
                    format =>
                        'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional',
                    about => 'http://example.com/content-elsewhere',
                },
                {
                    format =>
                        'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional',
                    encoding => 'http://www.w3.org/TR/REC-xml#dt-wellformed',
                    content  => '<i>italics</i>',
                },
            ],
        },
    );

    like(
        $out,
        qr{<channel[^>]+>.*<content:items>\s*<rdf:Bag>\s*<rdf:li>.+</rdf:li>\s*</rdf:Bag>\s*</content:items>.*</channel>}s,
        'expect to find content:items -> rdf:Bag -> rdf:li tags nested inside channel tag'
    );

    like(
        $out,
        qr{<rdf:li>.+<content:format\s*rdf:resource=.http://www.w3.org/1999/xhtml.+</rdf:li>}s,
        'expect to find content:format inside rdf:li tag'
    );

    like(
        $out,
        qr{<content:item>.+<rdf:value><!\[CDATA\[<b>Axis</b> Love\]\]></rdf:value>.+</content:item>}s,
        'expect to find CDATA inside content:item tag'
    );

    like(
        $out,
        qr{<content:item>.+<content:format\s*rdf:resource=.http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.+</content:item>}s,
        'expect to find CDATA inside content:item tag'
    );

    like(
        $out,
        qr{<content:item>.+<content:encoding\s*rdf:resource=.http://www.w3.org/TR/REC-xml#dt-wellformed.+</content:item>}s,
        'expect to find CDATA inside content:item tag'
    );

}

done_testing();

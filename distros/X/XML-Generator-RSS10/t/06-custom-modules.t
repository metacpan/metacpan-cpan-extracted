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

    package XML::Generator::RSS10::testing;

    use base 'XML::Generator::RSS10::Module';

    sub NamespaceURI { 'http://example.com/testing' }
}

{

    package XML::Generator::RSS10::more;

    use base 'XML::Generator::RSS10::Module';

    sub NamespaceURI { 'http://example.com/less' }
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        modules => [ 'testing', 'more' ],
        pretty  => 1,
    );

    $gen->item(
        title   => 'Item 1 title',
        link    => 'http://example.com/foo1',
        testing => { foo => 'bar' },
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
        more        => { or => 'less' },
    );

    like(
        $out, qr{<item[^>]+>.*<testing:foo>bar</testing:foo>.*</item>}s,
        'expect to find testing:foo tag inside item tag for item 1'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<more:or>less</more:or>.*</channel>}s,
        'expect to find more:or tag inside channel tag'
    );

    foreach my $mod (
        'XML::Generator::RSS10::testing',
        'XML::Generator::RSS10::more'
        ) {
        my $p   = $mod->Prefix;
        my $uri = $mod->NamespaceURI;

        like(
            $out, qr{xmlns:\Q$p\E=.\Q$uri\E.}s,
            "expect to find $p namespace declaration"
        );
    }
}

done_testing();

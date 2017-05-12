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
        modules => [qw( admin dc sy )],
    );

    $gen->item(
        title => 'Item 1 title',
        link  => 'http://example.com/foo1',
        dc    => { publisher => 'Test Publisher' },
    );

    $gen->item(
        title       => 'Item 2 title',
        link        => 'http://example.com/foo2',
        description => 'Item 2 description',
        dc          => { creator => 'The Somewhat Mighty' },
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
        sy          => { updatePeriod => 'yearly' },
        admin       => { errorReportsTo => 'yomama@example.com' },
    );

    like(
        $out,
        qr{<item[^>]+>.*<dc:publisher>Test Publisher</dc:publisher>.*</item>}s,
        'expect to find dc:publisher tag inside item tag for item 1'
    );

    like(
        $out,
        qr{<item[^>]+>.*<dc:creator>The Somewhat Mighty</dc:creator>.*</item>}s,
        'expect to find dc:creator tag inside item tag for item 2'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<sy:updatePeriod>yearly</sy:updatePeriod>.*</channel>}s,
        'expect to find dc:creator tag inside channel tag'
    );

    like(
        $out,
        qr{<channel[^>]+>.*<admin:errorReportsTo\s*rdf:resource=.yomama\@example\.com.*</channel>}s,
        'expect to find dc:creator tag inside channel tag'
    );
}

done_testing();

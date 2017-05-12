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
        modules => [qw( cc )],
    );

    $gen->item(
        title => 'Item 1 title',
        link  => 'http://example.com/foo1',
        cc    => {
            license => 'http://creativecommons.org/licenses/by-nc-nd/2.0/'
        },
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    like(
        $out,
        qr{<item[^>]*>.*<cc:license\s*rdf:about=.http://creativecommons\.org/licenses/by-nc-nd/2\.0/.+</item>}s,
        'expect to find cc:license tag inside item tag'
    );

    like(
        $out,
        qr{<cc:License\s*rdf:about=.http://creativecommons\.org/licenses/by-nc-nd/2\.0/.+</cc:License>}s,
        'expect to find cc:License tag'
    );

    like(
        $out,
        qr{<cc:License[^>]+>.*<cc:prohibits\s*rdf:resource=.http://web\.resource\.org/cc/CommercialUse.*</cc:License>}s,
        'expect to find cc:prohibits CommercialUse cc:License tag'
    );

    like(
        $out,
        qr{<cc:License[^>]+>.*<cc:permits\s*rdf:resource=.http://web\.resource\.org/cc/Reproduction.*</cc:License>}s,
        'expect to find cc:permits Reproduction cc:License tag'
    );

    like(
        $out,
        qr{<cc:License[^>]+>.*<cc:permits\s*rdf:resource=.http://web\.resource\.org/cc/Distribution.*</cc:License>}s,
        'expect to find cc:permits Distribution cc:License tag'
    );

    like(
        $out,
        qr{<cc:License[^>]+>.*<cc:requires\s*rdf:resource=.http://web\.resource\.org/cc/Attribution.*</cc:License>}s,
        'expect to find cc:requires Attribution cc:License tag'
    );

    like(
        $out,
        qr{<cc:License[^>]+>.*<cc:requires\s*rdf:resource=.http://web\.resource\.org/cc/Notice.*</cc:License>}s,
        'expect to find cc:requires Notice cc:License tag'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
        modules => [qw( cc )],
    );

    $gen->item(
        title => 'Item 1 title',
        link  => 'http://example.com/foo1',
        cc    => {
            license => 'http://creativecommons.org/licenses/by-nc-nd/2.0/'
        },
    );

    $gen->item(
        title => 'Item 2 title',
        link  => 'http://example.com/foo2',
        cc    => {
            license => 'http://creativecommons.org/licenses/by-nc-sa/2.0/'
        },
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    like(
        $out,
        qr{<item[^>]*>.*<cc:license\s*rdf:about=.http://creativecommons\.org/licenses/by-nc-nd/2\.0/.+</item>}s,
        'expect to find cc:license tag for by-nc-nd license inside item tag'
    );

    like(
        $out,
        qr{<item[^>]*>.*<cc:license\s*rdf:about=.http://creativecommons\.org/licenses/by-nc-sa/2\.0/.+</item>}s,
        'expect to find cc:license tag for by-nc-sa license  inside item tag'
    );

    like(
        $out,
        qr{<cc:License\s*rdf:about=.http://creativecommons\.org/licenses/by-nc-nd/2\.0/.+</cc:License>}s,
        'expect to find cc:License for by-nc-nd tag'
    );

    like(
        $out,
        qr{<cc:License\s*rdf:about=.http://creativecommons\.org/licenses/by-nc-sa/2\.0/.+</cc:License>}s,
        'expect to find cc:License for by-nc-sa tag'
    );
}

done_testing();

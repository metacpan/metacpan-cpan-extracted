use strict;
use warnings;

use Test::More tests => 13;

use XML::RSS;


sub output_contains
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss_output, $sub_string, $msg) = @_;

    my $ok = ok (index ($rss_output,
        $sub_string) >= 0,
        $msg
    );
    if (! $ok)
    {
        diag(
              "Could not find the substring [$sub_string]"
            . " in:{{{{\n$rss_output\n}}}}\n"
        );
    }
    return $ok;
}

my $xml;

{
    my $rss;

    $rss  = XML::RSS->new( 'xml:base' => 'http://example.com' );

    # TEST
    ok ($rss, "Created new rss");

    # TEST
    is($rss->{'xml:base'}, 'http://example.com', 'Got base');

    $rss->{'xml:base'} = 'http://foo.com/';

    # TEST
    ok($rss->channel(
        title       => 'Test Feed',
        link        => "http://example.com",
        description => "Foo",
    ), "Added channel");

    # TEST
    ok($rss->add_item(
        title => 'foo',
        'xml:base' => "http://foo.com/archive/",
        description => {
            content    => "Bar",
            'xml:base' => "http://foo.com/archive/1.html",
        }
    ), "Added item");

    $xml = $rss->as_rss_2_0();

    # TEST
    ok($xml, "Got xml");

    # TEST
    output_contains(
        $xml,
        'xml:base="http://foo.com/"',
        "Found rss base"
    );

    # TEST
    output_contains(
        $xml,
        'xml:base="http://foo.com/archive/"',
        "Found item base"
    );

    # TEST
    output_contains(
        $xml,
        'xml:base="http://foo.com/archive/1.html"',
        "Found description base"
    );
}

{
    my $rss = XML::RSS->new;

    # TEST
    ok(
        $rss->parse($xml, { hashrefs_instead_of_strings => 1 }),
        "Reparsed xml"
    );

    # TEST
    is(
        $rss->{'xml:base'},
        'http://foo.com/',
        "Found parsed rss base"
    );

    # TEST
    is(
        scalar(@{$rss->{items}}),
        1,
        "Got 1 item"
    );

    my $item = $rss->{items}->[0];

    # TEST
    is(
        $item->{'xml:base'},
        'http://foo.com/archive/',
        "Found parsed item base"
    );

    {
        if (ref $item->{description} eq 'HASH') {
            # TEST
            is(
                $item->{description}->{'xml:base'},
                'http://foo.com/archive/1.html',
                "Found parsed description base"
            );
        } else {
            fail("Description is not a hash ref");
        }
    }
}


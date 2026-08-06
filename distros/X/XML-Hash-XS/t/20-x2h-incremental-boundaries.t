use strict;
use warnings;
use utf8;

use Encode qw(encode);
use Test::More 0.98;
use XML::Hash::XS qw(xml2hash);

ok(!XML::Hash::XS->can('new_parser'), 'legacy converter factory is not exposed');

my @documents = (
    [
        'markup boundaries',
        '<!DOCTYPE root SYSTEM "test.dtd">' .
        '<?xml-stylesheet href="default.css" title="Default"?>' .
        '<root><!-- comment --><item name="a&amp;b"><![CDATA[x<y && z>q]]></item></root>',
    ],
    [
        'single quoted attribute and references',
        q{<root><item first='one &quot; two' second="three &apos; four">&#65;&#x42;</item></root>},
    ],
    [
        'UTF-8 byte boundaries',
        encode('UTF-8', qq{<?xml version="1.0" encoding="UTF-8"?><root name="тест">Привет 😀</root>}),
    ],
);

for my $case (@documents) {
    my ($name, $xml) = @$case;
    my $expected = xml2hash($xml, keep_root => 1);

    subtest $name => sub {
        for my $at (0 .. length $xml) {
            my $parser = XML::Hash::XS::Parser->new(keep_root => 1);
            $parser->feed(substr($xml, 0, $at));
            $parser->feed('');
            $parser->feed(substr($xml, $at));
            is_deeply($parser->finish, $expected, "split at byte $at");
        }
    };
}

{
    my $chunk = '<root><completed>value</completed><ite';
    my $parser = XML::Hash::XS::Parser->new(keep_root => 1);
    $parser->feed($chunk);

    # The parser must own the unfinished suffix after feed() returns.
    substr($chunk, 0, length($chunk), 'x' x length($chunk));
    $parser->feed('m attr="ok">tail</item></root>');

    is_deeply(
        $parser->finish,
        { root => { completed => 'value', item => { attr => 'ok', content => 'tail' } } },
        'unfinished suffix survives mutation of the source scalar',
    );
}

{
    my $value = '';
    my $parser = XML::Hash::XS::Parser->new(keep_root => 1);
    $parser->feed('<root><item attr="');

    # Keep the attribute unfinished while the retained buffer repeatedly grows.
    for my $size (1, 3, 17, 129, 1025, 8193, 32769) {
        my $part = 'x' x $size;
        $value .= $part;
        $parser->feed($part);
    }
    $parser->feed('">ok</item></root>');

    is_deeply(
        $parser->finish,
        { root => { item => { attr => $value, content => 'ok' } } },
        'retained suffix remains valid across buffer reallocations',
    );
}

{
    for my $iteration (1 .. 2000) {
        my $parser = XML::Hash::XS::Parser->new;
        $parser->feed('<root><item attr="' . ('x' x ($iteration % 257)));
        undef $parser;
    }
    pass('unfinished retained buffers can be repeatedly allocated and freed');
}

{
    my $error = eval { XML::Hash::XS::Parser->new->finish; 1 } ? '' : $@;
    like($error, qr/Invalid XML/, 'temporary parser remains alive while finish propagates an error');
}

{
    for my $iteration (1 .. 500) {
        my $parser = XML::Hash::XS::Parser->new;
        $parser->feed('<root><item>');
        eval { $parser->finish };
        undef $parser;
    }
    pass('error-state parsers release retained buffers safely');
}

done_testing;

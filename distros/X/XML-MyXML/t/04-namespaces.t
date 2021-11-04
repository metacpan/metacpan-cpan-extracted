use strict;
use warnings;
use utf8;

use Test::More;

use XML::MyXML qw(:all);

my $xml = <<'EOB';
<?xml version="1.0" encoding="UTF-8"?>
<stream:stream
    from='juliet@im.example.com'
    to='im.example.com'
    version='1.0'
    xml:lang='en'
    xmlns='jabber:client'
    xmlns:stream='http://etherx.jabber.org/streams'>

    <iq id='bv1bs71f'
        to='juliet@example.com/chamber'
        type='result'
        xmlns:o="hi there">

        <query xmlns='jabber:iq:roster' ver='ver7'>
            <item jid='nurse@example.com' o:t='false' xmlns=''/>
            <item jid='romeo@example.net' o:file='true'/>
        </query>

    </iq>

</stream:stream>
EOB

my $obj = xml_to_object($xml);

my @els = $obj->path('/stream{http://etherx.jabber.org/streams}/iq{jabber:client}/query/item[t{hi there}]');
is_deeply [map $_->attr('jid'), @els], ['nurse@example.com'], 'item found with namespaces';

my @items = $obj->path('/stream:stream/iq/query/item');

is_deeply $items[0]{ns_data}, {
    'hi there:t' => 'false',
}, 'deep ns_data for item 1';

is_deeply $items[1]{ns_data}, {
    'hi there:file'     => 'true',
    'jabber:iq:roster:' => undef,
}, 'deep ns_data for item 2';

is_deeply $items[0]{full_ns_info}, {
    stream => 'http://etherx.jabber.org/streams',
    o      => 'hi there',
}, 'deep full_ns_info for item 1';

is_deeply $items[1]{full_ns_info}, {
    ''     => 'jabber:iq:roster',
    stream => 'http://etherx.jabber.org/streams',
    o      => 'hi there',
}, 'deep full_ns_info for item 2';

$items[1]->inner_xml('<foo/>');

is_deeply $obj->path('/stream:stream/iq/query/item/foo')->{ns_data}, {
    'jabber:iq:roster:' => undef,
}, 'inner_xml';

$items[1]->attr(xmlns => '');
is_deeply $obj->path('/stream:stream/iq/query/item/foo')->{ns_data}, {}, 'remove default namespace';

$items[1]->attr(xmlns => 'foo');
is_deeply $obj->path('/stream:stream/iq/query/item/foo')->{ns_data}, {
    'foo:' => undef,
}, 'set default namespace';

done_testing;

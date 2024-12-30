package main;
use strict;
use warnings;

use Test::More tests => 6;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        Dumper(xml2hash(<<"XML", force_array => 0)),
<root>
    <aaa>bbb</aaa>
    <ccc><ddd>ggg</ddd>eee<!-- -->fff</ccc>
</root>
XML
        Dumper({
            aaa => 'bbb',
            ccc => {'content' => ['eee', 'fff'], 'ddd' => 'ggg'},
        }),
        'unuse force_array option',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", force_array => 1)),
<root>
    <aaa>bbb</aaa>
    <ccc><ddd>ggg</ddd>eee<!-- -->fff</ccc>
</root>
XML
        Dumper({
            aaa => ['bbb'],
            ccc => [{'content' => ['eee', 'fff'], 'ddd' => ['ggg']}],
        }),
        'use force_array option',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", force_array => qr/aaa|ddd/)),
<root>
    <aaa>bbb</aaa>
    <ccc><ddd>ggg</ddd>eee<!-- -->fff</ccc>
</root>
XML
        Dumper({
            aaa => ['bbb'],
            ccc => {'content' => ['eee', 'fff'], 'ddd' => ['ggg']},
        }),
        'use force_array option with regexp',
    ;
}

{
    my $o = XML::Hash::XS->new(force_array => ['aaa', 'ddd']);
    is
        Dumper($o->xml2hash(<<"XML")),
<root>
    <aaa>bbb</aaa>
    <ccc><ddd>ggg</ddd>eee<!-- -->fff</ccc>
</root>
XML
        Dumper({
            aaa => ['bbb'],
            ccc => {'content' => ['eee', 'fff'], 'ddd' => ['ggg']},
        }),
        'use force_array option with array',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", force_array => 1, keep_root => 1, trim => 1)),
<?xml version="1.0" encoding="utf-8"?>
<root>
    <node1>123</node1>
    <node3 attr1="attr1_content" subnode3="subnode30_content">
        node3_content_1
        <subnode3>
            subnode31_content
        </subnode3>
        node3_content_2
        <subnode3>
            subnode32_content
        </subnode3>
        <subnode3>
            subnode33_content
        </subnode3>
    </node3>
</root>
XML
        Dumper({
            'root' => {
                'node1' => ['123'],
                'node3' => [
                    {   'attr1'   => [ 'attr1_content' ],
                        'content' => [ 'node3_content_1', 'node3_content_2' ],
                        'subnode3' => [
                            'subnode30_content',
                            'subnode31_content',
                            'subnode32_content',
                            'subnode33_content',
                        ],
                    },
                ],
            },
        }),
        'use force_array option, issue #2',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", force_array => 1, force_content => 1, keep_root => 1, trim => 1)),
<?xml version="1.0" encoding="utf-8"?>
<root>
    <node1>123</node1>
    <node3 attr1="attr1_content" subnode3="subnode30_content">
        node3_content_1
        <subnode3>
            subnode31_content
        </subnode3>
        node3_content_2
        <subnode3>
            subnode32_content
        </subnode3>
        <subnode3>
            subnode33_content
        </subnode3>
    </node3>
</root>
XML
        Dumper({
            'root' => {
                'node1' => [ { content => '123' } ],
                'node3' => [
                    {   'attr1'   => [ { content => 'attr1_content' } ],
                        'content' => [ 'node3_content_1', 'node3_content_2' ],
                        'subnode3' => [
                            { content => 'subnode30_content' },
                            { content => 'subnode31_content' },
                            { content => 'subnode32_content' },
                            { content => 'subnode33_content' },
                        ],
                    },
                ],
            },
        }),
        'use force_content option',
    ;
}

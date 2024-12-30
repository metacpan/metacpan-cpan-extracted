package main;
use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        Dumper(xml2hash(<<"XML", force_array => 1, force_content => 1, merge_text => 1, keep_root => 1, trim => 1)),
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
            <!-- comment  -->
            subnode32_content2
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
                        'content' => ['node3_content_1', 'node3_content_2'],
                        'subnode3' => [
                            { content => 'subnode30_content' },
                            { content => 'subnode31_content' },
                            { content => 'subnode32_contentsubnode32_content2' },
                            { content => 'subnode33_content' },
                        ],
                    },
                ],
            },
        }),
        'use merge_text option',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", merge_text => 1, keep_root => 1)),
<?xml version="1.0" encoding="utf-8"?>
<root>
    <![CDATA[Hello,]]><![CDATA[ world!\n]]>
</root>
XML
        Dumper({
            'root' => "Hello, world!\n"
        }),
        'merge cdata',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", merge_text => 1, keep_root => 1)),
<?xml version="1.0" encoding="utf-8"?>
<root>
    <value><![CDATA[Hello,]]></value>
    <value><![CDATA[ world!\n]]></value>
</root>
XML
        Dumper({
            'root' => {
                'value' => ["Hello,", " world!\n"],
            },
        }),
        'don`t merge text from different nodes',
    ;
}
